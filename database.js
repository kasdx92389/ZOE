// database.js
const { Pool } = require('pg');
const { parse } = require('pg-connection-string');

const isProduction = process.env.NODE_ENV === 'production';

// โลคอลตอน dev (เหมือนเดิม)
const localConnectionString = `postgres://postgres:72rmcBtnuKJ2pVg@localhost:5432/postgres`;

const connectionString = isProduction ? process.env.DATABASE_URL : localConnectionString;
if (!connectionString) {
  console.error('❌ DATABASE_URL is not set (production mode)');
  process.exit(1);
}

const parsed = parse(connectionString);

// แก้ self-signed บน Render
const ssl = isProduction ? { rejectUnauthorized: false } : false;

// ค่าพูลที่เสถียร
const dbConfig = {
  user: parsed.user,
  password: parsed.password,
  host: parsed.host,
  port: parsed.port ? Number(parsed.port) : 5432,
  database: parsed.database,
  ssl,
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
};

const pool = new Pool(dbConfig);

console.log(
  isProduction
    ? "Connected to external database (Supabase) with SSL & keepAlive."
    : "Connected to local PostgreSQL database."
);

module.exports = pool;
