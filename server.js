// server.js
const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');

const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const pgPool = require('./database.js');                // proxy Pool จากไฟล์ด้านบน
const PgSessionFactory = require('connect-pg-simple');

const app = express();
const PORT = process.env.PORT || 3000;
app.set('trust proxy', 1);

const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;

// -------- สร้าง conString ของ Session ให้บังคับ 5432 --------
function buildSessionConString() {
  const raw =
    (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
    (process.env.DATABASE_URL && process.env.DATABASE_URL.trim());
  if (!raw) return undefined;
  if (/:6543\//.test(raw)) return raw.replace(':6543/', ':5432/');
  if (/:\d+\//.test(raw)) return raw.replace(/:\d+\//, ':5432/');
  return raw.replace(/(supabase\.co|pooler\.supabase\.com)(\/|$)/, '$1:5432$2');
}
const SESSION_CONSTRING = buildSessionConString();

// -------- DB helper (เหมือนเดิม แต่ใช้ proxyPool.query ภายใน) --------
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

// -------- Global state --------
let users = {};
async function loadUsers() {
  const rows = await db.prepare('SELECT username, password_hash FROM users').all();
  users = rows.reduce((acc, u) => (acc[u.username] = u.password_hash, acc), {});
  console.log(`👥 Users loaded: ${rows.length}`);
}

// -------- Middlewares --------
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Session ตั้งแต่ต้น (ใช้ 5432 + disableTouch ลดโหลด)
const PgSession = PgSessionFactory(session);
app.use(session({
  store: new PgSession({
    ...(SESSION_CONSTRING ? { conString: SESSION_CONSTRING } : { pool: pgPool }),
    tableName: 'user_sessions',
    createTableIfMissing: true,
    pruneSessionInterval: 3600,
    disableTouch: true,
  }),
  secret: 'a-very-secret-key-for-your-session-12345',
  resave: false,
  saveUninitialized: false,
  cookie: {
    maxAge: 30 * 24 * 60 * 60 * 1000,
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
  },
}));

// Static
app.use(express.static(path.join(__dirname, 'public')));

// Healths
app.get('/healthz', (_req, res) => res.status(200).send('ok'));
app.get('/readiness', async (_req, res) => {
  try { await pgPool.query('select 1'); res.status(200).send('ready'); }
  catch { res.status(503).send('db not ready'); }
});

// Auth
const requireLogin = (req, res, next) => (req.session?.userId ? next() : res.redirect('/'));

// -------- Routes (คงของเดิมทั้งหมด) --------
app.get('/', (req, res) => {
  if (req.session?.userId) res.redirect('/admin/home');
  else res.sendFile(path.join(__dirname, 'public', 'index.html'));
});
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
  await loadUsers();
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

// Protect /api
app.use('/api', requireLogin);

/* ===============================
   ==== APIs เดิมทั้งหมดของคุณ ====
   (Dashboard, Game Order, Packages, Orders CRUD, Export CSV, Summary)
   *** โค้ดส่วน API ที่คุณใช้อยู่เดิมให้คงไว้ทั้งหมด ***
   ข้างล่างนี้เป็นบล็อกหลักที่ต้องมี (คงตามที่คุณใช้)
================================= */

function buildOrdersQuery(queryParams) {
  const { q = '', status = '', platform = '', startDate, endDate, page = 1, limit = 20 } = queryParams;
  let whereSql = ` FROM orders WHERE 1=1`;
  const params = [];
  let i = 1;
  if (q)        { whereSql += ` AND (order_number ILIKE $${i++} OR customer_name ILIKE $${i++})`; params.push(`%${q}%`, `%${q}%`); }
  if (status)   { whereSql += ` AND status = $${i++}`; params.push(status); }
  if (platform) { whereSql += ` AND platform = $${i++}`; params.push(platform); }
  if (startDate){ whereSql += ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date >= $${i++}`; params.push(startDate); }
  if (endDate)  { whereSql += ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date <= $${i++}`; params.push(endDate); }
  const countSql = `SELECT COUNT(*) as total` + whereSql;
  let dataSql = `SELECT *` + whereSql + ` ORDER BY created_at DESC`;
  if (limit) { dataSql += ` LIMIT $${i++} OFFSET $${i++}`; params.push(Number(limit), (Number(page)-1)*Number(limit)); }
  return { dataSql, countSql, params };
}

app.get('/api/orders', async (req, res) => {
  try {
    const { dataSql, countSql, params } = buildOrdersQuery(req.query);
    const [totalRes, ordersRes] = await Promise.all([
      pgPool.query(countSql, params.slice(0, countSql.match(/\$/g)?.length || 0)),
      pgPool.query(dataSql, params),
    ]);
    const total = parseInt(totalRes.rows[0].total, 10);
    const orders = ordersRes.rows;
    const itemsStmt = 'SELECT * FROM order_items WHERE order_id = $1';
    for (const o of orders) {
      const r = await pgPool.query(itemsStmt, [o.id]);
      o.items = r.rows;
    }
    res.json({ orders, total });
  } catch (e) {
    console.error('Orders list error', e);
    res.status(500).json({ error: 'Failed to load orders' });
  }
});

function genOrderNumber() {
  const d = new Date();
  return `ODR-${d.getFullYear()}${String(d.getMonth()+1).padStart(2,'0')}${String(d.getDate()).padStart(2,'0')}-${Math.floor(Math.random()*9000)+1000}`;
}

app.post('/api/orders', async (req, res) => {
  const b = req.body;
  const c = await pgPool.connect();
  try {
    await c.query('BEGIN');
    const orderNumber = genOrderNumber();
    const totalPaid = Number(b.total_paid || 0);
    const cost = Number(b.cost || 0);
    const profit = totalPaid - cost;
    const packagesText = b.items?.map(it => `${it.package_name} x${it.quantity}`).join(', ') || '';
    const packageCount = b.items?.reduce((a,c)=>a+Number(c.quantity||0),0) || 0;

    const orderQuery = `INSERT INTO orders(
      order_number, order_date, platform, customer_name, game_name, total_paid,
      payment_proof_url, sales_proof_url, product_code, package_count, packages_text,
      cost, profit, status, operator, topup_channel, note
    ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17) RETURNING id`;

    const orderResult = await c.query(orderQuery, [
      orderNumber, b.order_date, b.platform, b.customer_name, b.game_name, totalPaid,
      b.payment_proof_url, b.sales_proof_url, b.product_code, packageCount, packagesText,
      cost, profit, b.status, b.operator, b.topup_channel, b.note
    ]);
    const orderId = orderResult.rows[0].id;

    if (Array.isArray(b.items) && b.items.length > 0) {
      const itemSql = `INSERT INTO order_items(
        order_id, package_id, package_name, product_code, quantity, unit_price, cost, total_price
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`;
      for (const it of b.items) {
        const qty = Number(it.quantity || 1);
        const unit = Number(it.unit_price || 0);
        await c.query(itemSql, [orderId, it.package_id, it.package_name, it.product_code, qty, unit, it.cost || 0, qty*unit]);
      }
    }
    await c.query('COMMIT');
    res.status(201).json({ id: orderId, order_number: orderNumber });
  } catch (e) {
    await c.query('ROLLBACK');
    console.error('Create order error', e);
    res.status(500).json({ error: 'Failed to create order' });
  } finally { c.release(); }
});

// … (PUT /api/orders/:orderNumber, DELETE, bulk-actions, export, summary — คงของเดิม)

app.listen(PORT, () => console.log(`🟢 Server running on :${PORT}`));

// Hydrate users แบบ background (จะรอ proxyPool พร้อมเอง)
(async function hydrate() {
  try { await loadUsers(); }
  catch (e) { console.warn('loadUsers failed, retrying soon:', e.code || e.message); setTimeout(hydrate, 5000); }
})();
