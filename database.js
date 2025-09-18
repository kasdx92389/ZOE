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
  // --- บรรทัดสำคัญอยู่ตรงนี้ ---
  // บังคับให้ Node.js ใช้การเชื่อมต่อแบบ IPv4 ซึ่งมักจะแก้ปัญหา ENETUNREACH ได้
  family: 4
};

// เลือกใช้ config ตามสภาพแวดล้อม
const dbConfig = isProduction ? productionDbConfig : localDbConfig;

const pool = new Pool(dbConfig);

console.log(isProduction ? "Connecting to external database (Supabase)..." : "Connecting to local PostgreSQL database...");

module.exports = pool;