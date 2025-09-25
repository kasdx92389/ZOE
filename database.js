const { Pool } = require('pg');
const path = require('path');

// ตรวจสอบว่าเรากำลังรันบน Hosting หรือไม่
const isProduction = process.env.NODE_ENV === 'production';

// --- NEW: เพิ่ม family: 4 เพื่อบังคับใช้ IPv4 ---
// สำหรับการเชื่อมต่อบนเครื่อง (Development)
const localDbConfig = {
  connectionString: `postgres://postgres:72rmcBtnuKJ2pVg@127.0.0.1:5432/postgres`,
  ssl: false
};

// สำหรับการเชื่อมต่อบนเซิร์ฟเวอร์ (Production)
const productionDbConfig = {
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  family: 4, // บรรทัดนี้ดีอยู่แล้ว ให้คงไว้

  // --- NEW: เพิ่มค่าเหล่านี้เพื่อแก้ปัญหา ETIMEDOUT ---
  // บังคับให้สร้าง Connection ใหม่ทุกครั้งที่ query (สำคัญมากสำหรับ PgBouncer)
  maxUses: 1, 
  // ตั้งค่าให้ปิด Connection ที่ว่างงาน (idle) ทันที
  idleTimeoutMillis: 0, 
  // อนุญาตให้สร้าง Connection ได้เร็วขึ้นเมื่อจำเป็น
  connectionTimeoutMillis: 10000, 
};

// เลือกใช้ config ตามสภาพแวดล้อม
const dbConfig = isProduction ? productionDbConfig : localDbConfig;

const pool = new Pool(dbConfig);

console.log(isProduction ? "Connecting to external database (Supabase)..." : "Connecting to local PostgreSQL database...");

module.exports = pool;