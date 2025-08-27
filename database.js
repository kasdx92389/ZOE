// database.js
// บังคับให้ DNS เลือก IPv4 ก่อน (แก้ ENETUNREACH บน Render)
const dns = require('node:dns');
if (typeof dns.setDefaultResultOrder === 'function') {
  dns.setDefaultResultOrder('ipv4first');
}

const { Pool } = require('pg');

const isProduction = process.env.NODE_ENV === 'production';

// สายเชื่อมต่อ: ใช้ DATABASE_URL บน Render / ใช้ local ตอน dev
let connectionString = isProduction
  ? process.env.DATABASE_URL
  : (process.env.LOCAL_DATABASE_URL || 'postgres://postgres:72rmcBtnuKJ2pVg@localhost:5432/postgres');

// ถ้าอยู่ production และยังไม่มี sslmode ให้บังคับเพิ่มเอง
if (isProduction && connectionString && !/(\?|&)sslmode=/.test(connectionString)) {
  connectionString += (connectionString.includes('?') ? '&' : '?') + 'sslmode=require';
}

if (!connectionString) {
  console.error('❌ Missing DATABASE_URL (or LOCAL_DATABASE_URL)'); // เห็นใน Render logs
  process.exit(1);
}

const pool = new Pool({
  connectionString,
  ssl: isProduction ? { rejectUnauthorized: false } : false,
});

// ทดสอบต่อ DB ตอนสตาร์ต ให้ fail-fast ถ้าพัง
pool.query('SELECT 1')
  .then(() => console.log('✅ DB connected'))
  .catch((e) => {
    console.error('❌ DB connect failed:', {
      message: e.message,
      code: e.code,
      errno: e.errno,
      syscall: e.syscall,
      address: e.address,
      port: e.port,
    });
    process.exit(1);
  });

module.exports = pool;
