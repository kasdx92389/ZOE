import pg from 'pg';
const { Pool } = pg;

const isProduction = process.env.NODE_ENV === 'production';

/**
 * Production strongly prefers Supabase Pooler URL if provided.
 * DATABASE_URL_POOLER example:
 * postgresql://USER:PASSWORD@<project>.pooler.supabase.com:6543/postgres?pgbouncer=true&sslmode=require
 */
const prod = {
  connectionString: (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) || process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 5,
  min: 0,
  idleTimeoutMillis: 60_000,
  connectionTimeoutMillis: 10_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
  statement_timeout: 30_000,
  query_timeout: 35_000,
  idle_in_transaction_session_timeout: 15_000,
};

const dev = {
  connectionString: process.env.DATABASE_URL || 'postgres://postgres:72rmcBtnuKJ2pVg@127.0.0.1:5432/postgres',
  ssl: false,
  max: 5,
  min: 0,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 5_000,
};

const pool = new Pool(isProduction ? prod : dev);

console.log(isProduction ? 'Connecting to external database (Supabase)...' : 'Connecting to local PostgreSQL database...');

export default pool;
