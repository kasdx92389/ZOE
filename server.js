const express = require('express');
const path = require('path');
const app = express();

// Render จะกำหนด Port ให้เอง หรือใช้ 3000 ถ้าทดสอบบนเครื่อง
const PORT = process.env.PORT || 3000;

// ให้บริการไฟล์ทั้งหมดจากโฟลเดอร์ public เท่านั้น
app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
    console.log(`Minimal Server is running at http://localhost:${PORT}`);
});