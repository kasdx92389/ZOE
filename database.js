const { Pool } = require('pg');

// ตรวจสอบว่าเรากำลังรันบน Hosting หรือไม่
const isProduction = process.env.NODE_ENV === 'production';

if (isProduction && !process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL environment variable is not set for production.");
}

const pool = new Pool({
  connectionString: isProduction ? process.env.DATABASE_URL : 'postgres://user:password@localhost:5432/database', // ใส่ connection string สำหรับ local ถ้ามี
  ssl: isProduction ? { rejectUnauthorized: false } : false
});

console.log(isProduction ? "Connected to external database (Supabase)." : "Connected to local PostgreSQL database.");

module.exports = pool;