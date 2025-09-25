
// --- Imports (ES Modules) ---
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import session from 'express-session';
import bcrypt from 'bcrypt';
import pgPool, { waitForDbReady, q } from './database.js';
import { createClient } from 'redis';
import { RedisStore } from 'connect-redis';

// --- ตั้งค่า __dirname สำหรับ ES Modules ---
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
// Render จะส่ง PORT มาเป็น env ด้วย แต่ของเดิมใช้ 3000 ก็รองรับทั้งคู่
const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;

// --- การตั้งค่า Redis Client ---
const isProduction = process.env.NODE_ENV === 'production';
let redisClient;

try {
  if (isProduction) {
    redisClient = createClient({ url: process.env.REDIS_URL });
  } else {
    redisClient = createClient();
  }
  redisClient.on('error', (err) => console.log('Redis Client Error', err));
  await redisClient.connect();
  console.log(
    isProduction
      ? 'Connecting to external Redis for session storage...'
      : 'Connecting to local Redis for session storage...'
  );
} catch (e) {
  console.error(
    'Redis connect failed, falling back to in-memory session (not recommended in prod):',
    e?.message
  );
}

const redisStore = redisClient
  ? new RedisStore({
      client: redisClient,
      prefix: 'webapp-sess:',
    })
  : undefined;

app.set('trust proxy', 1);

// --- ค่าคงที่ ---
const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;

// --- Database wrapper (ให้วิ่งผ่าน q() ที่มี retry) ---
const db = {
  prepare: (sql) => {
    let paramIndex = 1;
    const pgSql = sql.replace(/\?/g, () => `$${paramIndex++}`);
    return {
      get: async (...params) => {
        const res = await q(pgSql, params);
        return res.rows[0];
      },
      all: async (...params) => {
        const res = await q(pgSql, params);
        return res.rows;
      },
      run: async (...params) => {
        return await q(pgSql, params);
      },
    };
  },
  exec: async (sql) => await q(sql),
  transaction: async (callback) => {
    const client = await pgPool.connect();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },
};

// --- โหลดข้อมูลผู้ใช้ ---
let users = {};
const loadUsers = async () => {
  const userRows = await db
    .prepare('SELECT username, password_hash FROM users')
    .all();
  users = userRows.reduce((acc, user) => {
    acc[user.username] = user.password_hash;
    return acc;
  }, {});
  console.log('Users loaded from database.');
};

async function loadUsersWithRetry(max = 5) {
  let tries = 0,
    delay = 500;
  while (tries < max) {
    try {
      await loadUsers();
      return;
    } catch (e) {
      tries++;
      console.error(
        `Failed to load users (try ${tries}/${max}):`,
        e?.code || e?.message
      );
      if (tries >= max) throw e;
      await new Promise((r) => setTimeout(r, delay));
      delay = Math.min(delay * 2, 8_000);
    }
  }
}

// --- Middleware ---
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// --- Session configuration ---
app.use(
  session({
    store: redisStore,
    secret: process.env.SESSION_SECRET || 'a-very-secret-key-for-your-session-12345',
    resave: false,
    saveUninitialized: false,
    name: 'sid',
    cookie: {
      maxAge: 30 * 24 * 60 * 60 * 1000,
      secure: isProduction,
      httpOnly: true,
      sameSite: 'lax',
    },
    rolling: true,
  })
);

app.use(express.static(path.join(__dirname, 'public')));

// --- Auth helper ---
const requireLogin = (req, res, next) => {
  if (req.session.userId) {
    next();
  } else {
    res.redirect('/');
  }
};

// --- Routes (เดิม) ---
app.get('/', (req, res) => {
  if (req.session.userId) {
    res.redirect('/admin/home');
  } else {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
  }
});

app.get('/register', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin-register.html'));
});

app.get('/terms', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'terms.html'));
});

app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  const userHash = users[username];
  if (userHash && (await bcrypt.compare(password, userHash))) {
    req.session.userId = username;
    return res.redirect('/admin/home');
  }
  res.redirect(
    `/?error=${encodeURIComponent('Username หรือ Password ไม่ถูกต้อง')}`
  );
});

app.post('/register', async (req, res) => {
  const { username, password, master_code } = req.body;
  if (master_code !== MASTER_CODE)
    return res.redirect(
      `/register?error=${encodeURIComponent('รหัสโค้ดลับไม่ถูกต้อง.')}`
    );
  if (users[username])
    return res.redirect(
      `/register?error=${encodeURIComponent('Username นี้มีผู้ใช้งานแล้ว.')}`
    );

  const hashedPassword = await bcrypt.hash(password, saltRounds);
  await db
    .prepare('INSERT INTO users (username, password_hash) VALUES (?, ?)')
    .run(username, hashedPassword);

  await loadUsersWithRetry(3);
  res.redirect(`/?success=${encodeURIComponent('สร้างบัญชีสำเร็จ!')}`);
});

app.get('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error('Error destroying session on logout:', err);
    }
    res.redirect('/');
  });
});

app.get('/admin/home', requireLogin, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'homepage.html'));
});

app.get('/admin/dashboard', requireLogin, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin-dashboard.html'));
});

app.get('/admin/packages', requireLogin, (req, res) => {
  if (req.query.game) {
    res.sendFile(path.join(__dirname, 'public', 'package-management.html'));
  } else {
    res.sendFile(path.join(__dirname, 'public', 'games-dashboard.html'));
  }
});

app.get('/admin/zoe-management', requireLogin, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'order-management.html'));
});

// --- ต้องล็อกอินก่อนสำหรับ /api/*
app.use('/api', requireLogin);

// --- Helpers สำหรับ Orders & Summary ---
function buildOrdersQuery(queryParams) {
  const {
    q: keyword = '',
    status = '',
    platform = '',
    startDate,
    endDate,
    page = 1,
    limit = 20,
  } = queryParams;

  let whereSql = ` FROM orders WHERE 1=1`;
  const params = [];
  let paramIndex = 1;

  if (keyword) {
    whereSql += ` AND (order_number ILIKE $${paramIndex++} OR customer_name ILIKE $${paramIndex++})`;
    params.push(`%${keyword}%`, `%${keyword}%`);
  }
  if (status) {
    whereSql += ` AND status = $${paramIndex++}`;
    params.push(status);
  }
  if (platform) {
    whereSql += ` AND platform = $${paramIndex++}`;
    params.push(platform);
  }
  if (startDate) {
    whereSql += ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date >= $${paramIndex++}`;
    params.push(startDate);
  }
  if (endDate) {
    whereSql += ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date <= $${paramIndex++}`;
    params.push(endDate);
  }

  const countSql = `SELECT COUNT(*) as total` + whereSql;
  let dataSql = `SELECT *` + whereSql + ` ORDER BY created_at DESC`;

  if (limit) {
    dataSql += ` LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(Number(limit), (Number(page) - 1) * Number(limit));
  }

  return { dataSql, countSql, params };
}

app.get('/api/orders', async (req, res) => {
  try {
    const { dataSql, countSql, params } = buildOrdersQuery(req.query);

    const countParamsLen = (countSql.match(/\$/g) || []).length;
    const totalResult = await q(countSql, params.slice(0, countParamsLen));
    const ordersResult = await q(dataSql, params);

    const total = parseInt(totalResult.rows[0].total, 10);
    const orders = ordersResult.rows;

    const itemsStmt = 'SELECT * FROM order_items WHERE order_id = $1';
    for (const order of orders) {
      const itemsResult = await q(itemsStmt, [order.id]);
      order.items = itemsResult.rows;
    }

    res.json({ orders, total });
  } catch (e) {
    console.error('Orders list error', e);
    res.status(500).json({ error: 'Failed to load orders' });
  }
});

function genOrderNumber() {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const seq = Math.floor(Math.random() * 9000) + 1000;
  return `ODR-${y}${m}${day}-${seq}`;
}

app.post('/api/orders', async (req, res) => {
  const b = req.body;
  try {
    const { id: orderId, order_number: orderNumber } = await db.transaction(
      async (client) => {
        const orderNumber = genOrderNumber();
        const totalPaid = Number(b.total_paid || 0);
        const cost = Number(b.cost || 0);
        const profit = totalPaid - cost;
        const packagesText =
          b.items?.map((it) => `${it.package_name} x${it.quantity}`).join(', ') ||
          '';
        const packageCount =
          b.items?.reduce((a, c) => a + Number(c.quantity || 0), 0) || 0;

        const orderQuery = `INSERT INTO orders(order_number, order_date, platform, customer_name, game_name, total_paid, payment_proof_url, sales_proof_url, product_code, package_count, packages_text, cost, profit, status, operator, topup_channel, note) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17) RETURNING id`;
        const orderResult = await client.query(orderQuery, [
          orderNumber,
          b.order_date,
          b.platform,
          b.customer_name,
          b.game_name,
          totalPaid,
          b.payment_proof_url,
          b.sales_proof_url,
          b.product_code,
          packageCount,
          packagesText,
          cost,
          profit,
          b.status,
          b.operator,
          b.topup_channel,
          b.note,
        ]);
        const newOrderId = orderResult.rows[0].id;

        if (Array.isArray(b.items) && b.items.length > 0) {
          const itemQuery = `INSERT INTO order_items(order_id, package_id, package_name, product_code, quantity, unit_price, cost, total_price) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`;
          for (const it of b.items) {
            const qty = Number(it.quantity || 1);
            const unit = Number(it.unit_price || 0);
            await client.query(itemQuery, [
              newOrderId,
              it.package_id,
              it.package_name,
              it.product_code,
              qty,
              unit,
              it.cost || 0,
              qty * unit,
            ]);
          }
        }
        return { id: newOrderId, order_number: orderNumber };
      }
    );
    res.status(201).json({ id: orderId, order_number: orderNumber });
  } catch (e) {
    console.error('Create order error', e);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

app.put('/api/orders/:orderNumber', async (req, res) => {
  const { orderNumber } = req.params;
  const b = req.body;
  try {
    await db.transaction(async (client) => {
      const orderResult = await client.query(
        'SELECT id FROM orders WHERE order_number = $1',
        [orderNumber]
      );
      if (orderResult.rows.length === 0) throw new Error('OrderNotFound');

      const numericId = orderResult.rows[0].id;
      const totalPaid = Number(b.total_paid || 0);
      const cost = Number(b.cost || 0);
      const profit = totalPaid - cost;
      const packagesText =
        b.items?.map((it) => `${it.package_name} x${it.quantity}`).join(', ') ||
        '';
      const packageCount =
        b.items?.reduce((a, c) => a + Number(c.quantity || 0), 0) || 0;

      await client.query(
        `UPDATE orders SET order_date=$1, platform=$2, customer_name=$3, game_name=$4, total_paid=$5, payment_proof_url=$6, sales_proof_url=$7, product_code=$8, package_count=$9, packages_text=$10, cost=$11, profit=$12, status=$13, operator=$14, topup_channel=$15, note=$16 WHERE id=$17`,
        [
          b.order_date,
          b.platform,
          b.customer_name,
          b.game_name,
          totalPaid,
          b.payment_proof_url,
          b.sales_proof_url,
          b.product_code,
          packageCount,
          packagesText,
          cost,
          profit,
          b.status,
          b.operator,
          b.topup_channel,
          b.note,
          numericId,
        ]
      );

      await client.query('DELETE FROM order_items WHERE order_id = $1', [
        numericId,
      ]);
      if (Array.isArray(b.items) && b.items.length > 0) {
        const itemQuery = `INSERT INTO order_items(order_id, package_id, package_name, product_code, quantity, unit_price, cost, total_price) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`;
        for (const newItem of b.items) {
          const qty = Number(newItem.quantity || 1);
          const unit = Number(newItem.unit_price || 0);
          await client.query(itemQuery, [
            numericId,
            newItem.package_id,
            newItem.package_name,
            newItem.product_code,
            qty,
            unit,
            newItem.cost || 0,
            qty * unit,
          ]);
        }
      }
    });
    res.json({ ok: true, order_number: orderNumber });
  } catch (e) {
    console.error(`Update order error for ${orderNumber}:`, e);
    if (e.message === 'OrderNotFound')
      return res.status(404).json({ error: 'Order not found' });
    res.status(500).json({ error: 'Failed to update order' });
  }
});

app.delete('/api/orders/:orderNumber', async (req, res) => {
  const { orderNumber } = req.params;
  try {
    const result = await db
      .prepare('DELETE FROM orders WHERE order_number = ?')
      .run(orderNumber);
    if (result.rowCount === 0)
      return res
        .status(404)
        .json({ error: 'Order not found, nothing to delete.' });
    res.json({ ok: true, message: `Order ${orderNumber} and its items were deleted.` });
  } catch (e) {
    console.error(`Delete order error for ${orderNumber}:`, e);
    res.status(500).json({ error: 'Failed to delete order' });
  }
});

app.get('/api/orders/export/csv', async (req, res) => {
  try {
    const queryParams = { ...req.query, limit: null };
    const { dataSql, params } = buildOrdersQuery(queryParams);

    const ordersResult = await q(dataSql, params);
    const orders = ordersResult.rows;

    if (orders.length === 0) {
      return res.status(404).send('ไม่มีรายการในออเดอร์ที่เลือก');
    }

    const thaiHeaders = [
      'เลขออเดอร์',
      'วันที่ทำรายการ',
      'ยอดจ่าย',
      'หลักฐานโอนเงิน (URL)',
      'แพลตฟอร์ม',
      'ชื่อลูกค้า',
      'เกม',
      'รายการแพ็กเกจ',
      'ต้นทุน',
      'กำไร',
      'สถานะ',
      'หลักฐานปิดการขาย (URL)',
      'ผู้ทำรายการ',
      'ช่องทางการเติม',
      'หมายเหตุ',
    ];

    const dbColumns = [
      'order_number',
      'order_date',
      'total_paid',
      'payment_proof_url',
      'platform',
      'customer_name',
      'game_name',
      'packages_text',
      'cost',
      'profit',
      'status',
      'sales_proof_url',
      'operator',
      'topup_channel',
      'note',
    ];

    let csv = '\ufeff' + thaiHeaders.join(',') + '\n';

    for (const order of orders) {
      const row = dbColumns.map((header) => {
        let value = order[header];

        if (header === 'order_date' && value) {
          const date = new Date(value);
          value = date.toLocaleString('en-GB', { timeZone: 'Asia/Bangkok' });
        } else {
          value = value === null || value === undefined ? '' : String(value);
        }

        if (
          String(value).includes(',') ||
          String(value).includes('"') ||
          String(value).includes('\n')
        ) {
          value = `"${String(value).replace(/"/g, '""')}"`;
        }
        return value;
      });
      csv += row.join(',') + '\n';
    }

    const fileName = `orders-export-${new Date()
      .toISOString()
      .slice(0, 10)}.csv`;
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${fileName}"`
    );

    res.status(200).end(csv);
  } catch (error) {
    console.error('Failed to export orders:', error);
    res.status(500).send('Failed to export orders.');
  }
});

/** Summary */
app.get('/admin/summary', requireLogin, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin-summary.html'));
});

function _buildSummaryWhere(startDate, endDate) {
  let whereSql = ' WHERE 1=1';
  const params = [];
  let i = 1;
  if (startDate) {
    whereSql +=
      ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date >= $${i++}`;
    params.push(startDate);
  }
  if (endDate) {
    whereSql +=
      ` AND ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date <= $${i++}`;
    params.push(endDate);
  }
  return { whereSql, params };
}

app.get('/api/summary', async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const { whereSql, params } = _buildSummaryWhere(startDate, endDate);

    const totalsSql =
      `
      SELECT 
        COUNT(*)::int AS order_count,
        COALESCE(SUM(total_paid),0)::numeric AS revenue,
        COALESCE(SUM(cost),0)::numeric AS cost,
        COALESCE(SUM(profit),0)::numeric AS profit
      FROM orders` + whereSql;

    const totalsRow = (await q(totalsSql, params)).rows?.[0] || {};

    const dailySql =
      `
      SELECT 
        ((order_date::timestamptz) AT TIME ZONE 'Asia/Bangkok')::date AS day,
        COALESCE(SUM(total_paid),0)::numeric AS revenue,
        COALESCE(SUM(cost),0)::numeric AS cost,
        COALESCE(SUM(profit),0)::numeric AS profit
      FROM orders` + whereSql + ' GROUP BY 1 ORDER BY 1';

    const daily = (await q(dailySql, params)).rows || [];

    const whereJoin = whereSql.replace(/order_date/g, 'o.order_date');
    const byGameSql =
      `
      SELECT
        COALESCE(o.game_name, 'UNKNOWN') AS game,
        COALESCE(SUM(oi.total_price),0)::numeric AS revenue,
        COALESCE(SUM(oi.cost),0)::numeric AS cost,
        COALESCE(SUM(oi.quantity),0)::numeric AS units
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id` +
      whereJoin +
      `
      GROUP BY 1
      ORDER BY revenue DESC NULLS LAST
      LIMIT 10`;

    const byGame = (await q(byGameSql, params)).rows || [];

    const byPlatformSql =
      `
      SELECT 
        COALESCE(platform,'UNKNOWN') AS platform,
        COUNT(*)::int AS order_count,
        COALESCE(SUM(total_paid),0)::numeric AS revenue
      FROM orders` +
      whereSql +
      `
      GROUP BY 1
      ORDER BY revenue DESC NULLS LAST`;

    const byPlatform = (await q(byPlatformSql, params)).rows || [];

    const byStatusSql =
      `
      SELECT 
        COALESCE(status,'UNKNOWN') AS status,
        COUNT(*)::int AS count
      FROM orders` + whereSql + ' GROUP BY 1 ORDER BY count DESC NULLS LAST';

    const byStatus = (await q(byStatusSql, params)).rows || [];

    res.json({
      totals: {
        orders: Number(totalsRow.order_count || 0),
        revenue: Number(totalsRow.revenue || 0),
        cost: Number(totalsRow.cost || 0),
        profit: Number(totalsRow.profit || 0),
        margin:
          Number(totalsRow.revenue || 0) > 0
            ? Number(totalsRow.profit || 0) / Number(totalsRow.revenue || 0)
            : 0,
      },
      daily,
      byGame,
      byPlatform,
      byStatus,
    });
  } catch (err) {
    console.error('Summary API error:', err);
    res.status(500).json({ error: 'Failed to load summary' });
  }
});

/** Health check for Render
 *  หมายเหตุ: ตอบ 200 เสมอเพื่อกัน Render รีสตาร์ตลูปขณะ DB ไม่พร้อม
 *  ใส่สถานะ db ลงข้อความเพื่อ debug เอง
 */
app.get('/healthz', async (_req, res) => {
  let db = 'down';
  try {
    await q('SELECT 1');
    db = 'up';
  } catch {}
  res.status(200).json({ ok: true, db });
});

// --- Server Start ---
// เปิดพอร์ตก่อน เพื่อให้ Render เห็นว่า service ขึ้นแล้ว
// แล้วรอ DB ใน background; ระหว่างนั้น API ที่โดนยิงจะ retry เอง และถ้าไม่ไหวจะตอบ 500
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});

// รอ DB พร้อมใน background
(async () => {
  try {
    await waitForDbReady({ attempts: 10, firstDelayMs: 800 });
    await loadUsersWithRetry();
  } catch (e) {
    console.error('DB still unavailable after retries (service stays up):', e?.message);
  }
})();

// --- Graceful shutdown ---
function shutdown(sig) {
  console.log(`\n${sig} received, shutting down gracefully...`);
  Promise.allSettled([redisClient?.quit?.(), pgPool.end()]).finally(() =>
    process.exit(0)
  );
}
['SIGINT', 'SIGTERM'].forEach((s) => process.on(s, () => shutdown(s)));
