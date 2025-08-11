const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const fs = require('fs');

const FileStore = require('session-file-store')(session);

const db = require('./database.js'); 
const app = express();

const PORT = 3000;

// --- File Paths ---
const USERS_FILE_PATH = path.join(__dirname, 'users.json');
const GAME_ORDER_FILE_PATH = path.join(__dirname, 'game_order.json');

// --- ค่าคงที่ ---
const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;

// --- ระบบจัดเก็บข้อมูลผู้ใช้ (อ่านจากไฟล์) ---
let users = {};
try {
    const data = fs.readFileSync(USERS_FILE_PATH, 'utf8');
    users = JSON.parse(data);
} catch (error) {
    console.log('users.json not found or is invalid. Creating a new one...');
    const defaultAdminPassword = 'DgGUxU4N';
    const hashedDefaultPassword = bcrypt.hashSync(defaultAdminPassword, saltRounds);
    users = { 'admin': hashedDefaultPassword };
    fs.writeFileSync(USERS_FILE_PATH, JSON.stringify(users, null, 2));
}

// --- Middleware ---
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.use(session({
    store: new FileStore({
        path: './sessions',
        logFn: function() {}
    }),
    secret: 'a-very-secret-key-for-your-session-12345',
    resave: false,
    saveUninitialized: false,
    cookie: { 
        maxAge: 30 * 24 * 60 * 60 * 1000,
        secure: false, 
        httpOnly: true 
    }
}));

const requireLogin = (req, res, next) => {
    if (req.session.userId) {
        next();
    } else {
        res.redirect('/');
    }
};

// --- Public & Auth Routes ---
app.get('/', (req, res) => {
    if (req.session.userId) {
        res.redirect('/admin/home'); // <-- เปลี่ยนเป็น /admin/home
    } else {
        res.sendFile(path.join(__dirname, 'public', 'admin-login.html'));
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
        return res.redirect('/admin/home'); // <-- เปลี่ยนเป็น /admin/home
    }
    res.redirect(`/?error=${encodeURIComponent('Username หรือ Password ไม่ถูกต้อง')}`);
});

app.post('/register', async (req, res) => {
    const { username, password, master_code } = req.body;
    if (master_code !== MASTER_CODE) return res.redirect(`/register?error=${encodeURIComponent('รหัสโค้ดลับไม่ถูกต้อง.')}`);
    if (users[username]) return res.redirect(`/register?error=${encodeURIComponent('Username นี้มีผู้ใช้งานแล้ว.')}`);
    users[username] = await bcrypt.hash(password, saltRounds);
    fs.writeFileSync(USERS_FILE_PATH, JSON.stringify(users, null, 2));
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

// --- Admin Routes ---
app.get('/admin/home', requireLogin, (req, res) => { // ++ เพิ่ม Route สำหรับ Homepage ++
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

// --- API Endpoints ---
app.use('/api', requireLogin);

// (Package and Game API endpoints remain the same as your provided file)
app.get('/api/dashboard-data', (req, res) => {
    try {
        const { game } = req.query;
        let orderedGames = [];
        try {
            if (fs.existsSync(GAME_ORDER_FILE_PATH)) {
                orderedGames = JSON.parse(fs.readFileSync(GAME_ORDER_FILE_PATH, 'utf8'));
            }
        } catch (e) { /* ignore */ }
        const allDbGames = db.prepare("SELECT DISTINCT game_association FROM packages").all().map(g => g.game_association);
        const newGames = allDbGames.filter(g => !orderedGames.includes(g)).sort();
        let sortedGames = [...orderedGames, ...newGames];
        const activeGames = db.prepare("SELECT DISTINCT game_association FROM packages WHERE is_active = 1").all().map(g => g.game_association);
        const finalSortedActiveGames = sortedGames.filter(g => activeGames.includes(g));
        let query = 'SELECT * FROM packages';
        const params = [];
        if (game) {
            query += ' WHERE game_association = ?';
            params.push(game);
        }
        query += ' ORDER BY sort_order';
        const packagesStmt = db.prepare(query);
        const packages = packagesStmt.all(...params);
        res.json({ packages, games: finalSortedActiveGames });
    } catch (error) {
        console.error("Error fetching dashboard data:", error);
        res.status(500).json({ error: 'Failed to retrieve dashboard data' });
    }
});


// ================== Orders Management ==================
// --- API for Games Dashboard ---
app.get('/api/games/order', (req, res) => {
    try {
        let orderedGames = [];
        // ตรวจสอบว่ามีไฟล์จัดลำดับเกมอยู่หรือไม่
        if (fs.existsSync(GAME_ORDER_FILE_PATH)) {
            orderedGames = JSON.parse(fs.readFileSync(GAME_ORDER_FILE_PATH, 'utf8'));
        }
        
        // ดึงรายชื่อเกมทั้งหมดที่มีในฐานข้อมูล
        const allDbGames = db.prepare("SELECT DISTINCT game_association FROM packages").all().map(g => g.game_association);
        
        // หาเกมใหม่ที่ยังไม่มีในไฟล์จัดลำดับ แล้วเรียงตามตัวอักษร
        const newGames = allDbGames.filter(g => !orderedGames.includes(g)).sort();
        
        // รวมรายชื่อเกมที่จัดลำดับแล้วกับเกมใหม่
        const finalSortedGames = [...orderedGames, ...newGames];
        
        res.json(finalSortedGames);
    } catch (error) {
        console.error("Error fetching game order:", error);
        res.status(500).json({ error: 'Failed to retrieve game order' });
    }
});

function genOrderNumber() {
    const d = new Date();
    const y = d.getFullYear();
    const m = String(d.getMonth()+1).padStart(2,'0');
    const day = String(d.getDate()).padStart(2,'0');
    const seq = Math.floor(Math.random()*9000)+1000;
    return `ODR-${y}${m}${day}-${seq}`;
}

app.get('/api/orders', (req,res)=>{
    const { q = '', status = '', platform = '', limit = 200 } = req.query;
    const like = `%${q}%`;
    let sql = `SELECT * FROM orders WHERE 1=1`;
    const params = [];
    if (q) { 
        sql += ` AND (order_number LIKE ? OR customer_name LIKE ? OR game_name LIKE ? OR product_code LIKE ?)`; 
        params.push(like, like, like, like); 
    }
    if (status) { sql += ` AND status = ?`; params.push(status); }
    if (platform) { sql += ` AND platform = ?`; params.push(platform); }
    sql += ` ORDER BY created_at DESC LIMIT ?`; params.push(Number(limit));

    try {
        // 1. ดึงข้อมูลออเดอร์หลัก
        const orders = db.prepare(sql).all(...params);
        const itemsStmt = db.prepare('SELECT * FROM order_items WHERE order_id = ?');

        // 2. สำหรับแต่ละออเดอร์ ให้ดึงรายการแพ็กเกจ (items) มาใส่เพิ่มเข้าไป
        for (const order of orders) {
            order.items = itemsStmt.all(order.id);
        }

        // 3. ส่งข้อมูลออเดอร์ที่สมบูรณ์ (มี items) กลับไป
        res.json({ orders: orders });
        
    } catch (e) {
        console.error('Orders list error', e);
        res.status(500).json({ error: 'Failed to load orders' });
    }
});

app.post('/api/orders', (req,res)=>{
    const b = req.body || {};
    
    const createOrderTx = db.transaction(() => {
        const orderNumber = genOrderNumber();
        const orderDate = b.order_date || new Date().toISOString().slice(0,10);
        const totalPaid = Number(b.total_paid||0);
        const cost = Number(b.cost||0);
        const profit = totalPaid - cost;
        const packagesText = Array.isArray(b.items) && b.items.length ? b.items.map(it=>`${it.package_name} x${it.quantity}`).join(', ') : '';
        const packageCount = Array.isArray(b.items) ? b.items.reduce((a,c)=>a+Number(c.quantity||0),0) : 0;

        const info = db.prepare(`INSERT INTO orders(
            order_number, order_date, platform, customer_name, game_name,
            total_paid, payment_proof_url, sales_proof_url, product_code, package_count,
            packages_text, cost, profit, status, operator, topup_channel, note
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`).run(
            orderNumber, orderDate, b.platform||'', b.customer_name||'', b.game_name||'',
            totalPaid, b.payment_proof_url||'', b.sales_proof_url||'', b.product_code||'', packageCount,
            packagesText, cost, profit, b.status||'รอดำเนินการ', b.operator||'', b.topup_channel||'', b.note||''
        );
        const orderId = info.lastInsertRowid;

        if (Array.isArray(b.items) && b.items.length > 0) {
            const stmt = db.prepare(`INSERT INTO order_items(order_id, package_id, package_name, product_code, quantity, unit_price, cost, total_price) VALUES (?,?,?,?,?,?,?,?)`);
            for (const it of b.items) {
                const qty = Number(it.quantity||1);
                const unit = Number(it.unit_price||0);
                const costIt = Number(it.cost||0);
                stmt.run(orderId, it.package_id||null, it.package_name||'', it.product_code||'', qty, unit, costIt, qty*unit);
            }
        }
        return { id: orderId, order_number: orderNumber };
    });

    try {
        const result = createOrderTx();
        res.status(201).json(result);
    } catch (e) {
        console.error('Create order error', e);
        res.status(500).json({ error: 'Failed to create order' });
    }
});

app.put('/api/orders/:orderNumber', (req,res)=>{
    const { orderNumber } = req.params;
    const b = req.body || {};
    
    // Recalculate summary fields on every update
    const totalPaid = Number(b.total_paid||0);
    const cost = Number(b.cost||0);
    const profit = totalPaid - cost;
    const packagesText = Array.isArray(b.items) && b.items.length ? b.items.map(it=>`${it.package_name} x${it.quantity}`).join(', ') : '';
    const packageCount = Array.isArray(b.items) ? b.items.reduce((a,c)=>a+Number(c.quantity||0),0) : 0;

    const updateTransaction = db.transaction(() => {
        const order = db.prepare('SELECT id FROM orders WHERE order_number = ?').get(orderNumber);
        if (!order) {
            throw new Error('OrderNotFound');
        }
        const numericId = order.id;

        db.prepare(`UPDATE orders SET
            order_date=?, platform=?, customer_name=?, game_name=?, total_paid=?,
            payment_proof_url=?, sales_proof_url=?, product_code=?, package_count=?, packages_text=?,
            cost=?, profit=?, status=?, operator=?, topup_channel=?, note=?
            WHERE id=?`).run(
                b.order_date, b.platform, b.customer_name, b.game_name, totalPaid,
                b.payment_proof_url, b.sales_proof_url, b.product_code, packageCount, packagesText,
                cost, profit, b.status, b.operator, b.topup_channel, b.note, numericId
        );

        // --- Start of intelligent item update logic ---

        // 1. Fetch existing items from the database
        const existingItems = db.prepare('SELECT id, package_id, quantity, unit_price FROM order_items WHERE order_id = ?').all(numericId);
        const existingItemsMap = new Map(existingItems.map(item => [item.package_id, item]));
        
        // 2. Get new items from the request and prepare DB statements
        const newItems = b.items || [];
        const newItemsPackageIds = new Set(newItems.map(item => item.package_id));
        const insertStmt = db.prepare(`INSERT INTO order_items(order_id, package_id, package_name, product_code, quantity, unit_price, cost, total_price) VALUES (?,?,?,?,?,?,?,?)`);
        const updateStmt = db.prepare(`UPDATE order_items SET quantity = ?, unit_price = ?, total_price = ? WHERE id = ?`);

        // 3. Loop to find items to delete (in DB but not in new request)
        const idsToDelete = [];
        for (const existingItem of existingItems) {
            if (!newItemsPackageIds.has(existingItem.package_id)) {
                idsToDelete.push(existingItem.id);
            }
        }
        if (idsToDelete.length > 0) {
            const deletePlaceholders = idsToDelete.map(() => '?').join(',');
            db.prepare(`DELETE FROM order_items WHERE id IN (${deletePlaceholders})`).run(...idsToDelete);
        }

        // 4. Loop through new items to either INSERT or UPDATE
        for (const newItem of newItems) {
            const existingItem = existingItemsMap.get(newItem.package_id);
            const qty = Number(newItem.quantity || 1);
            const unit = Number(newItem.unit_price || 0);
            const costIt = Number(newItem.cost || 0);
            const totalPrice = qty * unit;

            if (existingItem) {
                // It exists, so UPDATE (but only if changed)
                if (existingItem.quantity !== qty || existingItem.unit_price !== unit) {
                    updateStmt.run(qty, unit, totalPrice, existingItem.id);
                }
            } else {
                // It's new, so INSERT
                insertStmt.run(numericId, newItem.package_id || null, newItem.package_name || '', newItem.product_code || '', qty, unit, costIt, totalPrice);
            }
        }
        
        // --- End of intelligent item update logic ---

        return { order_number: orderNumber };
    });

    try {
        const result = updateTransaction();
        res.json({ ok: true, order_number: result.order_number });
    } catch (e) {
        console.error(`Update order error for ${orderNumber}:`, e);
        if (e.message === 'OrderNotFound') {
            return res.status(404).json({ error: 'Order not found' });
        }
        res.status(500).json({ error: 'Failed to update order' });
    }
});

app.delete('/api/orders/:orderNumber', (req, res) => {
    const deleteOrderTransaction = db.transaction((numericId) => {
        db.prepare('DELETE FROM order_items WHERE order_id = ?').run(numericId);
        const info = db.prepare('DELETE FROM orders WHERE id = ?').run(numericId);
        return info;
    });

    try {
        const { orderNumber } = req.params;
        const order = db.prepare('SELECT id FROM orders WHERE order_number = ?').get(orderNumber);

        if (!order) {
            return res.status(404).json({ error: 'Order not found, nothing to delete.' });
        }

        const numericId = order.id;
        deleteOrderTransaction(numericId);

        res.json({ ok: true, message: `Order ${orderNumber} and its items were deleted.` });

    } catch (e) {
        console.error(`Delete order error for ${req.params.orderNumber}:`, e);
        res.status(500).json({ error: 'Failed to delete order' });
    }
});

app.get('/api/orders/export/csv', (req,res)=>{
    try {
        const rows = db.prepare('SELECT * FROM orders ORDER BY created_at DESC').all();
        const headers = [
            'order_number','order_date','platform','customer_name','game_name','product_code','package_count','packages_text',
            'total_paid','cost','profit','payment_proof_url','sales_proof_url','operator','topup_channel','status','note'
        ];
        const esc = v => '"' + String(v ?? '').replace(/"/g,'""') + '"';
        const body = rows.map(r => headers.map(h => esc(r[h])).join(',')).join('\n');
        const csv = '\ufeff' + headers.join(',') + '\n' + body;
        res.setHeader('Content-Type','text/csv; charset=utf-8');
        res.setHeader('Content-Disposition','attachment; filename="orders_export.csv"');
        res.send(csv);
    } catch (e) {
        console.error('Export csv error', e);
        res.status(500).json({ error: 'Failed to export CSV' });
    }
});
// ================== /Orders Management ==================
app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => console.log(`Server is running at http://localhost:${PORT}`));