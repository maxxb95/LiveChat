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

**Note**: This README uses `docker-compose` in examples, but newer Docker installations use `docker compose` (with a space instead of a hyphen). If `docker-compose` doesn't work, try `docker compose` instead. Both commands are functionally equivalent.

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

## Exposing the Frontend with ngrok

To expose the frontend development server to the internet (e.g., for testing on mobile devices or sharing with others), you can use ngrok:

### Setup

1. **Install ngrok** (if not already installed):
   - Download from: https://ngrok.com/download
   - Or install via Homebrew: `brew install ngrok`

2. **Start the application** (if not already running):

   ```bash
   docker-compose up
   ```

3. **Expose the frontend with ngrok**:

   ```bash
   ngrok http 5173
   ```

   This will create a public URL (e.g., `https://abc123.ngrok-free.dev`) that forwards to your local frontend on port 5173.

### Configuration

The application is pre-configured to accept requests from any `*.ngrok-free.dev` domain via regex patterns in the following files:

- **`backend/config/environments/development.rb`**:
  - `config.hosts << /.*\.ngrok-free\.dev/` - Allows Rails to accept requests from ngrok domains
  - `config.action_cable.allowed_request_origins` includes `/https?:\/\/.*\.ngrok-free\.dev/` - Allows WebSocket connections from ngrok domains

- **`backend/config/initializers/cors.rb`**:
  - Includes `/https?:\/\/.*\.ngrok-free\.dev/` in the `origins` list - Allows CORS requests from ngrok domains

- **`frontend/vite.config.ts`**:
  - `allowedHosts: ['.ngrok-free.dev']` - Allows Vite dev server to accept requests from ngrok domains

**Note**: If you're using a different ngrok domain pattern (e.g., `*.ngrok.io` or a custom domain), you'll need to update these regex patterns accordingly. After making changes, restart the backend container:

```bash
docker-compose restart api
```

## Development

### Backend Development

- Backend code is mounted as a volume, so changes are reflected immediately
- Rails server auto-reloads on code changes
- Logs are available via `docker-compose logs -f api`

### Frontend Development

- Frontend code is mounted as a volume with hot module replacement
- Changes to Vue components are reflected immediately in the browser
- Logs are available via `docker-compose logs -f frontend`

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

## Current Limitations

- **Message Length**: Maximum 10,000 characters per message
- **User Identification**: Users are identified by IP address (normalized for IPv6 privacy extensions)
- **Rate Limiting**: No rate limiting is currently implemented
- **Authentication**: No user authentication system
- **Message History**: Limited to 100 messages per page (pagination supported)

## Future Enhancements

### Authentication & User Management

- Implement user authentication (sign in/sign up), or integrate with existing auth systems for larger applications
- Allow users to set custom display names, or get display name from session
- User profiles and avatars

### Chat Features

- **Multiple Chat Rooms**:
  - Add `ChatRoom` model with foreign key association to messages
  - Room-based message filtering and routing
- **Message Reactions**: Emoji reactions to messages
- **File Attachments**: Support for image/file sharing
- **Message Editing/Deletion**: Allow users to edit or delete their own messages
- **Message comment threads**: Comment directly on a specific message to start a thread
- **Handle failed message sends**: Show grey message with red exclamation point if it didn't send successfully

### Performance & UX

- **Infinite Scroll**: Implement infinite scroll in the frontend using the paginated messages API
- **Message Search**: Search functionality for finding specific messages
- **Message Persistence**: Configurable message retention policies
- **Connection Recovery**: Automatic message recovery when reconnecting after disconnection

### Security & Reliability

- **Rate Limiting**: Implement rate limiting to prevent spam and abuse
- **Message Encryption**: End-to-end encryption for sensitive conversations
- **Audit Logging**: Track message history and user actions
