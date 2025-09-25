// database.js
const { Pool, Client } = require('pg');
const { parse } = require('pg-connection-string');

const isProd = (process.env.NODE_ENV || '').toLowerCase() === 'production';

// ดึงทั้งสอง URL (ถ้ามี)
const DIRECT_URL = (process.env.DATABASE_URL || '').trim();
const POOLER_URL = (process.env.DATABASE_URL_POOLER || '').trim();

if (!DIRECT_URL && !POOLER_URL) {
  console.error('❌ DATABASE_URL(_POOLER) not set');
  process.exit(1);
}

function mkBaseCfg(url) {
  const p = parse(url);
  return {
    user: p.user,
    password: p.password,
    host: p.host,
    database: p.database,
    // SSL safe-by-default ใน prod
    ssl: isProd ? { require: true, rejectUnauthorized: false } : false,
    keepAlive: true,
    statement_timeout: 20_000,
    query_timeout: 15_000,
    connectionTimeoutMillis: 10_000,
    _parsedPort: p.port ? Number(p.port) : null,
  };
}

const candidates = [];
const seen = new Set();
function addCandidate(host, port, base) {
  if (!host || !port) return;
  const key = `${host}:${port}`;
  if (seen.has(key)) return;
  seen.add(key);
  candidates.push({
    user: base.user,
    password: base.password,
    host,
    database: base.database,
    ssl: base.ssl,
    keepAlive: base.keepAlive,
    statement_timeout: base.statement_timeout,
    query_timeout: base.query_timeout,
    connectionTimeoutMillis: base.connectionTimeoutMillis,
    port,
  });
}

// 1) จาก DIRECT_URL (db.<project>.supabase.co)
if (DIRECT_URL) {
  const b = mkBaseCfg(DIRECT_URL);
  // ลองพอร์ตที่มากับ URL (ถ้ามี) + 5432
  if (b._parsedPort) addCandidate(b.host, b._parsedPort, b);
  addCandidate(b.host, 5432, b);
}

// 2) จาก POOLER_URL (aws-1-ap-southeast-1.pooler.supabase.com)
if (POOLER_URL) {
  const b = mkBaseCfg(POOLER_URL);
  // ลองพอร์ต pooler (มัก 6543/5432) + พอร์ตใน URL
  addCandidate(b.host, 6543, b);
  addCandidate(b.host, 5432, b);
  if (b._parsedPort) addCandidate(b.host, b._parsedPort, b);
}

if (candidates.length === 0) {
  console.error('❌ No DB candidates found from env.');
  process.exit(1);
}

let currentPool = null;
let currentLabel = '';
let ready = false;
let reprobeTimer = null;

async function probeOnce(cfg) {
  const label = `${cfg.host}:${cfg.port}`;
  const client = new Client(cfg);
  try {
    const t0 = Date.now();
    await client.connect();
    await client.query('select 1');
    await client.end();
    console.log(`✅ DB probe OK @ ${label} (${Date.now() - t0}ms)`);
    return true;
  } catch (e) {
    try { await client.end(); } catch {}
    console.warn(`⚠️  DB probe failed @ ${label}: ${e.code || e.message}`);
    return false;
  }
}

async function chooseAndConnect() {
  for (const cfg of candidates) {
    if (await probeOnce(cfg)) {
      const pool = new Pool({
        ...cfg,
        max: 5,
        idleTimeoutMillis: 30_000,
        keepAliveInitialDelayMillis: 10_000,
      });
      pool.on('error', (err) => {
        console.error('⚠️  PG pool error:', err.code || err.message);
        triggerReprobeSoon();
      });

      if (currentPool) try { await currentPool.end(); } catch {}
      currentPool = pool;
      currentLabel = `${cfg.host}:${cfg.port}`;
      ready = true;
      console.log(`🔌 Using PRODUCTION DB via ${currentLabel} (SSL on, pool size=5)`);
      return;
    }
  }
  // ทั้งหมดล้มเหลว → ตั้งเวลาลองใหม่
  ready = false;
  triggerReprobeSoon();
}

function triggerReprobeSoon(delay = 5000) {
  if (reprobeTimer) return;
  reprobeTimer = setTimeout(async () => {
    reprobeTimer = null;
    try { await chooseAndConnect(); } catch (e) {
      console.error('Reprobe failed:', e.message);
      triggerReprobeSoon(8000);
    }
  }, delay);
}

// เริ่มต้น
chooseAndConnect().catch((e) => {
  console.error('Initial connect failed:', e.message);
  triggerReprobeSoon();
});

const waiters = [];
function waitReady() {
  if (ready && currentPool) return Promise.resolve();
  return new Promise((resolve) => waiters.push({ resolve }));
}
function notifyReady() { while (waiters.length) waiters.shift().resolve(); }

const transient = new Set([
  '57P01','57P02','57P03','ECONNREFUSED','ETIMEDOUT','EHOSTUNREACH','EPIPE','ECONNRESET','ENETUNREACH'
]);

async function runWithRetry(op, name = 'query') {
  const maxTries = 6;
  for (let attempt = 1; attempt <= maxTries; attempt++) {
    try {
      await waitReady();
      const out = await op();
      notifyReady();
      return out;
    } catch (e) {
      const code = e.code || e.errno || e.message;
      const isTransient = transient.has(code) || /timeout|terminated|unreach/i.test(String(code));
      if (!isTransient || attempt === maxTries) {
        console.error(`❌ ${name} failed (attempt ${attempt}/${maxTries}) @ ${currentLabel}:`, code);
        throw e;
      }
      console.warn(`↻ ${name} retry ${attempt}/${maxTries} due to ${code}`);
      ready = false;
      triggerReprobeSoon(1000 * attempt);
      await new Promise(r => setTimeout(r, 300 + 250 * attempt));
    }
  }
}

const proxyPool = {
  async query(text, params) {
    return runWithRetry(() => currentPool.query(text, params), 'query');
  },
  async connect() {
    await waitReady();
    const client = await currentPool.connect();
    const origQuery = client.query.bind(client);
    client.query = (text, params) => runWithRetry(() => origQuery(text, params), 'client.query');
    const origRelease = client.release.bind(client);
    client.release = (...a) => { try { origRelease(...a); } catch {} };
    return client;
  },
  async end() { if (currentPool) try { await currentPool.end(); } catch {} },
};

module.exports = proxyPool;
