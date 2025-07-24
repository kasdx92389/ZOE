const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const fs = require('fs');

const db = require('./database.js'); 
const app = express();
app.use(express.json()); 

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
app.use(express.static(path.join(__dirname, 'public')));
app.use(session({
    secret: 'a-very-secret-key-for-your-session-12345',
    resave: false,
    saveUninitialized: false,
    cookie: { 
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

// --- Auth Routes ---
app.get('/', (req, res) => { res.sendFile(path.join(__dirname, 'admin-login.html')); });
app.get('/register', (req, res) => { res.sendFile(path.join(__dirname, 'admin-register.html')); });
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    const userHash = users[username];
    if (userHash && await bcrypt.compare(password, userHash)) {
        req.session.userId = username;
        req.session.cookie.maxAge = 30 * 24 * 60 * 60 * 1000;
        return res.redirect('/admin/homepage');
    }
    res.redirect(`/?error=${encodeURIComponent('Username หรือ Password ไม่ถูกต้อง')}`);
});
app.post('/register', async (req, res) => {
    const { username, password, master_code } = req.body;
    if (master_code !== MASTER_CODE) return res.redirect(`/register?error=${encodeURIComponent('รหัสโค้ดลับไม่ถูกต้อง.')}`);
    if (users[username]) return res.redirect(`/register?error=${encodeURIComponent('Username นี้มีผู้ใช้งานแล้ว.')}`);
    users[username] = await bcrypt.hash(password, saltRounds);
    fs.writeFileSync(USERS_FILE_PATH, JSON.stringify(users, null, 2));
    res.redirect(`/?success=${encodeURIComponent('สร้างบัญชีสำเร็จ! กรุณาล็อกอิน')}`);
});
app.get('/logout', (req, res) => { req.session.destroy(() => res.redirect('/')); });

// --- Public Routes ---
app.get('/terms', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'terms.html'));
});

// --- API Endpoints ---
app.get('/api/packages', (req, res) => {
    try {
        const stmt = db.prepare('SELECT * FROM packages ORDER BY game_association, sort_order');
        const packages = stmt.all();
        res.json(packages);
    } catch (error) {
        res.status(500).json({ error: 'Failed to retrieve packages' });
    }
});

app.post('/api/packages', (req, res) => {
    const { name, price, product_code, type, channel, game_association, originalId } = req.body;
    const transaction = db.transaction(() => {
        let newSortOrder;
        if (originalId) {
            const originalOrderStmt = db.prepare('SELECT sort_order FROM packages WHERE id = ?');
            const originalPackage = originalOrderStmt.get(originalId);
            if (!originalPackage) throw new Error('Original package for cloning not found');
            const originalSortOrder = originalPackage.sort_order;
            const shiftStmt = db.prepare('UPDATE packages SET sort_order = sort_order + 1 WHERE sort_order > ?');
            shiftStmt.run(originalSortOrder);
            newSortOrder = originalSortOrder + 1;
        } else {
            const maxSortOrderStmt = db.prepare('SELECT MAX(sort_order) as max_order FROM packages');
            const result = maxSortOrderStmt.get();
            newSortOrder = (result.max_order === null ? -1 : result.max_order) + 1;
        }
        const insertStmt = db.prepare(`
            INSERT INTO packages (name, price, product_code, type, channel, game_association, sort_order) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `);
        const info = insertStmt.run(name, price, product_code, type, channel, game_association, newSortOrder);
        return { id: info.lastInsertRowid };
    });
    try {
        const result = transaction();
        res.status(201).json(result);
    } catch (error) {
        console.error("Failed to create package:", error);
        res.status(500).json({ error: 'Failed to create package', details: error.message });
    }
});

app.post('/api/packages/order', (req, res) => {
    const { order } = req.body;
    if (!Array.isArray(order)) return res.status(400).json({ error: 'Invalid order data' });
    const updateStmt = db.prepare('UPDATE packages SET sort_order = ? WHERE id = ?');
    const updateTransaction = db.transaction((packages) => {
        for (const pkg of packages) updateStmt.run(pkg.sort_order, pkg.id);
    });
    try {
        const packagesToUpdate = order.map((id, index) => ({ id: id, sort_order: index }));
        updateTransaction(packagesToUpdate);
        res.json({ message: 'Order updated successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update order' });
    }
});

app.put('/api/packages/:id', (req, res) => {
    try {
        const { id } = req.params;
        const getStmt = db.prepare('SELECT * FROM packages WHERE id = ?');
        const existingPackage = getStmt.get(id);
        if (!existingPackage) return res.status(404).json({ error: 'Package not found' });
        
        const updatedPackage = { ...existingPackage, ...req.body };
        const { name, price, product_code, type, channel, game_association, is_active } = updatedPackage;
        
        const updateStmt = db.prepare(`
            UPDATE packages 
            SET name = ?, price = ?, product_code = ?, type = ?, channel = ?, game_association = ?, is_active = ? 
            WHERE id = ?
        `);
        updateStmt.run(name, price, product_code, type, channel, game_association, is_active, id);
        res.json({ message: 'Package updated successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update package' });
    }
});

app.delete('/api/packages/:id', (req, res) => {
    try {
        const stmt = db.prepare('DELETE FROM packages WHERE id = ?');
        stmt.run(req.params.id);
        res.json({ message: 'Package deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete package' });
    }
});

app.post('/api/packages/bulk-actions', (req, res) => {
    const { action, ids, status, priceUpdates } = req.body;
    if (!action || !Array.isArray(ids) || ids.length === 0) {
        return res.status(400).json({ error: 'Invalid request' });
    }

    const runInTransaction = db.transaction(() => {
        const placeholders = ids.map(() => '?').join(',');
        switch (action) {
            case 'delete':
                db.prepare(`DELETE FROM packages WHERE id IN (${placeholders})`).run(...ids);
                return { message: `${ids.length} packages deleted.` };
            case 'updateStatus':
                if (typeof status !== 'number') throw new Error('Invalid status');
                db.prepare(`UPDATE packages SET is_active = ? WHERE id IN (${placeholders})`).run(status, ...ids);
                return { message: `${ids.length} packages updated.` };
            case 'setIndividualPrices':
                if (!Array.isArray(priceUpdates)) throw new Error('Invalid price update data');
                const updateStmt = db.prepare('UPDATE packages SET price = ? WHERE id = ?');
                for (const update of priceUpdates) {
                    updateStmt.run(update.newPrice, update.id);
                }
                return { message: `${priceUpdates.length} package prices updated.` };
            default:
                throw new Error('Invalid action');
        }
    });

    try {
        const result = runInTransaction();
        res.json(result);
    } catch (error) {
        console.error('Bulk action error:', error);
        res.status(500).json({ error: 'Failed to perform bulk action', details: error.message });
    }
});


// --- GAME ORDERING APIs ---
app.get('/api/games/order', (req, res) => {
    let orderedGames = [];
    try {
        if (fs.existsSync(GAME_ORDER_FILE_PATH)) {
            orderedGames = JSON.parse(fs.readFileSync(GAME_ORDER_FILE_PATH, 'utf8'));
        }
    } catch (e) { /* Ignore parsing errors, will be overwritten */ }

    const allDbGames = db.prepare("SELECT DISTINCT game_association FROM packages WHERE is_active = 1").all().map(g => g.game_association);
    const newGames = allDbGames.filter(g => !orderedGames.includes(g)).sort();
    
    const finalGameOrder = [...orderedGames, ...newGames];
    res.json(finalGameOrder);
});

app.post('/api/games/order', (req, res) => {
    try {
        const { gameOrder } = req.body;
        if (!Array.isArray(gameOrder)) {
            return res.status(400).json({ error: 'Invalid data format' });
        }
        fs.writeFileSync(GAME_ORDER_FILE_PATH, JSON.stringify(gameOrder, null, 2));
        res.json({ message: 'Game order saved successfully.' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to save game order.' });
    }
});


// ===== CORE CHANGE HERE =====
app.get('/api/dashboard-data', (req, res) => {
    try {
        // Fetch packages and explicitly order them by their sort_order
        const packagesStmt = db.prepare('SELECT * FROM packages WHERE is_active = 1 ORDER BY sort_order');
        const packages = packagesStmt.all();

        let gameOrder = [];
        try {
            if (fs.existsSync(GAME_ORDER_FILE_PATH)) {
                gameOrder = JSON.parse(fs.readFileSync(GAME_ORDER_FILE_PATH, 'utf8'));
            }
        } catch (e) { /* ignore */ }

        const allGamesSet = new Set(packages.map(p => p.game_association));

        const sortedGames = Array.from(allGamesSet).sort((a, b) => {
            const indexA = gameOrder.indexOf(a);
            const indexB = gameOrder.indexOf(b);

            if (indexA === -1 && indexB === -1) return a.localeCompare(b);
            if (indexA === -1) return 1;
            if (indexB === -1) return -1;
            return indexA - indexB;
        });
        
        res.json({ packages, games: sortedGames });
    } catch (error) {
        res.status(500).json({ error: 'Failed to retrieve dashboard data' });
    }
});
// ============================


// --- Admin Routes ---
app.get('/admin/homepage', requireLogin, (req, res) => { res.sendFile(path.join(__dirname, 'public', 'homepage.html')); });
app.get('/admin/dashboard', requireLogin, (req, res) => { res.sendFile(path.join(__dirname, 'public', 'admin-dashboard.html')); });
app.get('/admin/packages', requireLogin, (req, res) => { res.sendFile(path.join(__dirname, 'public', 'package-management.html')); });

app.listen(PORT, () => console.log(`Server is running at http://localhost:${PORT}`));