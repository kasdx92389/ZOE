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