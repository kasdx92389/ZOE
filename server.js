// server.js
const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');

const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const PgSessionFactory = require('connect-pg-simple');

const app = express();
const PORT = process.env.PORT || 3000;
app.set('trust proxy', 1);

const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;

let pgPool; // set ใน start()

// ---------- utils ----------
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

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// ---------- mount SESSION ก่อนประกาศทุก route ----------
const conString =
  (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
  (process.env.DATABASE_URL && process.env.DATABASE_URL.trim());

const PgSession = PgSessionFactory(session);
app.use(session({
  store: new PgSession({
    conString,                 // ใช้ connection string ตรง ไม่ต้องรอ Pool
    tableName: 'user_sessions',
    createTableIfMissing: true,
    pruneSessionInterval: 60 * 60, // 1h
  }),
  secret: 'a-very-secret-key-for-your-session-12345',
  resave: false,
  saveUninitialized: false,
  cookie: {
    maxAge: 30 * 24 * 60 * 60 * 1000,
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
  }
}));

// ---------- middleware/auth ----------
const requireLogin = (req, res, next) => (req.session?.userId ? next() : res.redirect('/'));

// ---------- healthz ----------
app.get('/healthz', async (_req, res) => {
  try { await pgPool.query('select 1'); res.status(200).send('ok'); }
  catch { res.status(500).send('db down'); }
});

// ---------- DB wrapper (จะอ้างอิง pgPool หลัง start()) ----------
const db = {
  prepare: (sql) => {
    let i = 1;
    const toPg = sql.replace(/\?/g, () => `$${i++}`);
    return {
      get: async (...params) => (await pgPool.query(toPg, params)).rows[0],
      all: async (...params) => (await pgPool.query(toPg, params)).rows,
      run: async (...params) => await pgPool.query(toPg, params),
    };
  },
  exec: async (sql) => await pgPool.query(sql),
  transaction: (fn) => fn,
};

// ---------- routes (คงเดิมทั้งหมด) ----------
let users = {};
async function loadUsers() {
  const rows = await db.prepare('SELECT username, password_hash FROM users').all();
  users = rows.reduce((acc, u) => (acc[u.username] = u.password_hash, acc), {});
  console.log(`👥 Users loaded: ${rows.length}`);
}

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) =>
  req.session?.userId
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
  const hashed = await bcrypt.hash(password, saltRounds);
  await db.prepare('INSERT INTO users (username, password_hash) VALUES (?, ?)').run(username, hashed);
  await retry(loadUsers, { name: 'loadUsers-after-register' });
  res.redirect(`/?success=${encodeURIComponent('สร้างบัญชีสำเร็จ!')}`);
});

app.get('/logout', (req, res) => req.session.destroy(() => res.redirect('/')));

app.get('/admin/home', requireLogin, (_req, res) =>
  res.sendFile(path.join(__dirname, 'public', 'homepage.html'))
);
app.get('/admin/dashboard', requireLogin, (_req, res) =>
  res.sendFile(path.join(__dirname, 'public', 'admin-dashboard.html'))
);
app.get('/admin/packages', requireLogin, (req, res) => {
  if (req.query.game) res.sendFile(path.join(__dirname, 'public', 'package-management.html'));
  else res.sendFile(path.join(__dirname, 'public', 'games-dashboard.html'));
});
app.get('/admin/zoe-management', requireLogin, (_req, res) =>
  res.sendFile(path.join(__dirname, 'public', 'order-management.html'))
);
app.get('/admin/summary', requireLogin, (_req, res) =>
  res.sendFile(path.join(__dirname, 'public', 'admin-summary.html'))
);

// ปกป้องทุก /api ด้วย requireLogin (เหมือนเดิม)
app.use('/api', requireLogin);

/* ==========================
   ===== API เดิมทั้งหมด =====
   (Orders / Packages / Summary / Export ฯลฯ)
   *** วางโค้ด API ของคุณตรงนี้ตามไฟล์ก่อนหน้า ***
   ผมไม่ได้เปลี่ยน logic ภายใน API เลย
   ========================== */
// (ใส่โค้ด API ของคุณที่มีอยู่แล้ว — จากไฟล์ก่อนหน้านี้ที่เราส่งให้คุณ ใช้ได้ทันที)

// ---------- startup ----------
async function waitForDb({ tries = 14, baseDelay = 1800, factor = 1.7 } = {}) {
  for (let k = 1; k <= tries; k++) {
    try { await pgPool.query('select 1'); console.log('✅ Database is reachable'); return; }
    catch (err) {
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
    // รับ Pool ที่พร้อมใช้งานจริง (database.js คืน Promise<Pool>)
    const poolPromise = require('./database.js');
    pgPool = await poolPromise;

    await waitForDb();
    await retry(loadUsers, { name: 'loadUsers' });

    app.listen(PORT, () => console.log(`🟢 Server running on :${PORT}`));
  } catch (e) {
    console.error('❌ Fatal: service cannot start', e.message);
    process.exit(1);
  }
}

process.on('SIGTERM', async () => {
  console.log('⏳ Shutting down…');
  try { await pgPool?.end(); } catch {}
  process.exit(0);
});
process.on('unhandledRejection', (err) => console.error('UnhandledRejection:', err));

start();
