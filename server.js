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

// ✨ FIX STEP 1: เริ่มต้นระบบ Session ก่อนเป็นอันดับแรกเสมอ
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

// ✨ FIX STEP 2: สร้าง Middleware ตรวจสอบการล็อกอิน
const requireLogin = (req, res, next) => {
    if (req.session.userId) {
        next(); // ถ้าล็อกอินแล้ว ให้ไปต่อ
    } else {
        res.redirect('/'); // ถ้ายังไม่ล็อกอิน ให้กลับไปหน้าแรก
    }
};

// --- Public & Auth Routes (กำหนดเส้นทางทั้งหมดก่อน Static Files) ---
app.get('/', (req, res) => {
    if (req.session.userId) {
        res.redirect('/admin/dashboard');
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
        return res.redirect('/admin/dashboard');
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

// --- Admin Routes (Protected by requireLogin) ---
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

// --- API Endpoints (Protected by requireLogin) ---
// ... (All API routes will be implicitly protected because they come before express.static)
app.use('/api', requireLogin); // ⭐️ ปกป้อง API ทุกเส้นทางด้วยบรรทัดนี้

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

// ... (The rest of API routes do not need 'requireLogin' individually anymore)
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
        if (!existingPackage) {
            return res.status(404).json({ error: 'Package not found' });
        }
        const dataToUpdate = { ...existingPackage, ...req.body };
        const price = parseFloat(dataToUpdate.price);
        if (isNaN(price)) {
            return res.status(400).json({ error: 'Invalid input: Price must be a valid number.' });
        }
        dataToUpdate.price = price;
        if (!dataToUpdate.name || !dataToUpdate.type || !dataToUpdate.channel || !dataToUpdate.game_association) {
            return res.status(400).json({ error: 'Invalid input: Name, Type, Channel, and Game cannot be empty.' });
        }
        const { name, product_code, type, channel, game_association, is_active } = dataToUpdate;
        const updateStmt = db.prepare(`
            UPDATE packages 
            SET name = ?, price = ?, product_code = ?, type = ?, channel = ?, game_association = ?, is_active = ? 
            WHERE id = ?
        `);
        updateStmt.run(name, price, product_code, type, channel, game_association, is_active, id);
        res.json({ message: 'Package updated successfully' });
    } catch (error) {
        console.error("Error updating package:", error);
        res.status(500).json({ error: 'Failed to update package' });
    }
});

app.delete('/api/packages/:id', (req, res) => {
    try {
        const stmt = db.prepare('DELETE FROM packages WHERE id = ?');
        const info = stmt.run(req.params.id);
        if (info.changes === 0) {
            return res.status(404).json({ error: 'Package not found, nothing to delete.' });
        }
        res.json({ message: 'Package deleted successfully' });
    } catch (error) {
        console.error("Error deleting package:", error);
        let errorMessage = 'Failed to delete package.';
        if (error.code === 'SQLITE_CONSTRAINT') {
            errorMessage = 'Cannot delete: This package is linked to other data.';
        }
        res.status(500).json({ error: errorMessage });
    }
});

app.post('/api/packages/bulk-actions', (req, res) => {
    const { action, ids, status, priceUpdates, nameUpdates, codeUpdates, updates } = req.body;
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
                const priceUpdateStmt = db.prepare('UPDATE packages SET price = ? WHERE id = ?');
                for (const update of priceUpdates) {
                    priceUpdateStmt.run(update.newPrice, update.id);
                }
                return { message: `${priceUpdates.length} package prices updated.` };
            case 'setIndividualNames':
                if (!Array.isArray(nameUpdates)) throw new Error('Invalid name update data');
                const nameUpdateStmt = db.prepare('UPDATE packages SET name = ? WHERE id = ?');
                for (const update of nameUpdates) {
                    nameUpdateStmt.run(update.newName, update.id);
                }
                return { message: `${nameUpdates.length} package names updated.` };
            case 'setIndividualCodes':
                if (!Array.isArray(codeUpdates)) throw new Error('Invalid code update data');
                const codeUpdateStmt = db.prepare('UPDATE packages SET product_code = ? WHERE id = ?');
                for (const update of codeUpdates) {
                    codeUpdateStmt.run(update.newCode, update.id);
                }
                return { message: `${codeUpdates.length} package codes updated.` };
            case 'bulkEdit':
                if (typeof updates !== 'object' || updates === null || Object.keys(updates).length === 0) {
                    throw new Error('Invalid update data provided for bulk edit.');
                }
                const allowedFields = ['price', 'type', 'channel', 'game_association'];
                const fieldsToUpdate = Object.keys(updates).filter(key => allowedFields.includes(key));
                if (fieldsToUpdate.length === 0) {
                    throw new Error('No valid fields to update in bulk edit.');
                }
                const setClauses = fieldsToUpdate.map(key => `${key} = ?`).join(', ');
                const values = fieldsToUpdate.map(key => updates[key]);
                const bulkUpdateStmt = db.prepare(`UPDATE packages SET ${setClauses} WHERE id IN (${placeholders})`);
                bulkUpdateStmt.run(...values, ...ids);
                return { message: `${ids.length} packages have been updated.` };
            default:
                throw new Error('Invalid action');
        }
    });
    try {
        const result = runInTransaction();
        res.json(result);
    } catch (error) {
        console.error('Bulk action error:', error);
        let errorMessage = 'Failed to perform bulk action.';
        if (error.code === 'SQLITE_CONSTRAINT') {
            errorMessage = 'Cannot delete: One or more packages are linked to other data.';
        }
        res.status(500).json({ error: errorMessage });
    }
});

app.get('/api/games/order', (req, res) => {
    let orderedGames = [];
    try {
        if (fs.existsSync(GAME_ORDER_FILE_PATH)) {
            orderedGames = JSON.parse(fs.readFileSync(GAME_ORDER_FILE_PATH, 'utf8'));
        }
    } catch (e) { /* Ignore parsing errors */ }
    const allDbGames = db.prepare("SELECT DISTINCT game_association FROM packages").all().map(g => g.game_association);
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

// ✨ FIX STEP 3: ให้ static file serving ทำงานหลังจากที่กำหนด Route ทั้งหมดแล้ว
// จะให้บริการไฟล์เช่น CSS, JS, และไฟล์ public อื่นๆ ที่ไม่มีใน Route ด้านบน
app.use(express.static(path.join(__dirname, 'public')));


app.listen(PORT, () => console.log(`Server is running at http://localhost:${PORT}`));