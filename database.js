// database.js
const { Pool } = require('pg');
const { parse } = require('pg-connection-string');

// ตรวจสอบว่าเรากำลังรันบน Hosting หรือไม่
const isProduction = process.env.NODE_ENV === 'production';

// --- ใช้คอนเนกชันโลคอลตอนพัฒนา (เหมือนเดิม) ---
const localConnectionString = `postgres://postgres:72rmcBtnuKJ2pVg@localhost:5432/postgres`;

// --- เลือก connection string ตามโหมด ---
const connectionString = isProduction
  ? process.env.DATABASE_URL
  : localConnectionString;

if (!connectionString) {
  console.error('❌ DATABASE_URL is not set (production mode)');
  process.exit(1);
}

// แปลงเป็นอ็อบเจ็กต์เพื่อความยืดหยุ่น
const parsed = parse(connectionString);

// --- สำคัญ: ป้องกัน self-signed certificate error บน Render ---
// node-postgres รองรับ ssl: { rejectUnauthorized: false } สำหรับกรณี CA ไม่ถูก trust
const ssl = isProduction ? { rejectUnauthorized: false } : false;

// --- ค่าคอนเนกชันที่ทำให้เสถียรขึ้น ---
const dbConfig = {
  user: parsed.user,
  password: parsed.password,
  host: parsed.host,
  port: parsed.port ? Number(parsed.port) : 5432,
  database: parsed.database,
  ssl,
  // Pool tuning สำหรับเว็บเล็ก/แผนฟรี
  max: 5,                          // จำกัดคอนเนกชัน
  idleTimeoutMillis: 30_000,       // ปล่อยว่าง 30s แล้วปิด
  connectionTimeoutMillis: 10_000, // รอคอนเนกชันสูงสุด 10s
  keepAlive: true,                 // กันหลุดตอน idle
  keepAliveInitialDelayMillis: 10_000,
};

const pool = new Pool(dbConfig);

console.log(
  isProduction
    ? "Connected to external database (Supabase) with SSL & keepAlive."
    : "Connected to local PostgreSQL database."
);

module.exports = pool;
