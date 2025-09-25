// database.js
const { Pool } = require('pg');
const { parse } = require('pg-connection-string');

const isProd = process.env.NODE_ENV === 'production';

// ใช้ URL จาก ENV: ให้ Pooler มาก่อน (6543) แล้วค่อย Direct (5432)
const envConn =
  (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
  (process.env.DATABASE_URL && process.env.DATABASE_URL.trim()) || '';

const localConn = 'postgres://postgres:72rmcBtnuKJ2pVg@localhost:5432/postgres';
const connStr = isProd ? envConn : localConn;

if (!connStr) {
  console.error('❌ DATABASE_URL / DATABASE_URL_POOLER is not set (production mode)');
  process.exit(1);
}

const parsed = parse(connStr);

// ถ้าเป็น Supabase pooler แต่พอร์ตไม่ใช่ 6543 ให้บังคับเป็น 6543
const looksLikeSupabase =
  /supabase\.co$/i.test(parsed.host || '') || /pooler\.supabase\.com$/i.test(parsed.host || '');
let port = parsed.port ? Number(parsed.port) : 5432;
if (looksLikeSupabase) port = 6543;

// SSL กัน self-signed บน Render
const ssl = isProd ? { require: true, rejectUnauthorized: false } : false;

const pool = new Pool({
  user: parsed.user,
  password: parsed.password,
  host: parsed.host,
  port,
  database: parsed.database,
  ssl,
  // tuning เพื่อความเสถียร
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 15_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
  // กันแฮงค์ระหว่าง query
  statement_timeout: 20_000,
  query_timeout: 15_000,
});

pool.on('error', (err) => {
  console.error('⚠️  PG pool error:', err.message);
});

console.log(
  isProd
    ? `🔌 Using PRODUCTION DB via ${parsed.host}:${port} (SSL on, pool size=5)`
    : `🔌 Using LOCAL DB via ${parsed.host || 'localhost'}:${port}`
);

module.exports = pool;
