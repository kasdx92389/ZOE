// server.js
const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');

const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const pgPool = require('./database.js');                  // proxy Pool กันตาย
const PgSessionFactory = require('connect-pg-simple');

const app = express();
const PORT = process.env.PORT || 3000;
app.set('trust proxy', 1);

// --- constants ---
const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;

// --- build session conString forcing 5432 (เสถียรกว่า) + sslmode=require ---
// (คงไว้ตามไฟล์เดิม แม้ไม่ได้ใช้ เพื่อไม่กระทบส่วนอื่น)
function buildSessionConString() {
  const raw =
    (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
    (process.env.DATABASE_URL && process.env.DATABASE_URL.trim());
  if (!raw) return undefined;

  // บังคับพอร์ต 5432
  let url = raw;
  if (/:6543\//.test(url)) url = url.replace(':6543/', ':5432/');
  else if (/:\d+\//.test(url)) url = url.replace(/:\d+\//, ':5432/');
  else url = url.replace(/(supabase\.co|pooler\.supabase\.com)(\/|$)/, '$1:5432$2');

  // เติม sslmode=require ถ้ายังไม่มี
  if (!/[?&]sslmode=/.test(url)) {
    url += (url.includes('?') ? '&' : '?') + 'sslmode=require';
  }
  return url;
}
const SESSION_CONSTRING = buildSessionConString(); // เดิม (ไม่ใช้แล้วใน session store ใหม่นี้)

/* --------- เพิ่มฟังก์ชันใหม่: สร้าง conObject แบบแยก field และ SSL non-verify --------- */
function buildSessionConObject() {
  const raw =
    (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
    (process.env.DATABASE_URL && process.env.DATABASE_URL.trim());
  if (!raw) return undefined;
  const u = new URL(raw);
  const database = decodeURIComponent(u.pathname.replace(/^\//, ''));
  return {
    host: u.hostname,
    port: 5432, // บังคับพอร์ต 5432 ให้เสถียร
    user: decodeURIComponent(u.username),
    password: decodeURIComponent(u.password),
    database,
    ssl: { rejectUnauthorized: false }, // สำคัญ: กัน self-signed cert
    statement_timeout: 20_000,
    query_timeout: 15_000,
    connectionTimeoutMillis: 10_000,
  };
}
const SESSION_CONOBJECT = buildSessionConObject();
/* ------------------------------------------------------------------------- */

// --- db helper (แปลง ? → $1) ---
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

// --- state & bootstrap helpers ---
let users = {};
async function loadUsers() {
  const rows = await db.prepare('SELECT username, password_hash FROM users').all();
  users = rows.reduce((acc, u) => (acc[u.username] = u.password_hash, acc), {});
  console.log(`👥 Users loaded: ${rows.length}`);
}

// --- middlewares ---
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

/* =========================
 *  session ก่อนทุก route
 *  (อัปเดตเฉพาะส่วนนี้: ใช้ conObject แบบแยก field + SSL non-verify)
 * ========================= */
// ... (ส่วนบนไฟล์เดิมทั้งหมดคงเดิม) ...
const PgSession = PgSessionFactory(session);

// ✅ ใช้ DATABASE_URL ก่อน (Direct 5432) แล้วค่อย fallback ไป POOLER
function pickRawDbUrl() {
  return (
    (process.env.DATABASE_URL && process.env.DATABASE_URL.trim()) ||
    (process.env.DATABASE_URL_POOLER && process.env.DATABASE_URL_POOLER.trim()) ||
    ''
  );
}

// สร้าง conObject แบบแยก field + บังคับ 5432 + SSL non-verify
function buildSessionConObject() {
  const raw = pickRawDbUrl();
  if (!raw) return undefined;
  const u = new URL(raw);
  const database = decodeURIComponent(u.pathname.replace(/^\//, ''));
  return {
    host: u.hostname,            // ถ้าเป็น db-xxxx.supabase.co จะวิ่ง direct
    port: 5432,                  // บังคับพอร์ต 5432 เสมอ
    user: decodeURIComponent(u.username),
    password: decodeURIComponent(u.password),
    database,
    ssl: { rejectUnauthorized: false },   // กัน self-signed
    statement_timeout: 20_000,
    query_timeout: 15_000,
    connectionTimeoutMillis: 10_000,
  };
}
const SESSION_CONOBJECT = buildSessionConObject();

app.use(session({
  store: new PgSession({
    ...(SESSION_CONOBJECT ? { conObject: SESSION_CONOBJECT } : { pool: pgPool }),
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

// static
app.use(express.static(path.join(__dirname, 'public')));

// healths
app.get('/healthz', (_req, res) => res.status(200).send('ok'));
app.get('/readiness', async (_req, res) => {
  try { await pgPool.query('select 1'); res.status(200).send('ready'); }
  catch { res.status(503).send('db not ready'); }
});

// auth
const requireLogin = (req, res, next) => (req.session?.userId ? next() : res.redirect('/'));

// routes (เหมือนเดิม)
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

// guard /api
app.use('/api', requireLogin);

/* =========================
 * ===== Utils สำหรับวันที่ (ใช้ COALESCE) =====
 * ========================= */
const DATE_EXPR = "((COALESCE(order_date, created_at))::timestamptz AT TIME ZONE 'Asia/Bangkok')::date";
const DATE_EXPR_JOIN = DATE_EXPR
  .replace(/order_date/g, 'o.order_date')
  .replace(/created_at/g, 'o.created_at');

// ===== Build Orders Query (แก้ให้ fallback created_at) =====
function buildOrdersQuery(queryParams) {
  const { q = '', status = '', platform = '', startDate, endDate, page = 1, limit = 20 } = queryParams;

  let whereSql = ` FROM orders WHERE 1=1`;
  const params = [];
  let i = 1;

  if (q) {
    whereSql += ` AND (order_number ILIKE $${i++} OR customer_name ILIKE $${i++})`;
    params.push(`%${q}%`, `%${q}%`);
  }
  if (status) { whereSql += ` AND status = $${i++}`; params.push(status); }
  if (platform) { whereSql += ` AND platform = $${i++}`; params.push(platform); }
  if (startDate) { whereSql += ` AND ${DATE_EXPR} >= $${i++}`; params.push(startDate); }
  if (endDate) { whereSql += ` AND ${DATE_EXPR} <= $${i++}`; params.push(endDate); }

  const countSql = `SELECT COUNT(*) AS total` + whereSql;

  let dataSql = `SELECT *` + whereSql + `
    ORDER BY COALESCE(order_date, created_at) DESC, id DESC`;

  if (limit) {
    dataSql += ` LIMIT $${i++} OFFSET $${i++}`;
    params.push(Number(limit), (Number(page) - 1) * Number(limit));
  }
  return { dataSql, countSql, params };
}

// ===== Dashboard & Games Order (เหมือนเดิม) =====
app.get('/api/dashboard-data', async (req, res) => {
  try {
    const { game } = req.query;
    let orderedGames = [];
    const config = await db.prepare("SELECT value FROM app_config WHERE key = 'game_order'").get();
    if (config && config.value) orderedGames = JSON.parse(config.value);

    const allDbGames = (await db.prepare('SELECT DISTINCT game_association FROM packages').all())
      .map((g) => g.game_association);

    const cleaned = orderedGames.filter((g) => allDbGames.includes(g));
    const news = allDbGames.filter((g) => !orderedGames.includes(g));
    const finalOrder = [...cleaned, ...news];
    if (JSON.stringify(finalOrder) !== JSON.stringify(orderedGames)) {
      await db.prepare(
        "INSERT INTO app_config (key, value) VALUES ('game_order', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value"
      ).run(JSON.stringify(finalOrder));
      orderedGames = finalOrder;
    }

    const activeGames = (await db.prepare('SELECT DISTINCT game_association FROM packages WHERE is_active = 1').all())
      .map((g) => g.game_association);
    const finalActive = orderedGames.filter((g) => activeGames.includes(g));

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

app.get('/api/games/order', async (_req, res) => {
  try {
    let orderedGames = [];
    const config = await db.prepare("SELECT value FROM app_config WHERE key = 'game_order'").get();
    if (config && config.value) orderedGames = JSON.parse(config.value);
    res.json(orderedGames);
  } catch (e) {
    console.error('Error fetching game order:', e);
    res.status(500).json({ error: 'Failed to retrieve game order' });
  }
});

app.post('/api/games/order', async (req, res) => {
  try {
    const { gameOrder } = req.body;
    if (!Array.isArray(gameOrder)) return res.status(400).json({ error: 'Invalid data format.' });
    await db.prepare(
      "INSERT INTO app_config (key, value) VALUES ('game_order', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value"
    ).run(JSON.stringify(gameOrder));
    res.json({ ok: true });
  } catch (e) {
    console.error('Error saving game order:', e);
    res.status(500).json({ error: 'Failed to save game order' });
  }
});

// ===== Packages =====
app.post('/api/packages', async (req, res) => {
  try {
    const { name, price, product_code, type, channel, game_association } = req.body;
    const result = await db.prepare(
      'INSERT INTO packages (name, price, product_code, type, channel, game_association) VALUES (?, ?, ?, ?, ?, ?) RETURNING id'
    ).get(name, price, product_code, type, channel, game_association);
    res.status(201).json({ id: result.id, message: 'Package created' });
  } catch (e) {
    console.error('Error creating package:', e);
    res.status(500).json({ error: 'Failed to create package' });
  }
});

app.put('/api/packages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, price, product_code, type, channel, game_association, is_active } = req.body;
    const r = await db.prepare(
      'UPDATE packages SET name = ?, price = ?, product_code = ?, type = ?, channel = ?, game_association = ?, is_active = ? WHERE id = ?'
    ).run(name, price, product_code, type, channel, game_association, is_active, id);
    if (r.rowCount === 0) return res.status(404).json({ error: 'Package not found' });
    res.json({ id, message: 'Package updated' });
  } catch (e) {
    console.error(`Error updating package ${req.params.id}:`, e);
    res.status(500).json({ error: 'Failed to update package' });
  }
});

app.delete('/api/packages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const r = await db.prepare('DELETE FROM packages WHERE id = ?').run(id);
  if (r.rowCount === 0) return res.status(404).json({ error: 'Package not found' });
    res.status(200).json({ message: 'Package deleted' });
  } catch (e) {
    console.error(`Error deleting package ${req.params.id}:`, e);
    res.status(500).json({ error: 'Failed to delete package' });
  }
});

app.post('/api/packages/order', async (req, res) => {
  const { order } = req.body;
  if (!Array.isArray(order)) return res.status(400).json({ error: 'Invalid order data' });
  const c = await pgPool.connect();
  try {
    await c.query('BEGIN');
    for (const [idx, id] of order.entries()) {
      await c.query('UPDATE packages SET sort_order = $1 WHERE id = $2', [idx, id]);
    }
    await c.query('COMMIT');
    res.json({ ok: true, message: 'Package order updated' });
  } catch (e) {
    await c.query('ROLLBACK');
    console.error('Error updating package order:', e);
    res.status(500).json({ error: 'Failed to update package order' });
  } finally { c.release(); }
});

app.post('/api/packages/bulk-actions', async (req, res) => {
  const { action, ids, updates } = req.body;
  if (!action || !Array.isArray(ids) || ids.length === 0)
    return res.status(400).json({ error: 'Invalid request' });

  const c = await pgPool.connect();
  try {
    await c.query('BEGIN');
    if (action === 'delete') {
      await c.query(`DELETE FROM packages WHERE id = ANY($1::int[])`, [ids]);
    } else if (action === 'updateStatus') {
      await c.query(`UPDATE packages SET is_active = $1 WHERE id = ANY($2::int[])`, [req.body.status, ids]);
    } else if (action === 'bulkEdit' && updates) {
      const setClauses = [];
      const params = [];
      let p = 1;
      for (const k in updates) { setClauses.push(`${k} = $${p++}`); params.push(updates[k]); }
      params.push(ids);
      const sql = `UPDATE packages SET ${setClauses.join(', ')} WHERE id = ANY($${p}::int[])`;
      await c.query(sql, params);
    }
    await c.query('COMMIT');
    res.json({ ok: true, message: 'Bulk action successful' });
  } catch (e) {
    await c.query('ROLLBACK');
    console.error('Bulk action error:', e);
    res.status(500).json({ error: 'Failed to perform bulk action' });
  } finally { c.release(); }
});

// ===== Orders (ใช้ COALESCE สำหรับกรอง/จัดเรียง) =====
app.get('/api/orders', async (req, res) => {
  try {
    const { dataSql, countSql, params } = buildOrdersQuery(req.query);
    const [totalResult, ordersResult] = await Promise.all([
      pgPool.query(countSql, params.slice(0, countSql.match(/\$/g)?.length || 0)),
      pgPool.query(dataSql, params),
    ]);
    const total = parseInt(totalResult.rows[0].total, 10);
    const orders = ordersResult.rows;

    // attach items
    const stmt = 'SELECT * FROM order_items WHERE order_id = $1';
    for (const o of orders) {
      const r = await pgPool.query(stmt, [o.id]);
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

    const sql = `INSERT INTO orders(
      order_number, order_date, platform, customer_name, game_name, total_paid,
      payment_proof_url, sales_proof_url, product_code, package_count, packages_text,
      cost, profit, status, operator, topup_channel, note
    ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17) RETURNING id`;

    const r = await c.query(sql, [
      orderNumber, b.order_date, b.platform, b.customer_name, b.game_name, totalPaid,
      b.payment_proof_url, b.sales_proof_url, b.product_code, packageCount, packagesText,
      cost, profit, b.status, b.operator, b.topup_channel, b.note
    ]);
    const orderId = r.rows[0].id;

    if (Array.isArray(b.items) && b.items.length) {
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

app.put('/api/orders/:orderNumber', async (req, res) => {
  const { orderNumber } = req.params;
  const b = req.body;
  const c = await pgPool.connect();
  try {
    await c.query('BEGIN');

    const find = await c.query('SELECT id FROM orders WHERE order_number = $1', [orderNumber]);
    if (find.rows.length === 0) throw new Error('OrderNotFound');
    const id = find.rows[0].id;

    const totalPaid = Number(b.total_paid || 0);
    const cost = Number(b.cost || 0);
    const profit = totalPaid - cost;
    const packagesText = b.items?.map(it => `${it.package_name} x${it.quantity}`).join(', ') || '';
    const packageCount = b.items?.reduce((a,c)=>a+Number(c.quantity||0),0) || 0;

    await c.query(
      `UPDATE orders SET
        order_date=$1, platform=$2, customer_name=$3, game_name=$4, total_paid=$5,
        payment_proof_url=$6, sales_proof_url=$7, product_code=$8,
        package_count=$9, packages_text=$10, cost=$11, profit=$12,
        status=$13, operator=$14, topup_channel=$15, note=$16
       WHERE id=$17`,
      [b.order_date, b.platform, b.customer_name, b.game_name, totalPaid,
       b.payment_proof_url, b.sales_proof_url, b.product_code, packageCount, packagesText,
       cost, profit, b.status, b.operator, b.topup_channel, b.note, id]
    );

    await c.query('DELETE FROM order_items WHERE order_id = $1', [id]);
    if (Array.isArray(b.items) && b.items.length) {
      const itemSql = `INSERT INTO order_items(
        order_id, package_id, package_name, product_code, quantity, unit_price, cost, total_price
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`;
      for (const it of b.items) {
        const qty = Number(it.quantity || 1);
        const unit = Number(it.unit_price || 0);
        await c.query(itemSql, [id, it.package_id, it.package_name, it.product_code, qty, unit, it.cost || 0, qty*unit]);
      }
    }

    await c.query('COMMIT');
    res.json({ ok: true, order_number: orderNumber });
  } catch (e) {
    await c.query('ROLLBACK');
    console.error(`Update order error for ${orderNumber}:`, e);
    if (e.message === 'OrderNotFound') return res.status(404).json({ error: 'Order not found' });
    res.status(500).json({ error: 'Failed to update order' });
  } finally { c.release(); }
});

app.delete('/api/orders/:orderNumber', async (req, res) => {
  const { orderNumber } = req.params;
  try {
    const r = await db.prepare('DELETE FROM orders WHERE order_number = ?').run(orderNumber);
    if (r.rowCount === 0)
      return res.status(404).json({ error: 'Order not found, nothing to delete.' });
    res.json({ ok: true, message: `Order ${orderNumber} and its items were deleted.` });
  } catch (e) {
    console.error(`Delete order error for ${orderNumber}:`, e);
    res.status(500).json({ error: 'Failed to delete order' });
  }
});

// ===== Export CSV (fallback วันที่) =====
app.get('/api/orders/export/csv', async (req, res) => {
  try {
    const queryParams = { ...req.query, limit: null };
    const { dataSql, params } = buildOrdersQuery(queryParams);
    const orders = (await pgPool.query(dataSql, params)).rows;
    if (!orders.length) return res.status(404).send('ไม่มีรายการในออเดอร์ที่เลือก');

    const thaiHeaders = [
      'เลขออเดอร์','วันที่ทำรายการ','ยอดจ่าย','หลักฐานโอนเงิน (URL)',
      'แพลตฟอร์ม','ชื่อลูกค้า','เกม','รายการแพ็กเกจ',
      'ต้นทุน','กำไร','สถานะ','หลักฐานปิดการขาย (URL)',
      'ผู้ทำรายการ','ช่องทางการเติม','หมายเหตุ',
    ];
    const dbCols = [
      'order_number','order_date','total_paid','payment_proof_url',
      'platform','customer_name','game_name','packages_text',
      'cost','profit','status','sales_proof_url','operator','topup_channel','note',
    ];

    let csv = '\ufeff' + thaiHeaders.join(',') + '\n';
    for (const row of orders) {
      const arr = dbCols.map((col) => {
        let v = row[col];
        if (col === 'order_date') {
          const raw = row.order_date || row.created_at;
          if (raw) v = new Date(raw).toLocaleString('en-GB', { timeZone: 'Asia/Bangkok' });
          else v = '';
        } else {
          v = v == null ? '' : String(v);
        }
        return /[,"\n]/.test(String(v)) ? `"${String(v).replace(/"/g,'""')}"` : v;
      });
      csv += arr.join(',') + '\n';
    }
    const name = `orders-export-${new Date().toISOString().slice(0,10)}.csv`;
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${name}"`);
    res.status(200).end(csv);
  } catch (e) {
    console.error('Failed to export orders:', e);
    res.status(500).send('Failed to export orders.');
  }
});

// ===== Summary (ใช้ COALESCE สำหรับช่วงวันที่) =====
function _buildSummaryWhere(startDate, endDate) {
  let whereSql = ' WHERE 1=1';
  const params = [];
  let i = 1;
  if (startDate) { whereSql += ` AND ${DATE_EXPR} >= $${i++}`; params.push(startDate); }
  if (endDate) { whereSql += ` AND ${DATE_EXPR} <= $${i++}`; params.push(endDate); }
  return { whereSql, params };
}

app.get('/api/summary', async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const { whereSql, params } = _buildSummaryWhere(startDate, endDate);

    const totals = (await pgPool.query(`
      SELECT COUNT(*)::int AS order_count,
             COALESCE(SUM(total_paid),0)::numeric AS revenue,
             COALESCE(SUM(cost),0)::numeric AS cost,
             COALESCE(SUM(profit),0)::numeric AS profit
      FROM orders` + whereSql, params)).rows?.[0] || {};

    const daily = (await pgPool.query(`
      SELECT ${DATE_EXPR} AS day,
             COALESCE(SUM(total_paid),0)::numeric AS revenue,
             COALESCE(SUM(cost),0)::numeric AS cost,
             COALESCE(SUM(profit),0)::numeric AS profit
      FROM orders` + whereSql + ` GROUP BY 1 ORDER BY 1`, params)).rows || [];

    const byGame = (await pgPool.query(`
      SELECT COALESCE(o.game_name, 'UNKNOWN') AS game,
             COALESCE(SUM(oi.total_price),0)::numeric AS revenue,
             COALESCE(SUM(oi.cost),0)::numeric AS cost,
             COALESCE(SUM(oi.quantity),0)::numeric AS units
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      ${_buildSummaryWhere(startDate, endDate).whereSql.replace(DATE_EXPR, DATE_EXPR_JOIN)}
      GROUP BY 1
      ORDER BY revenue DESC NULLS LAST
      LIMIT 10`, params)).rows || [];

    const byPlatform = (await pgPool.query(`
      SELECT COALESCE(platform,'UNKNOWN') AS platform,
             COUNT(*)::int AS order_count,
             COALESCE(SUM(total_paid),0)::numeric AS revenue
      FROM orders` + whereSql + `
      GROUP BY 1
      ORDER BY revenue DESC NULLS LAST`, params)).rows || [];

    const byStatus = (await pgPool.query(`
      SELECT COALESCE(status,'UNKNOWN') AS status,
             COUNT(*)::int AS count
      FROM orders` + whereSql + `
      GROUP BY 1
      ORDER BY count DESC NULLS LAST`, params)).rows || [];

    res.json({
      totals: {
        orders: Number(totals.order_count || 0),
        revenue: Number(totals.revenue || 0),
        cost: Number(totals.cost || 0),
        profit: Number(totals.profit || 0),
        margin: Number(totals.revenue || 0) > 0
          ? Number(totals.profit || 0) / Number(totals.revenue || 0)
          : 0,
      },
      daily, byGame, byPlatform, byStatus,
    });
  } catch (e) {
    console.error('Summary API error:', e);
    res.status(500).json({ error: 'Failed to load summary' });
  }
});

// ---- start server ทันที แล้ว hydrate users แบบ background ----
app.listen(PORT, () => console.log(`🟢 Server running on :${PORT}`));
(async function hydrate() {
  try { await loadUsers(); }
  catch (e) { console.warn('loadUsers failed, retrying soon:', e.code || e.message); setTimeout(hydrate, 5000); }
})();
