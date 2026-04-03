# Link Manager Web Interface

A web-based link management system that runs on port 443 with a separate nginx proxy on port 8080.

## Features

- **Port 443 Webserver**: Main application running on HTTPS port 443
- **Nginx Proxy**: Separate nginx proxy running on port 8080
- **Link Management**: Add, edit, and delete links
- **File Storage**: Links stored in `links.json` file on disk
- **New Tab Option**: Checkbox to control if links open in new tab
- **Original CSS**: Reuses the color scheme and styling from the original website
- **Edit/Delete Icons**: Each link has edit and delete action buttons
- **Responsive Design**: Works on desktop and mobile devices

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Browser       │    │   Nginx Proxy   │    │  Link Manager   │
│   (Port 8080)   │───▶│   (Port 80)     │───▶│   (Port 443)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                      │
                                              ┌─────────────┐
                                              │ links.json  │
                                              │  (File)     │
                                              └─────────────┘
```

## Quick Start

1. **Install Dependencies**:
   ```bash
   cd website2
   npm install
   ```

2. **Run with Docker**:
   ```bash
   docker-compose up -d --build
   ```

3. **Access the Application**:
   - Main interface: https://localhost:443
   - Via nginx proxy: http://localhost:8080

## Development

### Running Locally

```bash
# Install dependencies
npm install

# Start the server
npm start

# Or for development with auto-reload
npm run dev
```

The server will start on https://localhost:443

### File Structure

```
website2/
├── package.json          # Node.js dependencies
├── server.js             # Express server with API endpoints
├── Dockerfile            # Docker container configuration
├── docker-compose.yaml   # Docker Compose setup
├── nginx.conf            # Nginx proxy configuration
├── links.json            # Link data storage (auto-created)
├── public/
│   └── index.html        # Web interface
└── README.md             # This file
```

## API Endpoints

- `GET /api/links` - Get all links
- `POST /api/links` - Add new link
- `PUT /api/links/:id` - Update existing link
- `DELETE /api/links/:id` - Delete link

## Data Format

Links are stored in `links.json` with the following structure:

```json
[
  {
    "id": 1234567890,
    "title": "Example Link",
    "url": "https://example.com",
    "newTab": true,
    "createdAt": "2023-12-07T10:30:00.000Z",
    "updatedAt": "2023-12-07T10:30:00.000Z"
  }
]
```

## Usage

1. **Add Links**: Click the "+ Add New Link" button
2. **Edit Links**: Click the edit icon on any link card
3. **Delete Links**: Click the delete icon or use delete in edit modal
4. **New Tab**: Check the "Open in new tab" checkbox when adding/editing
5. **Navigate**: Click on link cards to navigate to the URL

## Security Notes

- The application runs on port 443 but uses self-signed certificates
- For production, use proper SSL certificates
- The nginx proxy runs on port 8080 for demonstration
- File permissions should be secured for `links.json`

## Customization

- Modify CSS variables in `public/index.html` to change colors
- Update nginx.conf for different proxy configurations
- Extend the API in `server.js` for additional features
