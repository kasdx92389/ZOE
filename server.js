const express = require('express');
const path = require('path');
const session = require('express-session');
const bcrypt = require('bcrypt');
const fs = require('fs');
const app = express();
const PORT = 3000;

// --- ค่าคงที่ ---
const MASTER_CODE = 'KESU-SECRET-2025';
const saltRounds = 10;
const USERS_FILE_PATH = path.join(__dirname, 'users.json');

// --- ระบบจัดเก็บข้อมูลผู้ใช้ (อ่านจากไฟล์) ---
let users = {};

try {
    const data = fs.readFileSync(USERS_FILE_PATH, 'utf8');
    users = JSON.parse(data);
} catch (error) {
    console.log('users.json not found or is invalid. Creating a new one with a default admin...');
    const defaultAdminPassword = 'DgGUxU4N';
    const hashedDefaultPassword = bcrypt.hashSync(defaultAdminPassword, saltRounds);
    users = {
        'admin': hashedDefaultPassword
    };
    fs.writeFileSync(USERS_FILE_PATH, JSON.stringify(users, null, 2));
}

// --- Middleware ---
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.use(session({
    secret: 'a-very-secret-key-for-your-session-12345', // ควรเป็น Environment Variable ใน Production
    resave: false,
    saveUninitialized: false,
    cookie: { 
        secure: false, // สำหรับ localhost ควรเป็น false, ใน Production ควรเป็น true ถ้าใช้ HTTPS
        httpOnly: true,
        maxAge: 30 * 24 * 60 * 60 * 1000 // 30 วันในหน่วยมิลลิวินาที
    }
}));

const requireLogin = (req, res, next) => {
    if (req.session.userId) {
        next();
    } else {
        res.redirect('/');
    }
};

// --- Routes ---
app.get('/', (req, res) => {
    // ตรวจสอบว่ามี session อยู่หรือไม่ ถ้ามีให้ไปที่ dashboard เลย
    if (req.session.userId) {
        return res.redirect('/admin/dashboard');
    }
    res.sendFile(path.join(__dirname, 'admin-login.html'));
});

app.get('/register', (req, res) => {
    res.sendFile(path.join(__dirname, 'admin-register.html'));
});

app.post('/login', async (req, res) => {
    const { username, password } = req.body; // ไม่มี 'remember' แล้ว
    const userHash = users[username];

    if (userHash) {
        const match = await bcrypt.compare(password, userHash);
        if (match) {
            req.session.userId = username;
            // maxAge ถูกตั้งค่าไว้ใน middleware express-session แล้ว
            return res.redirect('/admin/dashboard');
        }
    }
    const message = encodeURIComponent('Username หรือ Password ไม่ถูกต้อง');
    res.redirect(`/?error=${message}`);
});

app.post('/register', async (req, res) => {
    const { username, password, master_code } = req.body;

    if (master_code !== MASTER_CODE) {
        const message = encodeURIComponent('รหัสโค้ดลับไม่ถูกต้อง.');
        return res.redirect(`/register?error=${message}`);
    }

    if (users[username]) {
        const message = encodeURIComponent('Username นี้มีผู้ใช้งานแล้ว.');
        return res.redirect(`/register?error=${message}`);
    }

    const hashedPassword = await bcrypt.hash(password, saltRounds);
    users[username] = hashedPassword;

    try {
        fs.writeFileSync(USERS_FILE_PATH, JSON.stringify(users, null, 2));
        console.log('New user created and saved:', { username });
        const message = encodeURIComponent('สร้างบัญชีสำเร็จ! กรุณาล็อกอิน');
        res.redirect(`/?success=${message}`);
    } catch (error) {
        console.error('Failed to save new user:', error);
        const message = encodeURIComponent('เกิดข้อผิดพลาดในการบันทึกข้อมูลผู้ใช้');
        res.redirect(`/register?error=${message}`);
    }
});

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

app.get('/terms', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'terms.html'));
});

app.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
    console.log(`Master Code for Registration: ${MASTER_CODE}`);
});