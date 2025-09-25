const { Pool } = require('pg');
const path = require('path');

// ตรวจสอบว่าเรากำลังรันบน Hosting หรือไม่
const isProduction = process.env.NODE_ENV === 'production';

// --- NEW: Define a specific connection string for local development ---
// ใส่รหัสผ่านที่คุณตั้งไว้ในขั้นตอนติดตั้ง PostgreSQL ตรง [YOUR-PASSWORD]
const localConnectionString = `postgres://postgres:KESUSECRET2025@localhost:5432/postgres`;

const dbConfig = {
  // ถ้าอยู่บน Hosting ให้ใช้ URL และ Token จาก Environment Variables
  // ถ้าอยู่บนเครื่องเรา (Development) ให้เชื่อมต่อกับฐานข้อมูล postgres ที่เพิ่งติดตั้ง
  connectionString: isProduction ? process.env.DATABASE_URL : localConnectionString,
  ssl: isProduction ? { rejectUnauthorized: false } : false
};

const pool = new Pool(dbConfig);

console.log(isProduction ? "Connected to external database (Supabase)." : "Connected to local PostgreSQL database.");

module.exports = pool;