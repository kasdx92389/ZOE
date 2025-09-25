// database.js
// กันตาย: failover 6543→5432, background re-probe, circuit-breaker + proxy Pool
const { Pool, Client } = require('pg');
const { parse } = require('pg-connection-string');

const isProd =
  (process.env.NODE_ENV || '').toLowerCase() === 'production';

const BASE_CONN =
  (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
  (process.env.DATABASE_URL && process.env.DATABASE_URL.trim()) ||
  (!isProd ? 'postgres://postgres:72rmcBtnuKJ2pVg@localhost:5432/postgres' : '');

if (!BASE_CONN) {
  console.error('❌ DATABASE_URL(_POOLER) not set');
  process.exit(1);
}

const parsed = parse(BASE_CONN);
const looksSupabase =
  /supabase\.co$/i.test(parsed.host || '') ||
  /pooler\.supabase\.com$/i.test(parsed.host || '');

const forcePort = process.env.FORCE_DB_PORT && Number(process.env.FORCE_DB_PORT) || null;

const baseCfg = {
  user: parsed.user,
  password: parsed.password,
  host: parsed.host,
  database: parsed.database,
  ssl: isProd ? { require: true, rejectUnauthorized: false } : false,
  keepAlive: true,
  statement_timeout: 20_000,
  query_timeout: 15_000,
  connectionTimeoutMillis: 10_000,
};

const seen = new Set();
const candidates = [];
function pushUnique(port) {
  const key = `${baseCfg.host}:${port}`;
  if (!seen.has(key)) { candidates.push({ ...baseCfg, port }); seen.add(key); }
}

if (forcePort) {
  pushUnique(forcePort);
} else {
  if (looksSupabase) pushUnique(6543);
  pushUnique(5432);
  pushUnique(parsed.port ? Number(parsed.port) : 5432);
}

let currentPool = null;
let currentLabel = '';
let ready = false;

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

let reprobeTimer = null;
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

chooseAndConnect().catch((e) => {
  console.error('Initial connect failed:', e.message);
  triggerReprobeSoon();
});

// ---- Proxy pool with retries ----
const waiters = [];
function notifyReady() { while (waiters.length) waiters.shift().resolve(); }
function waitReady() {
  if (ready && currentPool) return Promise.resolve();
  return new Promise((resolve) => waiters.push({ resolve }));
}
const transientCodes = new Set([
  '57P01','57P02','57P03',
  'ECONNREFUSED','ETIMEDOUT','EHOSTUNREACH','EPIPE','ECONNRESET'
]);
async function runWithRetry(op, name = 'query') {
  const maxTries = 6;
  let attempt = 0;
  for (;;) {
    try {
      await waitReady();
      const out = await op();
      notifyReady();
      return out;
    } catch (e) {
      const code = e.code || e.errno || e.message;
      const isTransient = transientCodes.has(code) || /timeout|terminated/i.test(String(code));
      attempt++;
      if (!isTransient || attempt >= maxTries) {
        console.error(`❌ ${name} failed (attempt ${attempt}/${maxTries}) @ ${currentLabel}:`, code);
        throw e;
      }
      console.warn(`↻ ${name} retry ${attempt}/${maxTries} due to ${code}`);
      ready = false;
      triggerReprobeSoon(1000 * attempt);
      await new Promise(r => setTimeout(r, 300 + 200 * attempt));
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
