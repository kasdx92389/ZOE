
import pg from 'pg';
const { Pool } = pg;

const isProduction = process.env.NODE_ENV === 'production';

// บังคับโหมด SSL ที่ผ่อนปรนเพื่อหลีก SELF_SIGNED_CERT_IN_CHAIN บางกรณี
if (!process.env.PGSSLMODE) {
  process.env.PGSSLMODE = 'require';
}

/**
 * DATABASE_URL_POOLER ควรเป็น Supabase Pooler:6543 พร้อมพารามิเตอร์
 *   ?pgbouncer=true&sslmode=require&connection_limit=1
 */
const prod = {
  connectionString:
    (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
    process.env.DATABASE_URL,
  // ปิดการตรวจสอบใบรับรองเพื่อกัน SELF_SIGNED_CERT_IN_CHAIN บนบางสภาพแวดล้อมฟรี
  ssl: { rejectUnauthorized: false, requestCert: true },

  max: 5,
  min: 0,
  connectionTimeoutMillis: 20_000,
  idleTimeoutMillis: 45_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
  statement_timeout: 45_000,
  query_timeout: 50_000,
  idle_in_transaction_session_timeout: 15_000,
  allowExitOnIdle: true,
};

const dev = {
  connectionString:
    process.env.DATABASE_URL ||
    'postgres://postgres:72rmcBtnuKJ2pVg@127.0.0.1:5432/postgres',
  ssl: false,
  max: 5,
  min: 0,
  connectionTimeoutMillis: 10_000,
  idleTimeoutMillis: 30_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 5_000,
  statement_timeout: 30_000,
  query_timeout: 35_000,
  idle_in_transaction_session_timeout: 10_000,
  allowExitOnIdle: true,
};

const pool = new Pool(isProduction ? prod : dev);
console.log(
  isProduction
    ? 'Connecting to external database (Supabase)...'
    : 'Connecting to local PostgreSQL database...'
);

// Health check + backoff
export async function waitForDbReady({ attempts = 8, firstDelayMs = 500 } = {}) {
  let delay = firstDelayMs;
  for (let i = 1; i <= attempts; i++) {
    try {
      await pool.query('SELECT 1');
      return true;
    } catch (err) {
      console.warn(`DB not ready (try ${i}/${attempts}):`, err?.code || err?.message);
      if (i === attempts) throw err;
      await new Promise(r => setTimeout(r, delay));
      delay = Math.min(delay * 2, 10_000);
    }
  }
}

// Retryable errors
const RETRYABLE_CODES = new Set([
  'ETIMEDOUT',
  'ECONNRESET',
  'ECONNREFUSED',
  '57P01',
  '57P02',
  '57P03',
  '53300',
  '08006',
  '08003',
]);

export async function q(sql, params = [], { retries = 2 } = {}) {
  let attempt = 0;
  let delay = 300;
  while (true) {
    try {
      return await pool.query(sql, params);
    } catch (err) {
      const code = err?.code || err?.errno || err?.message;
      const retryable =
        RETRYABLE_CODES.has(err?.code) ||
        /ETIMEDOUT|ECONNRESET|ECONNREFUSED/i.test(String(code)) ||
        /SELF_SIGNED_CERT_IN_CHAIN/i.test(String(code));
      attempt++;
      if (!retryable || attempt > retries + 1) throw err;
      await new Promise((r) => setTimeout(r, delay));
      delay = Math.min(delay * 2, 1_500);
    }
  }
}

export default pool;
