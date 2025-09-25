// database.js
const { Pool } = require('pg');
const { parse } = require('pg-connection-string');

const isProduction = process.env.NODE_ENV === 'production';

// ----- เลือก connection string -----
// ผลักให้ใช้ POOLER ก่อนเสมอ ถ้ามี
const envConn =
  process.env.DATABASE_URL_POOLER?.trim() ||
  process.env.DATABASE_URL?.trim() ||
  '';

const localConn = `postgres://postgres:72rmcBtnuKJ2pVg@localhost:5432/postgres`;
const connectionString = isProduction ? envConn : localConn;

if (!connectionString) {
  console.error('❌ DATABASE_URL / DATABASE_URL_POOLER is not set (production mode)');
  process.exit(1);
}

const parsed = parse(connectionString);

// ----- เงื่อนไขช่วยเหลือ: ถ้าเป็น Supabase + มี pgbouncer=true แต่ยังเป็น 5432 → เปลี่ยนเป็น 6543 -----
const looksLikeSupabase =
  /supabase\.co$/.test(parsed.host || '') || /pooler\.supabase\.com$/.test(parsed.host || '');
const hasPgBouncerParam = /\bpgbouncer=true\b/i.test(connectionString);

let port = parsed.port ? Number(parsed.port) : 5432;
if (looksLikeSupabase && hasPgBouncerParam && port === 5432) {
  port = 6543;
}

// ----- SSL กัน self-signed บน Render -----
const ssl = isProduction ? { require: true, rejectUnauthorized: false } : false;

// ----- ค่าพูลเพื่อความเสถียร -----
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
};

const pool = new Pool(dbConfig);

// แสดงปลายทาง (mask user/pass) ช่วย debug ได้หากยังหลุด
const maskedHost = `${parsed.host}:${port}`;
console.log(
  isProduction
    ? `🔌 Using PRODUCTION DB via ${maskedHost} (SSL on, pool size=${dbConfig.max})`
    : `🔌 Using LOCAL DB via ${maskedHost}`
);

module.exports = pool;
