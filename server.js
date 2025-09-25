// server.js
const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');

const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const pgPool = require('./database.js');
const PgSessionFactory = require('connect-pg-simple');

const app = express();
const PORT = process.env.PORT || 3000;
app.set('trust proxy', 1);

const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;

// -------- Build Session Connection String (force 5432) --------
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

// -------- DB helpers --------
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

// -------- App state --------
let READY = false;
let users = {};
async function loadUsers() {
  const rows = await db.prepare('SELECT username, password_hash FROM users').all();
  users = rows.reduce((acc, u) => (acc[u.username] = u.password_hash, acc), {});
  console.log(`👥 Users loaded: ${rows.length}`);
}

// -------- Core middlewares --------
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Session ก่อนทุก route (ใช้ 5432 เพื่อลด ETIMEDOUT)
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

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Health checks
app.get('/healthz', (_req, res) => res.status(200).send('ok'));
app.get('/readiness', async (_req, res) => {
  if (!READY) return res.status(503).send('starting');
  try { await pgPool.query('select 1'); return res.status(200).send('ready'); }
  catch { return res.status(503).send('db not ready'); }
});

// Auth guard
const requireLogin = (req, res, next) => (req.session?.userId ? next() : res.redirect('/'));

// ------------- ROUTES (คงของเดิมทั้งหมด) -------------
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

// ป้องกันทุก /api
app.use('/api', requireLogin);

// --------- APIs เดิม (Dashboard/Games/Packages/Orders/Export/Summary) ---------
function buildOrdersQuery(queryParams) {
  const { q = '', status = '', platform = '', startDate, endDate, page = 1, limit = 20 } = queryParams;
  let whereSql = ` FROM orders WHERE 1=1`;
  const params = [];
  let i = 1;
  if (q)        { whereSql += ` AND (order_number ILIKE $${i++} OR customer_name ILIKE $${i++})`; params.push(`%${q}%`, `%${q}%`); }
  if (status)   { whereSql += ` AND status = $${i++}`;    params.push(status); }
  if (platform) { whereSql += ` AND platform = $${i++}`;  params.push(platform); }
  if (startDate){ whereSql += ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date >= $${i++}`; params.push(startDate); }
  if (endDate)  { whereSql += ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date <= $${i++}`; params.push(endDate); }
  const countSql = `SELECT COUNT(*) as total` + whereSql;
  let dataSql = `SELECT *` + whereSql + ` ORDER BY created_at DESC`;
  if (limit) { dataSql += ` LIMIT $${i++} OFFSET $${i++}`; params.push(Number(limit), (Number(page)-1)*Number(limit)); }
  return { dataSql, countSql, params };
}

app.get('/api/dashboard-data', async (req, res) => {
  try {
    const { game } = req.query;
    let orderedGames = [];
    const cfg = await db.prepare("SELECT value FROM app_config WHERE key = 'game_order'").get();
    if (cfg?.value) orderedGames = JSON.parse(cfg.value);
    const allDbGames = (await db.prepare("SELECT DISTINCT game_association FROM packages").all()).map(g => g.game_association);
    const cleaned = orderedGames.filter(g => allDbGames.includes(g));
    const news = allDbGames.filter(g => !orderedGames.includes(g));
    const finalOrder = [...cleaned, ...news];
    if (JSON.stringify(finalOrder) !== JSON.stringify(orderedGames)) {
      await db.prepare("INSERT INTO app_config (key, value) VALUES ('game_order', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value").run(JSON.stringify(finalOrder));
      orderedGames = finalOrder;
    }
    const activeGames = (await db.prepare("SELECT DISTINCT game_association FROM packages WHERE is_active = 1").all()).map(g => g.game_association);
    const finalActive = orderedGames.filter(g => activeGames.includes(g));
    let q = 'SELECT * FROM packages', p = [];
    if (game) { q += ' WHERE game_association = ?'; p.push(game); }
    q += ' ORDER BY sort_order ASC, name ASC';
    const packages = await db.prepare(q).all(...p);
    res.json({ packages, games: finalActive });
  } catch (e) {
    console.error('Error fetching dashboard data:', e);
    res.status(500).json({ error: 'Failed to retrieve dashboard data' });
  }
});

// ... (คง API กลุ่ม games/order/packages/bulk/edit/delete ตามไฟล์เดิม)
// **ใส่บล็อคคำสั่งเดิมทั้งหมดของคุณตรงนี้ได้ตามที่ใช้อยู่**

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
  const y = d.getFullYear(), m = String(d.getMonth()+1).padStart(2,'0'), day = String(d.getDate()).padStart(2,'0');
  return `ODR-${y}${m}${day}-${Math.floor(Math.random()*9000)+1000}`;
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
    ) VALUES (
      $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17
    ) RETURNING id`;

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

// (PUT /api/orders/:orderNumber, DELETE, bulk-actions, export CSV, summary API — คงตามเดิมของคุณ)

// -------- Start server “ทันที” และ init DB แบบ background + retry --------
app.listen(PORT, () => console.log(`🟢 Server running on :${PORT}`));

(async function initDb() {
  try {
    console.log('🚀 Init DB…');
    await pgPool.query('select 1');
    await loadUsers();
    READY = true;
    console.log('✅ DB ready');
  } catch (e) {
    console.error('⚠️ Init DB failed:', e.code || e.message);
    // retry background ใน 5 วิ โดยไม่ปิดโปรเซส
    setTimeout(initDb, 5000);
  }
})();

process.on('SIGTERM', async () => {
  console.log('⏳ Shutting down…');
  try { await pgPool.end(); } catch {}
  process.exit(0);
});
process.on('unhandledRejection', (err) => console.error('UnhandledRejection:', err));
