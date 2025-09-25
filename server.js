// server.js
const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');

const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const pgPool = require('./database.js');
const PgSession = require('connect-pg-simple')(session);

const app = express();
const PORT = process.env.PORT || 3000;

app.set('trust proxy', 1);

const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;

// ---------- DB wrapper ----------
const db = {
  prepare: (sql) => {
    let i = 1;
    const pgSql = sql.replace(/\?/g, () => `$${i++}`);
    return {
      get: async (...params) => (await pgPool.query(pgSql, params)).rows[0],
      all: async (...params) => (await pgPool.query(pgSql, params)).rows,
      run: async (...params) => await pgPool.query(pgSql, params),
    };
  },
  exec: async (sql) => await pgPool.query(sql),
  transaction: (fn) => fn,
};

// ---------- helpers ----------
async function retry(fn, { tries = 5, base = 800, factor = 1.8, name = 'task' } = {}) {
  let attempt = 0;
  for (;;) {
    try {
      return await fn();
    } catch (err) {
      attempt++;
      if (attempt >= tries) throw err;
      const wait = Math.round(base * Math.pow(factor, attempt - 1));
      console.warn(`↻ Retry ${name} (${attempt}/${tries}) after ${wait}ms: ${err.code || err.message}`);
      await new Promise(r => setTimeout(r, wait));
    }
  }
}

let users = {};
async function loadUsers() {
  const rows = await db.prepare('SELECT username, password_hash FROM users').all();
  users = rows.reduce((acc, u) => (acc[u.username] = u.password_hash, acc), {});
  console.log(`👥 Users loaded: ${rows.length}`);
}

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// ---------- sessions ----------
app.use(session({
  store: new PgSession({
    pool: pgPool,
    tableName: 'user_sessions',
    createTableIfMissing: true,
  }),
  secret: 'a-very-secret-key-for-your-session-12345',
  resave: false,
  saveUninitialized: false,
  cookie: {
    maxAge: 30 * 24 * 60 * 60 * 1000,
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true
  }
}));

app.use(express.static(path.join(__dirname, 'public')));

// healthz
app.get('/healthz', async (_req, res) => {
  try { await pgPool.query('select 1'); res.status(200).send('ok'); }
  catch { res.status(500).send('db down'); }
});

const requireLogin = (req, res, next) => (req.session.userId ? next() : res.redirect('/'));

// routes (เดิม)
app.get('/', (req, res) =>
  req.session.userId
    ? res.redirect('/admin/home')
    : res.sendFile(path.join(__dirname, 'public', 'index.html'))
);
app.get('/register', (_req, res) => res.sendFile(path.join(__dirname, 'public', 'admin-register.html')));
app.get('/terms',    (_req, res) => res.sendFile(path.join(__dirname, 'public', 'terms.html')));

app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  const userHash = users[username];
  if (userHash && await bcrypt.compare(password, userHash)) {
    req.session.userId = username;
    return res.redirect('/admin/home');
  }
  res.redirect(`/?error=${encodeURIComponent('Username หรือ Password ไม่ถูกต้อง')}`);
});

app.post('/register', async (req, res) => {
  const { username, password, master_code } = req.body;
  if (master_code !== MASTER_CODE)
    return res.redirect(`/register?error=${encodeURIComponent('รหัสโค้ดลับไม่ถูกต้อง.')}`);
  if (users[username])
    return res.redirect(`/register?error=${encodeURIComponent('Username นี้มีผู้ใช้งานแล้ว.')}`);

  const hashedPassword = await bcrypt.hash(password, saltRounds);
  await db.prepare('INSERT INTO users (username, password_hash) VALUES (?, ?)').run(username, hashedPassword);
  await retry(loadUsers, { name: 'loadUsers-after-register' });
  res.redirect(`/?success=${encodeURIComponent('สร้างบัญชีสำเร็จ!')}`);
});

app.get('/logout', (req, res) => req.session.destroy(() => res.redirect('/')));

// ---------- startup gating ----------
async function waitForDb({ tries = 12, baseDelay = 1500, factor = 1.6 } = {}) {
  for (let k = 1; k <= tries; k++) {
    try {
      await pgPool.query('select 1');
      console.log('✅ Database is reachable');
      return;
    } catch (err) {
      const delay = Math.round(baseDelay * Math.pow(factor, k - 1));
      console.warn(`DB not ready (try ${k}/${tries}): ${err.code || err.message}`);
      await new Promise(r => setTimeout(r, delay));
    }
  }
  throw new Error('Database not reachable after retries');
}

async function start() {
  try {
    console.log('🚀 Starting app…');
    await waitForDb();
    // ► ย้าย loadUsers มาไว้หลัง DB พร้อม และใส่ retry
    await retry(loadUsers, { name: 'loadUsers' });

    app.listen(PORT, () => console.log(`🟢 Server running on :${PORT}`));
  } catch (e) {
    console.error('❌ Fatal: service cannot start', e.message);
    process.exit(1);
  }
}

// graceful shutdown
process.on('SIGTERM', async () => {
  console.log('⏳ Shutting down…');
  try { await pgPool.end(); } catch {}
  process.exit(0);
});
process.on('unhandledRejection', (err) => console.error('UnhandledRejection:', err));

start();
