import pg from 'pg';
import path from 'path';
const { Pool } = pg;

// ตรวจสอบว่าเรากำลังรันบน Hosting หรือไม่
const isProduction = process.env.NODE_ENV === 'production';

// สำหรับการเชื่อมต่อบนเครื่อง (Development)
const localDbConfig = {
  connectionString: `postgres://postgres:72rmcBtnuKJ2pVg@127.0.0.1:5432/postgres`,
  ssl: false
};

// สำหรับการเชื่อมต่อบนเซิร์ฟเวอร์ (Production) - แก้ไขแล้ว
const productionDbConfig = {
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  connectionTimeoutMillis: 10000, 
};

// เลือกใช้ config ตามสภาพแวดล้อม
const dbConfig = isProduction ? productionDbConfig : localDbConfig;

const pool = new Pool(dbConfig);

console.log(isProduction ? "Connecting to external database (Supabase)..." : "Connecting to local PostgreSQL database...");

export default pool;