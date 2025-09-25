// database.js
const { Pool } = require('pg');
const { parse } = require('pg-connection-string');

const isProduction = process.env.NODE_ENV === 'production';

const envConn =
  process.env.DATABASE_URL_POOLER?.trim() ||
  process.env.DATABASE_URL?.trim() || '';

const localConn = `postgres://postgres:72rmcBtnuKJ2pVg@localhost:5432/postgres`;
const connectionString = isProduction ? envConn : localConn;

if (!connectionString) {
  console.error('❌ DATABASE_URL / DATABASE_URL_POOLER is not set (production mode)');
  process.exit(1);
}

const parsed = parse(connectionString);

const looksLikeSupabase =
  /supabase\.co$/.test(parsed.host || '') || /pooler\.supabase\.com$/.test(parsed.host || '');
const hasPgBouncerParam = /\bpgbouncer=true\b/i.test(connectionString);

let port = parsed.port ? Number(parsed.port) : 5432;
if (looksLikeSupabase && (hasPgBouncerParam || /pooler\.supabase\.com$/.test(parsed.host || ''))) {
  // ใช้ 6543 เมื่อเป็น pooler
  port = 6543;
}

const ssl = isProduction ? { require: true, rejectUnauthorized: false } : false;

const dbConfig = {
  user: parsed.user,
  password: parsed.password,
  host: parsed.host,
  port,
  database: parsed.database,
  ssl,
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
  // เพิ่มเติม: timeout ฝั่งไคลเอนต์กันแฮงค์
  query_timeout: 15_000, // ms
  statement_timeout: 20_000, // ส่งลงไปที่เซิร์ฟเวอร์ (pg >= 12 รองรับผ่าน SET)
};

const pool = new Pool(dbConfig);

// กรณีคอนเนกชันตายแบบไม่คาดคิด ให้ log ไว้
pool.on('error', (err) => {
  console.error('⚠️  PG pool error:', err.message);
});

const maskedHost = `${parsed.host}:${port}`;
console.log(
  isProduction
    ? `🔌 Using PRODUCTION DB via ${maskedHost} (SSL on, pool size=${dbConfig.max})`
    : `🔌 Using LOCAL DB via ${maskedHost}`
);

module.exports = pool;
