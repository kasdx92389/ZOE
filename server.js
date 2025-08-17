const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const pgPool = require('./database.js');
const PgSession = require('connect-pg-simple')(session);

const app = express();
const PORT = 3000;

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
            get: async (...params) => {
                const res = await pgPool.query(pgSql, params);
                return res.rows[0];
            },
            all: async (...params) => {
                const res = await pgPool.query(pgSql, params);
                return res.rows;
            },
            run: async (...params) => {
                return await pgPool.query(pgSql, params);
            }
        }
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
        tableName: 'user_sessions'
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

// ... (ส่วนของ Routes อื่นๆ เหมือนเดิมทุกประการ) ...
const requireLogin = (req, res, next) => {
    if (req.session.userId) {
        next();
    } else {
        res.redirect('/');
    }
};

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
    if (userHash && await bcrypt.compare(password, userHash)) {
        req.session.userId = username;
        return res.redirect('/admin/home');
    }
    res.redirect(`/?error=${encodeURIComponent('Username หรือ Password ไม่ถูกต้อง')}`);
});

app.post('/register', async (req, res) => {
    const { username, password, master_code } = req.body;
    if (master_code !== MASTER_CODE) return res.redirect(`/register?error=${encodeURIComponent('รหัสโค้ดลับไม่ถูกต้อง.')}`);
    if (users[username]) return res.redirect(`/register?error=${encodeURIComponent('Username นี้มีผู้ใช้งานแล้ว.')}`);

    const hashedPassword = await bcrypt.hash(password, saltRounds);
    await db.prepare('INSERT INTO users (username, password_hash) VALUES (?, ?)')
        .run(username, hashedPassword);

    await loadUsers();
    res.redirect(`/?success=${encodeURIComponent('สร้างบัญชีสำเร็จ!')}`);
});

app.get('/logout', (req, res) => {
    req.session.destroy(err => {
        if (err) {
            console.error("Error destroying session on logout:", err);
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

app.use('/api', requireLogin);

// --- General Data API ---
app.get('/api/dashboard-data', async (req, res) => {
    try {
        const { game } = req.query;
        let orderedGames = [];
        const config = await db.prepare("SELECT value FROM app_config WHERE key = 'game_order'").get();
        if (config && config.value) {
            orderedGames = JSON.parse(config.value);
        }

        const allDbGames = (await db.prepare("SELECT DISTINCT game_association FROM packages").all()).map(g => g.game_association);

        const cleanedOrderedGames = orderedGames.filter(game => allDbGames.includes(game));
        const newGames = allDbGames.filter(game => !orderedGames.includes(game));
        const finalCorrectOrder = [...cleanedOrderedGames, ...newGames];

        if (JSON.stringify(finalCorrectOrder) !== JSON.stringify(orderedGames)) {
            console.log('Game order has changed. Updating app_config.');
            const value = JSON.stringify(finalCorrectOrder);
            await db.prepare("INSERT INTO app_config (key, value) VALUES ('game_order', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value").run(value);
            orderedGames = finalCorrectOrder;
        }

        let sortedGames = orderedGames;
        const activeGames = (await db.prepare("SELECT DISTINCT game_association FROM packages WHERE is_active = 1").all()).map(g => g.game_association);
        const finalSortedActiveGames = sortedGames.filter(g => activeGames.includes(g));
        
        let query = 'SELECT * FROM packages';
        const params = [];
        if (game) {
            query += ' WHERE game_association = ?';
            params.push(game);
        }
        query += ' ORDER BY sort_order ASC, name ASC';
        const packages = await db.prepare(query).all(...params);
        res.json({ packages, games: finalSortedActiveGames });
    } catch (error) {
        console.error("Error fetching dashboard data:", error);
        res.status(500).json({ error: 'Failed to retrieve dashboard data' });
    }
});

// --- Game Order API ---
app.get('/api/games/order', async (req, res) => {
    try {
        let orderedGames = [];
        const config = await db.prepare("SELECT value FROM app_config WHERE key = 'game_order'").get();
        if (config && config.value) {
            orderedGames = JSON.parse(config.value);
        }
        res.json(orderedGames);
    } catch (error) {
        console.error("Error fetching game order:", error);
        res.status(500).json({ error: 'Failed to retrieve game order' });
    }
});

app.post('/api/games/order', async (req, res) => {
    try {
        const { gameOrder } = req.body;
        if (!Array.isArray(gameOrder)) {
            return res.status(400).json({ error: 'Invalid data format.' });
        }
        const value = JSON.stringify(gameOrder);
        await db.prepare("INSERT INTO app_config (key, value) VALUES ('game_order', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value").run(value);
        res.json({ ok: true });
    } catch (error) {
        console.error("Error saving game order:", error);
        res.status(500).json({ error: 'Failed to save game order' });
    }
});


// --- Packages API ---
app.post('/api/packages', async (req, res) => {
    try {
        const { name, price, product_code, type, channel, game_association } = req.body;
        const result = await db.prepare('INSERT INTO packages (name, price, product_code, type, channel, game_association) VALUES (?, ?, ?, ?, ?, ?) RETURNING id').get(name, price, product_code, type, channel, game_association);
        res.status(201).json({ id: result.id, message: 'Package created' });
    } catch (error) {
        console.error("Error creating package:", error);
        res.status(500).json({ error: 'Failed to create package' });
    }
});

app.put('/api/packages/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, price, product_code, type, channel, game_association, is_active } = req.body;
        const result = await db.prepare('UPDATE packages SET name = ?, price = ?, product_code = ?, type = ?, channel = ?, game_association = ?, is_active = ? WHERE id = ?').run(name, price, product_code, type, channel, game_association, is_active, id);
        if (result.rowCount === 0) return res.status(404).json({ error: 'Package not found' });
        res.json({ id, message: 'Package updated' });
    } catch (error) {
        console.error(`Error updating package ${req.params.id}:`, error);
        res.status(500).json({ error: 'Failed to update package' });
    }
});

app.delete('/api/packages/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.prepare('DELETE FROM packages WHERE id = ?').run(id);
        if (result.rowCount === 0) return res.status(404).json({ error: 'Package not found' });
        res.status(200).json({ message: 'Package deleted' });
    } catch (error) {
        console.error(`Error deleting package ${req.params.id}:`, error);
        res.status(500).json({ error: 'Failed to delete package' });
    }
});

app.post('/api/packages/order', async (req, res) => {
    const { order } = req.body;
    if (!Array.isArray(order)) return res.status(400).json({ error: 'Invalid order data' });
    
    const client = await pgPool.connect();
    try {
        await client.query('BEGIN');
        for (const [index, id] of order.entries()) {
            await client.query('UPDATE packages SET sort_order = $1 WHERE id = $2', [index, id]);
        }
        await client.query('COMMIT');
        res.json({ ok: true, message: 'Package order updated' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Error updating package order:", error);
        res.status(500).json({ error: 'Failed to update package order' });
    } finally {
        client.release();
    }
});

app.post('/api/packages/bulk-actions', async (req, res) => {
    const { action, ids, updates } = req.body;
    if (!action || !Array.isArray(ids) || ids.length === 0) return res.status(400).json({ error: 'Invalid request' });

    const client = await pgPool.connect();
    try {
        await client.query('BEGIN');

        if (action === 'delete') {
            await client.query(`DELETE FROM packages WHERE id = ANY($1::int[])`, [ids]);
        } else if (action === 'updateStatus') {
            await client.query(`UPDATE packages SET is_active = $1 WHERE id = ANY($2::int[])`, [req.body.status, ids]);
        } else if (action === 'bulkEdit' && updates) {
            const setClauses = [];
            const params = [];
            let paramIndex = 1;
            for (const key in updates) {
                setClauses.push(`${key} = $${paramIndex++}`);
                params.push(updates[key]);
            }
            params.push(ids);
            const sql = `UPDATE packages SET ${setClauses.join(', ')} WHERE id = ANY($${paramIndex}::int[])`;
            await client.query(sql, params);
        }
        
        await client.query('COMMIT');
        res.json({ ok: true, message: 'Bulk action successful' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Bulk action error:', error);
        res.status(500).json({ error: 'Failed to perform bulk action' });
    } finally {
        client.release();
    }
});


// --- Orders API ---

function buildOrdersQuery(queryParams) {
    const { q = '', status = '', platform = '', startDate, endDate, page = 1, limit = 20 } = queryParams;
    
    let whereSql = ` FROM orders WHERE 1=1`;
    const params = [];
    let paramIndex = 1;

    if (q) {
        whereSql += ` AND (order_number ILIKE $${paramIndex++} OR customer_name ILIKE $${paramIndex++})`;
        params.push(`%${q}%`, `%${q}%`);
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
    // --- โค้ดที่แก้ไขปัญหา Timezone อย่างถาวร ---
        whereSql += ` AND (order_date AT TIME ZONE 'Asia/Bangkok')::date >= $${paramIndex++}`;
        params.push(startDate);
    }
    if (endDate) {
    // --- โค้ดที่แก้ไขปัญหา Timezone อย่างถาวร ---
        whereSql += ` AND (order_date AT TIME ZONE 'Asia/Bangkok')::date <= $${paramIndex++}`;
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
        const [totalResult, ordersResult] = await Promise.all([
            pgPool.query(countSql, params.slice(0, countSql.match(/\$/g)?.length || 0)),
            pgPool.query(dataSql, params)
        ]);
        const total = parseInt(totalResult.rows[0].total, 10);
        const orders = ordersResult.rows;
        const itemsStmt = 'SELECT * FROM order_items WHERE order_id = $1';
        for (const order of orders) {
            const itemsResult = await pgPool.query(itemsStmt, [order.id]);
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
    const client = await pgPool.connect();
    try {
        await client.query('BEGIN');
        const orderNumber = genOrderNumber();
        const totalPaid = Number(b.total_paid || 0);
        const cost = Number(b.cost || 0);
        const profit = totalPaid - cost;
        const packagesText = b.items?.map(it => `${it.package_name} x${it.quantity}`).join(', ') || '';
        const packageCount = b.items?.reduce((a, c) => a + Number(c.quantity || 0), 0) || 0;

        const orderQuery = `INSERT INTO orders(order_number, order_date, platform, customer_name, game_name, total_paid, payment_proof_url, sales_proof_url, product_code, package_count, packages_text, cost, profit, status, operator, topup_channel, note) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17) RETURNING id`;
        const orderResult = await client.query(orderQuery, [orderNumber, b.order_date, b.platform, b.customer_name, b.game_name, totalPaid, b.payment_proof_url, b.sales_proof_url, b.product_code, packageCount, packagesText, cost, profit, b.status, b.operator, b.topup_channel, b.note]);
        const orderId = orderResult.rows[0].id;
        
        if (Array.isArray(b.items) && b.items.length > 0) {
            const itemQuery = `INSERT INTO order_items(order_id, package_id, package_name, product_code, quantity, unit_price, cost, total_price) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`;
            for (const it of b.items) {
                const qty = Number(it.quantity || 1);
                const unit = Number(it.unit_price || 0);
                await client.query(itemQuery, [orderId, it.package_id, it.package_name, it.product_code, qty, unit, it.cost || 0, qty * unit]);
            }
        }
        await client.query('COMMIT');
        res.status(201).json({ id: orderId, order_number: orderNumber });
    } catch (e) {
        await client.query('ROLLBACK');
        console.error('Create order error', e);
        res.status(500).json({ error: 'Failed to create order' });
    } finally {
        client.release();
    }
});

app.put('/api/orders/:orderNumber', async (req, res) => {
    const { orderNumber } = req.params;
    const b = req.body;
    const client = await pgPool.connect();
    try {
        await client.query('BEGIN');
        const orderResult = await client.query('SELECT id FROM orders WHERE order_number = $1', [orderNumber]);
        if (orderResult.rows.length === 0) throw new Error('OrderNotFound');
        
        const numericId = orderResult.rows[0].id;
        const totalPaid = Number(b.total_paid || 0);
        const cost = Number(b.cost || 0);
        const profit = totalPaid - cost;
        const packagesText = b.items?.map(it => `${it.package_name} x${it.quantity}`).join(', ') || '';
        const packageCount = b.items?.reduce((a, c) => a + Number(c.quantity || 0), 0) || 0;

        await client.query(`UPDATE orders SET order_date=$1, platform=$2, customer_name=$3, game_name=$4, total_paid=$5, payment_proof_url=$6, sales_proof_url=$7, product_code=$8, package_count=$9, packages_text=$10, cost=$11, profit=$12, status=$13, operator=$14, topup_channel=$15, note=$16 WHERE id=$17`, [b.order_date, b.platform, b.customer_name, b.game_name, totalPaid, b.payment_proof_url, b.sales_proof_url, b.product_code, packageCount, packagesText, cost, profit, b.status, b.operator, b.topup_channel, b.note, numericId]);
        
        await client.query('DELETE FROM order_items WHERE order_id = $1', [numericId]);
        if (Array.isArray(b.items) && b.items.length > 0) {
            const itemQuery = `INSERT INTO order_items(order_id, package_id, package_name, product_code, quantity, unit_price, cost, total_price) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`;
            for (const newItem of b.items) {
                const qty = Number(newItem.quantity || 1);
                const unit = Number(newItem.unit_price || 0);
                await client.query(itemQuery, [numericId, newItem.package_id, newItem.package_name, newItem.product_code, qty, unit, newItem.cost || 0, qty * unit]);
            }
        }
        await client.query('COMMIT');
        res.json({ ok: true, order_number: orderNumber });
    } catch (e) {
        await client.query('ROLLBACK');
        console.error(`Update order error for ${orderNumber}:`, e);
        if (e.message === 'OrderNotFound') return res.status(404).json({ error: 'Order not found' });
        res.status(500).json({ error: 'Failed to update order' });
    } finally {
        client.release();
    }
});

app.delete('/api/orders/:orderNumber', async (req, res) => {
    const { orderNumber } = req.params;
    try {
        const result = await db.prepare('DELETE FROM orders WHERE order_number = ?').run(orderNumber);
        if (result.rowCount === 0) return res.status(404).json({ error: 'Order not found, nothing to delete.' });
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
        
        const ordersResult = await pgPool.query(dataSql, params);
        const orders = ordersResult.rows;

        if (orders.length === 0) {
            return res.status(404).send('ไม่มีรายการในออเดอร์ที่เลือก');
        }

        const thaiHeaders = [
            'เลขออเดอร์', 'วันที่ทำรายการ', 'ยอดจ่าย', 'หลักฐานโอนเงิน (URL)', 'แพลตฟอร์ม',
            'ชื่อลูกค้า', 'เกม', 'รายการแพ็กเกจ', 'ต้นทุน', 'กำไร',
            'สถานะ', 'หลักฐานปิดการขาย (URL)', 'ผู้ทำรายการ', 'ช่องทางการเติม', 'หมายเหตุ'
        ];

        const dbColumns = [
            'order_number', 'order_date', 'total_paid', 'payment_proof_url', 'platform',
            'customer_name', 'game_name', 'packages_text', 'cost', 'profit',
            'status', 'sales_proof_url', 'operator', 'topup_channel', 'note'
        ];

        let csv = '\ufeff' + thaiHeaders.join(',') + '\n';

        // --- โค้ดส่วนที่คุณส่งมา ---
        for (const order of orders) {
            const row = dbColumns.map(header => {
                let value = order[header]; 

                if (header === 'order_date' && value) {
                    const date = new Date(value);
                    value = date.toLocaleString('en-GB', { timeZone: 'Asia/Bangkok' });
                } else {
                    value = value === null || value === undefined ? '' : String(value);
                }

                if (String(value).includes(',') || String(value).includes('"') || String(value).includes('\n')) {
                    value = `"${String(value).replace(/"/g, '""')}"`;
                }
                return value;
            });
            csv += row.join(',') + '\n';
        }
        // --------------------------

        const fileName = `orders-export-${new Date().toISOString().slice(0, 10)}.csv`;
        res.setHeader('Content-Type', 'text/csv; charset=utf-8');
        res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);

        res.status(200).end(csv);

    } catch (error) {
        console.error('Failed to export orders:', error);
        res.status(500).send('Failed to export orders.');
    }
});


// --- Server Start ---
app.listen(PORT, () => console.log(`Server is running at http://localhost:${PORT}`));