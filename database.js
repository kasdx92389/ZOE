// database.js
const { Pool, Client } = require('pg');
const { parse } = require('pg-connection-string');

const isProduction = process.env.NODE_ENV === 'production';

const envConn =
  (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
  (process.env.DATABASE_URL && process.env.DATABASE_URL.trim()) || '';
const localConn = `postgres://postgres:72rmcBtnuKJ2pVg@localhost:5432/postgres`;
const connectionString = isProduction ? envConn : localConn;

if (!connectionString) {
  console.error('❌ DATABASE_URL / DATABASE_URL_POOLER is not set (production mode)');
  process.exit(1);
}

const parsed = parse(connectionString);

function buildCandidates(p) {
  const host = p.host;
  const base = {
    user: p.user,
    password: p.password,
    host,
    database: p.database,
    ssl: isProduction ? { require: true, rejectUnauthorized: false } : false,
    keepAlive: true,
    statement_timeout: 20_000,
    query_timeout: 15_000,
    connectionTimeoutMillis: 15_000,
  };
  const looksPoolerHost = /pooler\.supabase\.com$/.test(host) || /supabase\.co$/.test(host);
  const givenPort = p.port ? Number(p.port) : 5432;
  const primary = { ...base, port: looksPoolerHost ? 6543 : givenPort };
  const secondary = { ...base, port: 5432 };
  if (!looksPoolerHost) return [primary];
  const arr = [primary];
  if (primary.port !== secondary.port) arr.push(secondary);
  return arr;
}

const candidates = buildCandidates(parsed);

async function probeAndPick(cfgs) {
  for (const cfg of cfgs) {
    const label = `${cfg.host}:${cfg.port}`;
    const client = new Client(cfg);
    try {
      const t0 = Date.now();
      await client.connect();
      await client.query('select 1');
      await client.end();
      console.log(`✅ DB probe OK @ ${label} (${Date.now() - t0}ms)`);
      return cfg;
    } catch (err) {
      await client.end().catch(() => {});
      console.warn(`⚠️  DB probe failed @ ${label}: ${err.code || err.message}`);
    }
  }
  throw new Error('No DB endpoint reachable');
}

let pool;
async function createPool() {
  const cfg = await probeAndPick(candidates);
  console.log(`🔌 Using PRODUCTION DB via ${cfg.host}:${cfg.port} (SSL on, pool size=5)`);
  pool = new Pool({
    ...cfg,
    max: 5,
    idleTimeoutMillis: 30_000,
    keepAliveInitialDelayMillis: 10_000,
  });
  pool.on('error', (err) => console.error('⚠️  PG pool error:', err.message));
  return pool;
}

module.exports = (async () => {
  if (isProduction) return await createPool();
  const { user, password, host, port, database } = parse(localConn);
  pool = new Pool({
    user, password, host, port: port ? Number(port) : 5432, database,
    ssl: false, max: 5, idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 15_000, keepAlive: true, keepAliveInitialDelayMillis: 10_000,
  });
  return pool;
})();
