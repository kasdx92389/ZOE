const sqlite3 = require('better-sqlite3');
const path = require('path');
const db = new sqlite3(path.join(__dirname, 'main.db'), { fileMustExist: false });

// สร้างตาราง packages หากยังไม่มี
const createTableStmt = `
CREATE TABLE IF NOT EXISTS packages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    product_code TEXT,
    type TEXT NOT NULL,
    channel TEXT NOT NULL,
    game_association TEXT NOT NULL,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
`;
db.exec(createTableStmt);

// --- ADD sort_order column if it doesn't exist ---
try {
    const columns = db.prepare(`PRAGMA table_info(packages)`).all();
    const hasSortOrder = columns.some(col => col.name === 'sort_order');
    if (!hasSortOrder) {
        db.exec('ALTER TABLE packages ADD COLUMN sort_order INTEGER DEFAULT 0');
        console.log("'sort_order' column added to 'packages' table.");
    }
} catch (error) {
    console.error("Error checking/adding sort_order column:", error);
}

console.log("Database is ready.");
module.exports = db;
// ===== Orders tables (NEW) =====
try {
    db.pragma('foreign_keys = ON');
    db.exec(`
    CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT UNIQUE NOT NULL,
        order_date TEXT NOT NULL,
        platform TEXT,
        customer_name TEXT,
        game_name TEXT,
        total_paid REAL NOT NULL DEFAULT 0,
        payment_proof_url TEXT,
        sales_proof_url TEXT,
        product_code TEXT,
        package_count INTEGER NOT NULL DEFAULT 0,
        packages_text TEXT,
        cost REAL NOT NULL DEFAULT 0,
        profit REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'รอดำเนินการ',
        operator TEXT,
        topup_channel TEXT,
        note TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        package_id INTEGER,
        package_name TEXT,
        product_code TEXT,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL DEFAULT 0,
        cost REAL NOT NULL DEFAULT 0,
        total_price REAL NOT NULL DEFAULT 0,
        FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE
    );
    `);
    console.log("Orders tables ready.");
} catch (e) {
    console.error("Error creating orders tables:", e);
}
// ===== /Orders tables (NEW) =====
