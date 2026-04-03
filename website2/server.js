const express = require('express');
const fs = require('fs-extra');
const path = require('path');
const app = express();
const PORT = 443;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Links file path
const linksPath = path.join(__dirname, 'links.json');

// Initialize links file if it doesn't exist
async function initializeLinksFile() {
    try {
        if (!await fs.pathExists(linksPath)) {
            await fs.writeJson(linksPath, []);
            console.log('Created links.json file');
        }
    } catch (error) {
        console.error('Error initializing links file:', error);
    }
}

// API Routes
app.get('/api/links', async (req, res) => {
    try {
        const links = await fs.readJson(linksPath);
        res.json(links);
    } catch (error) {
        res.status(500).json({ error: 'Error reading links' });
    }
});

app.post('/api/links', async (req, res) => {
    try {
        const { title, url, newTab } = req.body;
        const links = await fs.readJson(linksPath);
        
        const newLink = {
            id: Date.now(),
            title: title.trim(),
            url: url.trim(),
            newTab: Boolean(newTab),
            createdAt: new Date().toISOString()
        };
        
        links.push(newLink);
        await fs.writeJson(linksPath, links);
        
        res.json(newLink);
    } catch (error) {
        res.status(500).json({ error: 'Error adding link' });
    }
});

app.put('/api/links/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { title, url, newTab } = req.body;
        const links = await fs.readJson(linksPath);
        
        const linkIndex = links.findIndex(link => link.id == id);
        if (linkIndex === -1) {
            return res.status(404).json({ error: 'Link not found' });
        }
        
        links[linkIndex] = {
            ...links[linkIndex],
            title: title.trim(),
            url: url.trim(),
            newTab: Boolean(newTab),
            updatedAt: new Date().toISOString()
        };
        
        await fs.writeJson(linksPath, links);
        res.json(links[linkIndex]);
    } catch (error) {
        res.status(500).json({ error: 'Error updating link' });
    }
});

app.delete('/api/links/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const links = await fs.readJson(linksPath);
        
        const linkIndex = links.findIndex(link => link.id == id);
        if (linkIndex === -1) {
            return res.status(404).json({ error: 'Link not found' });
        }
        
        const deletedLink = links.splice(linkIndex, 1)[0];
        await fs.writeJson(linksPath, links);
        
        res.json(deletedLink);
    } catch (error) {
        res.status(500).json({ error: 'Error deleting link' });
    }
});

// Serve the main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Initialize and start server
initializeLinksFile().then(() => {
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Link manager server running on https://localhost:${PORT}`);
    });
});
