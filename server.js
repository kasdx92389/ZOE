const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    console.log('--- ADVANCED DEBUGGER: Received request for root / ---');
    const publicDirPath = path.join(__dirname, 'public');
    const filePath = path.join(publicDirPath, 'index.html');

    console.log(`[DEBUG] Checking for public folder at: ${publicDirPath}`);
    if (!fs.existsSync(publicDirPath)) {
        console.error('[DEBUG] CRITICAL: The "public" folder does not exist!');
        return res.status(500).send('Server configuration error: public directory not found.');
    }
    console.log('[DEBUG] The "public" folder exists.');

    console.log(`[DEBUG] Checking for index.html at: ${filePath}`);
    if (!fs.existsSync(filePath)) {
        console.error('[DEBUG] CRITICAL: "index.html" does not exist inside the public folder!');
        return res.status(404).send('404 Not Found: index.html is missing.');
    }
    console.log('[DEBUG] "index.html" exists. Reading file...');

    try {
        const fileContent = fs.readFileSync(filePath);
        console.log(`[DEBUG] Successfully read file. Size: ${fileContent.length} bytes. Sending response...`);
        res.setHeader('Content-Type', 'text/html');
        res.send(fileContent);
    } catch (err) {
        console.error('[DEBUG] CRITICAL: Failed to read the file!', err);
        res.status(500).send('Server error: Could not read file.');
    }
});

app.listen(PORT, () => {
    console.log(`Advanced Debug Server is running at http://localhost:${PORT}`);
});