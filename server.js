// server.js
const dns = require('dns');
dns.setDefaultResultOrder('ipv4first'); // กัน IPv6 ก่อนแล้วหลุด

const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const pgPool = require('./database.js');
const PgSessionFactory = require('connect-pg-simple');

const app = express();
const PORT = process.env.PORT || 3000;

app.set('trust proxy', 1);

// --- ค่าคงที่ ---
const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;

// ===== Helper: สร้าง connection string สำหรับ Session Store ที่พอร์ต 5432 =====
function buildSessionConString() {
  const raw =
    (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
    (process.env.DATABASE_URL && process.env.DATABASE_URL.trim());
  if (!raw) return undefined;

  // แปลง :6543 → :5432 (หรือถ้าไม่มีพอร์ต ให้เติม :5432)
  if (/:6543\//.test(raw)) return raw.replace(':6543/', ':5432/');
  if (/:\d+\//.test(raw)) return raw.replace(/:\d+\//, ':5432/');
  return raw.replace(/(supabase\.co|pooler\.supabase\.com)(\/|$)/, '$1:5432$2');
}

const SESSION_CONSTRING = buildSessionConString();

// --- Database wrapper (เหมือนเดิม) ---
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
  transaction: (fn) => fn,
};

// --- โหลดข้อมูลผู้ใช้ (เรียกหลังเซิร์ฟเวอร์พร้อม) ---
let users = {};
async function loadUsers() {
  const userRows = await db.prepare('SELECT username, password_hash FROM users').all();
  users = userRows.reduce((acc, u) => ((acc[u.username] = u.password_hash), acc), {});
  console.log(`👥 Users loaded: ${userRows.length}`);
}

// --- Middleware ---
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// --- Session configuration (มาก่อนทุก route) ---
// ใช้ Session Store ผ่านพอร์ต 5432 เพื่อเสถียรภาพ (ลด ETIMEDOUT ระหว่าง touch session)
const PgSession = PgSessionFactory(session);
app.use(
  session({
    store: new PgSession({
      // ถ้าไม่มี ENV ก็ยังใช้ pool ได้ แต่แนะนำให้ตั้ง ENV ไว้เสมอ
      ...(SESSION_CONSTRING ? { conString: SESSION_CONSTRING } : { pool: pgPool }),
      tableName: 'user_sessions',
      createTableIfMissing: true,
      pruneSessionInterval: 60 * 60, // เก็บกวาดทุก 1 ชม.
      disableTouch: true,            // ไม่ touch ทุก request → ลดภาระ DB
    }),
    secret: 'a-very-secret-key-for-your-session-12345',
    resave: false,
    saveUninitialized: false,
    cookie: {
      maxAge: 30 * 24 * 60 * 60 * 1000,
      secure: process.env.NODE_ENV === 'production',
      httpOnly: true,
    },
  })
);

// เสิร์ฟไฟล์หน้าเว็บ
app.use(express.static(path.join(__dirname, 'public')));

// Health check สำหรับ Render
app.get('/healthz', async (_req, res) => {
  try {
    await pgPool.query('select 1');
    res.status(200).send('ok');
  } catch {
    res.status(500).send('db down');
  }
});

// --- Auth middleware ---
const requireLogin = (req, res, next) => {
  if (req.session.userId) next();
  else res.redirect('/');
};

// --- Routes เดิมทั้งหมด (คงไว้ครบ) ---
app.get('/', (req, res) => {
  if (req.session.userId) res.redirect('/admin/home');
  else res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/register', (_req, res) => res.sendFile(path.join(__dirname, 'public', 'admin-register.html')));
app.get('/terms',    (_req, res) => res.sendFile(path.join(__dirname, 'public', 'terms.html')));

app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  const userHash = users[username];
  if (userHash && (await bcrypt.compare(password, userHash))) {
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
  await loadUsers();
  res.redirect(`/?success=${encodeURIComponent('สร้างบัญชีสำเร็จ!')}`);
});

app.get('/logout', (req, res) => req.session.destroy(() => res.redirect('/')));

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

app.get('/admin/summary', requireLogin, (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin-summary.html'));
});

// ป้องกันทุก /api
app.use('/api', requireLogin);

// ===== API เดิมของคุณทั้งหมด (Dashboard, Game Order, Packages, Orders, Export, Summary) =====
// ... (โค้ดกลุ่ม API เดิมของคุณตามที่ใช้อยู่ปัจจุบัน ให้คงไว้เหมือนเดิม)
// ↓↓↓ ถัดจากนี้คือตัวอย่างบล็อกหลัก ๆ ที่คุณมี (ผมคงโครงสร้างเดิมไว้) ↓↓↓

function buildOrdersQuery(queryParams) {
  const { q = '', status = '', platform = '', startDate, endDate, page = 1, limit = 20 } = queryParams;
  let whereSql = ` FROM orders WHERE 1=1`;
  const params = [];
  let paramIndex = 1;

  if (q) { whereSql += ` AND (order_number ILIKE $${paramIndex++} OR customer_name ILIKE $${paramIndex++})`; params.push(`%${q}%`, `%${q}%`); }
  if (status) { whereSql += ` AND status = $${paramIndex++}`; params.push(status); }
  if (platform) { whereSql += ` AND platform = $${paramIndex++}`; params.push(platform); }
  if (startDate) { whereSql += ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date >= $${paramIndex++}`; params.push(startDate); }
  if (endDate) { whereSql += ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date <= $${paramIndex++}`; params.push(endDate); }

  const countSql = `SELECT COUNT(*) as total` + whereSql;
  let dataSql = `SELECT *` + whereSql + ` ORDER BY created_at DESC`;

  if (limit) {
    dataSql += ` LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(Number(limit), (Number(page) - 1) * Number(limit));
  }

  return { dataSql, countSql, params };
}

// …………… (คง API ของคุณตามไฟล์ก่อนหน้า) ……………

// ---- Startup ----
async function start() {
  try {
    console.log('🚀 Starting app…');
    await pgPool.query('select 1'); // ให้แน่ใจว่าเชื่อมได้ตอนสตาร์ท
    await loadUsers();
    app.listen(PORT, () => console.log(`🟢 Server running on :${PORT}`));
  } catch (e) {
    console.error('❌ Fatal: service cannot start', e.message);
    process.exit(1);
  }
}

process.on('SIGTERM', async () => {
  console.log('⏳ Shutting down…');
  try { await pgPool.end(); } catch {}
  process.exit(0);
});
process.on('unhandledRejection', (err) => console.error('UnhandledRejection:', err));

start();
