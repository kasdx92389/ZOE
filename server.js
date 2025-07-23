const express = require('express');
const path = require('path');
const session = require('express-session');
const app = express();
const PORT = 3000;

// --- ค่าคงที่ (ใช้รหัสผ่านแบบข้อความธรรมดา) ---
const ADMIN_USER = 'admin';
const ADMIN_PASSWORD = 'DgGUxU4N'; // <--- ตั้งรหัสผ่านที่ต้องการตรงนี้

// --- Middleware ---
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.use(session({
    secret: 'a-very-secret-key-for-your-session-12345',
    resave: false,
    saveUninitialized: false,
    cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 } // อายุ session 1 วัน
}));

const requireLogin = (req, res, next) => {
    if (req.session.userId) {
        next();
    } else {
        res.redirect('/');
    }
};

// --- Routes ---

// หน้าล็อกอิน
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'admin-login.html'));
});

// หน้าข้อกำหนด
app.get('/terms', requireLogin, (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'terms.html'));
});

// รับข้อมูลจากฟอร์ม Login
app.post('/login', (req, res) => {
    const { username, password } = req.body;
    if (username === ADMIN_USER && password === ADMIN_PASSWORD) {
        req.session.userId = ADMIN_USER;
        res.redirect('/admin/dashboard');
    } else {
        res.status(401).send('Login Failed. <a href="/">Try again</a>');
    }
});

// ออกจากระบบ
app.get('/logout', (req, res) => {
    req.session.destroy(err => {
        if (err) {
            return res.redirect('/admin/dashboard');
        }
        res.clearCookie('connect.sid');
        res.redirect('/');
    });
});

// --- ส่วนของ Admin ที่ต้องล็อกอิน ---
app.get('/admin/dashboard', requireLogin, (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'admin-dashboard.html'));
});

// --- เริ่มรันเซิร์ฟเวอร์ ---
app.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
    console.log(`Admin user: ${ADMIN_USER}`);
    console.log(`Admin pass: ${ADMIN_PASSWORD}`);
});