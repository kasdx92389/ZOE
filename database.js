// database.js
import pg from 'pg';
const { Pool } = pg;

const isProduction = process.env.NODE_ENV === 'production';

/**
 * แนะนำให้ตั้ง DATABASE_URL_POOLER เป็น Supabase Pooler (port 6543) เช่น:
 * postgresql://USER:PASSWORD@<project>.pooler.supabase.com:6543/postgres?pgbouncer=true&sslmode=require&connection_limit=1
 * - pgbouncer=true และ sslmode=require สำคัญมาก
 * - connection_limit=1 ช่วยไม่ให้กินโควตา connection ของ nano ฟรี-tier
 */

const prod = {
  connectionString:
    (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
    process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },

  // จำกัด connection ให้เหมาะกับ free nano + Pooler
  max: 5,
  min: 0,

  // ปรับคุณสมบัติเพื่อความทนบนเครือข่ายฟรี-tier
  connectionTimeoutMillis: 20_000,
  idleTimeoutMillis: 45_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,

  // ป้องกัน query แขวน
  statement_timeout: 45_000,
  query_timeout: 50_000,
  idle_in_transaction_session_timeout: 15_000,

  // ปล่อย process exit เมื่อ idle ได้ ลดค้างคา socket เก่า
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

/** รอ DB พร้อมใช้งานด้วย health-check + backoff */
export async function waitForDbReady({ attempts = 8, firstDelayMs = 500 } = {}) {
  let delay = firstDelayMs;
  for (let i = 1; i <= attempts; i++) {
    try {
      await pool.query('SELECT 1');
      return true;
    } catch (err) {
      console.warn(
        `DB not ready (try ${i}/${attempts}):`,
        err?.code || err?.message
      );
      if (i === attempts) throw err;
      await new Promise((r) => setTimeout(r, delay));
      delay = Math.min(delay * 2, 10_000);
    }
  }
}

/** รายการ error ที่สมเหตุสมผลสำหรับ retry */
const RETRYABLE_CODES = new Set([
  'ETIMEDOUT',
  'ECONNRESET',
  'ECONNREFUSED',
  '57P01', // admin_shutdown
  '57P02', // crash_shutdown
  '57P03', // cannot_connect_now
  '53300', // too_many_connections
  '08006', // connection_failure
  '08003', // connection_does_not_exist
]);

/**
 * q(sql, params, {retries})
 * ตัวห่อ query พร้อม retry/backoff สำหรับกรณีเครือข่ายแกว่ง/pgbouncer ตัด idle conn
 * - รับ SQL แบบปกติ (ใช้ $1,$2,…)
 * - ใช้กับทั้งจุดที่เดิมเรียก pool.query ตรง ๆ และผ่าน db.prepare()
 */
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
        /ETIMEDOUT|ECONNRESET|ECONNREFUSED/i.test(String(code));
      attempt++;
      if (!retryable || attempt > retries + 1) throw err;
      await new Promise((r) => setTimeout(r, delay));
      delay = Math.min(delay * 2, 1_500);
    }
  }
}

export default pool;
