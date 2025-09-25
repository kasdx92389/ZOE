// server.js
const dns = require('dns');
// บังคับให้ Node ใช้ IPv4 ก่อน (กัน ENETUNREACH/ETIMEDOUT)
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

// --- ค่าคงที่ ---
const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;

// --- Database wrapper ---
const db = {
  prepare: (sql) => {
    let paramIndex = 1;
    const pgSql = sql.replace(/\?/g, () => `$${paramIndex++}`);
    return {
      get: async (...params) => (await pgPool.query(pgSql, params)).rows[0],
      all: async (...params) => (await pgPool.query(pgSql, params)).rows,
      run: async (...params) => await pgPool.query(pgSql, params),
    };
  },
  exec: async (sql) => await pgPool.query(sql),
  transaction: (fn) => fn
};

// --- โหลดข้อมูลผู้ใช้ ---
let users = {};
const loadUsers = async () => {
  try {
    const userRows = await db.prepare('SELECT username, password_hash FROM users').all();
    users = userRows.reduce((acc, user) => {
      acc[user.username] = user.password_hash;
      return acc;
    }, {});
    console.log('Users loaded from database.');
  } catch (error) {
    console.error('Failed to load users from database:', error);
  }
};
loadUsers();

// --- Middleware ---
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// --- Session configuration ---
app.use(session({
  store: new PgSession({
    pool: pgPool,
    tableName: 'user_sessions',
    // ให้สร้างตาราง session อัตโนมัติ ถ้ายังไม่มี
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

// --- Health check ---
app.get('/healthz', async (_req, res) => {
  try {
    await pgPool.query('select 1');
    res.status(200).send('ok');
  } catch {
    res.status(500).send('db down');
  }
});

const requireLogin = (req, res, next) => {
  if (req.session.userId) next();
  else res.redirect('/');
};

app.get('/', (req, res) => {
  if (req.session.userId) res.redirect('/admin/home');
  else res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/register', (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin-register.html'));
});

app.get('/terms', (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'terms.html'));
});

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
  if (master_code !== 'KESU-SECRET-2025')
    return res.redirect(`/register?error=${encodeURIComponent('รหัสโค้ดลับไม่ถูกต้อง.')}`);
  if (users[username])
    return res.redirect(`/register?error=${encodeURIComponent('Username นี้มีผู้ใช้งานแล้ว.')}`);

  const hashedPassword = await bcrypt.hash(password, saltRounds);
  await db.prepare('INSERT INTO users (username, password_hash) VALUES (?, ?)').run(username, hashedPassword);
  await loadUsers();
  res.redirect(`/?success=${encodeURIComponent('สร้างบัญชีสำเร็จ!')}`);
});

app.get('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/'));
});

app.get('/admin/home', requireLogin, (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'homepage.html'));
});

app.get('/admin/dashboard', requireLogin, (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin-dashboard.html'));
});

app.get('/admin/packages', requireLogin, (req, res) => {
  if (req.query.game) res.sendFile(path.join(__dirname, 'public', 'package-management.html'));
  else res.sendFile(path.join(__dirname, 'public', 'games-dashboard.html'));
});

app.get('/admin/zoe-management', requireLogin, (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'order-management.html'));
});

app.use('/api', requireLogin);

// ========================
// (โค้ด API อื่น ๆ ของคุณ… ทั้ง Orders / Packages / Summary ฯลฯ “คงเดิม”)
// ==> ผมไม่ได้เปลี่ยนฟังก์ชันใด ๆ นอกจากที่เกี่ยวกับเครือข่าย/เซสชันข้างบน
// ========================

// ---- Startup: รอ DB พร้อมก่อนค่อยฟังพอร์ต ----
async function waitForDb({ tries = 12, baseDelay = 1500, factor = 1.6 } = {}) {
  let attempt = 0;
  while (attempt < tries) {
    attempt++;
    try {
      await pgPool.query('select 1');
      console.log('✅ Database is reachable');
      return;
    } catch (err) {
      const delay = Math.round(baseDelay * Math.pow(factor, attempt - 1));
      console.warn(`DB not ready (try ${attempt}/${tries}): ${err.code || err.message}`);
      await new Promise(r => setTimeout(r, delay));
    }
  }
  throw new Error('Database not reachable after retries');
}

async function start() {
  try {
    await waitForDb();
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
    });
  } catch (e) {
    console.error('❌ Fatal: service cannot start', e.message);
    process.exit(1);
  }
}

process.on('SIGTERM', async () => {
  console.log('⏳ Shutting down...');
  try { await pgPool.end(); } catch {}
  process.exit(0);
});

process.on('unhandledRejection', (err) => {
  console.error('UnhandledRejection:', err);
});

start();
