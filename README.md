# LiveChat

A live chat interface built with Rails API backend and Vue.js frontend.

## Tech Stack

- **Backend**: Rails 8.1 API (Ruby 3.2.2)
- **Frontend**: Vue 3 with TypeScript, Vite, Vue Router, Pinia
- **Database**: PostgreSQL 16
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Docker and Docker Compose installed
- Git

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/maxxb95/LiveChat.git
cd LiveChat
```

### 2. Start the Application

Start all services (database, backend API, and frontend) using Docker Compose:

```bash
docker-compose up
```

To run in detached mode (background):

```bash
docker-compose up -d
```

### 3. Database Initialization

The database is automatically created and migrated when the API container starts. The Rails entrypoint script runs `rails db:prepare`, which:
- Creates the database if it doesn't exist
- Runs pending migrations automatically
- Does nothing if the database is already up to date

**Note**: If you need to manually run database commands, you can still use:

```bash
# Create database
docker-compose exec api bundle exec rails db:create

# Run migrations
docker-compose exec api bundle exec rails db:migrate

# Or both at once
docker-compose exec api bundle exec rails db:create db:migrate
```

## Accessing the Services

### Frontend

- **URL**: http://localhost:5173
- **Container**: `livechat_frontend`
- The Vue development server runs on port 5173 with hot module replacement enabled.

### Backend API

- **URL**: http://localhost:3000
- **Container**: `api`
- Rails API server running on port 3000.

### Database (PostgreSQL)

- **Host**: localhost
- **Port**: 5432
- **Database**: `livechat`
- **Username**: `dev`
- **Password**: `postgres`
- **Container**: `livechat_db`

## Accessing the Database with pgAdmin 4

1. **Install pgAdmin 4** (if not already installed):
   - Download from: https://www.pgadmin.org/download/

2. **Open pgAdmin 4** and create a new server connection:
   - Right-click "Servers" → "Register" → "Server"
   - **General Tab**:
     - Name: `LiveChat Development`
   - **Connection Tab**:
     - Host name/address: `localhost`
     - Port: `5432`
     - Maintenance database: `livechat`
     - Username: `dev`
     - Password: `postgres`
   - Click "Save"

## Common Commands

### Stop Services

```bash
docker-compose down
```

### Stop and Remove Volumes (⚠️ This deletes database data)

```bash
docker-compose down -v
```

### Rebuild Services

```bash
# Rebuild all services
docker-compose build

# Rebuild specific service
docker-compose build api
docker-compose build frontend
```

### Run Rails Commands

```bash
# Rails console
docker-compose exec api bundle exec rails console

# Run migrations
docker-compose exec api bundle exec rails db:migrate

# Create a migration
docker-compose exec api bundle exec rails generate migration MigrationName

# Run seeds
docker-compose exec api bundle exec rails db:seed
```

### Run Frontend Commands

```bash
# Install new npm packages
docker-compose exec frontend npm install <package-name>

# Run linting
docker-compose exec frontend npm run lint
```

### Database Access via Command Line

```bash
# Connect to PostgreSQL
docker-compose exec db psql -U dev -d livechat
```

## Exposing with ngrok

To expose your local development server to the internet (useful for testing with external devices or sharing with others):

### Quick Start

1. **Prerequisites**:
   ```bash
   # Install ngrok
   brew install ngrok  # macOS
   # or download from https://ngrok.com/download
   
   # Sign up and get authtoken from https://dashboard.ngrok.com/get-started/your-authtoken
   ngrok config add-authtoken YOUR_AUTHTOKEN
   ```

2. **Start your Docker containers**:
   ```bash
   docker compose up -d
   ```

3. **Run the ngrok script**:
   ```bash
   ./scripts/ngrok.sh
   ```

4. **Share the URL**: The script will output a single shareable URL that includes everything needed. Just copy and share it!

   Example output:
   ```
   📋 SHARE THIS URL (includes backend automatically):
   https://frontend-xyz.ngrok-free.app?backend=https://backend-abc.ngrok-free.app
   ```

   **Note**: On first visit, ngrok-free domains show a warning page - click "Visit Site" to proceed.

### How It Works

- The script automatically starts both **frontend** (port 5173) and **backend** (port 3000) tunnels via ngrok
- It generates a single shareable URL with the backend URL included as a parameter
- The frontend automatically detects it's on ngrok and reads the backend URL from the `?backend=` parameter
- The backend URL is stored in sessionStorage, so it persists across page refreshes
- **Remote devices** (like phones) can access both services through their ngrok URLs

### Important Notes

- **ngrok URLs change** each time you restart ngrok (unless you have a paid plan with a static domain)
- **WebSocket support**: ngrok supports WebSockets, so ActionCable will work through ngrok
- **CORS & ActionCable**: The backend is already configured to accept requests from ngrok domains
- **Vite allowedHosts**: The frontend is configured to allow ngrok domains in `vite.config.ts`
- **Security**: Only use ngrok for development/testing. Never expose production servers this way without proper authentication

### Troubleshooting

- **"The site can't provide a secure connection"**: 
  - Make sure you're using the **HTTPS** URL from ngrok (not HTTP)
  - On first visit, ngrok-free domains show a warning page - click "Visit Site" to proceed
  - Make sure both backend and frontend are exposed via ngrok (not just frontend)
  - The shareable URL must include the `?backend=` parameter

- **Frontend can't connect to backend**:
  - Verify the shareable URL includes `?backend=YOUR_BACKEND_NGROK_URL`
  - Check browser console for errors
  - Make sure both ngrok tunnels are running

- **Vite host warning**: The ngrok domain is already configured in `vite.config.ts` - this warning can be ignored

- **CORS errors**: The backend is already configured for ngrok domains, but verify `backend/config/initializers/cors.rb`

- **WebSocket connection fails**: Check `backend/config/environments/development.rb` for ActionCable origins

## Development

### Backend Development

- Backend code is mounted as a volume, so changes are reflected immediately
- Rails server auto-reloads on code changes
- Logs are available via `docker compose logs -f api`

### Frontend Development

- Frontend code is mounted as a volume with hot module replacement
- Changes to Vue components are reflected immediately in the browser
- Logs are available via `docker compose logs -f frontend`

## Project Structure

```
LiveChat/
├── backend/          # Rails API
│   ├── app/
│   ├── config/
│   └── db/
├── frontend/         # Vue.js application
│   ├── src/
│   ├── public/
│   └── package.json
└── docker-compose.yml
```
