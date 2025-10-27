# Docker Deployment Guide

This guide explains how to run the Acquisitions API using Docker with different database configurations for development and production.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Development Setup (Neon Local)](#development-setup-neon-local)
- [Production Setup (Neon Cloud)](#production-setup-neon-cloud)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)

## Overview

The application uses different database strategies for different environments:

- **Development**: Uses **Neon Local** via Docker, which creates ephemeral database branches that are automatically created when the container starts and deleted when it stops.
- **Production**: Uses **Neon Cloud Database** with a persistent connection string.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose v2+
- Neon account (https://neon.tech)
- Neon API Key (https://console.neon.tech -> Account -> API Keys)
- Neon Project ID (https://console.neon.tech -> Project Settings -> General)

## Development Setup (Neon Local)

### Step 1: Configure Environment Variables

1. Copy the development environment template:
   ```bash
   cp .env.development.example .env.development
   ```

2. Edit `.env.development` and fill in your Neon credentials:
   ```env
   # Neon Configuration
   NEON_API_KEY=neon_api_xxxxxxxxxxxx
   NEON_PROJECT_ID=your-project-id
   PARENT_BRANCH_ID=br_xxxxxxxxxxxxxx  # Your main/production branch ID
   
   # Arcjet
   ARCJET_KEY=your_arcjet_key
   ```

### Step 2: Start Development Environment

```bash
docker-compose -f docker-compose.dev.yml up --build
```

This will:
- Pull the `neondatabase/neon_local:latest` image
- Create an ephemeral Neon database branch from your parent branch
- Start your application connected to this ephemeral branch
- Automatically delete the branch when you stop the container

### Step 3: Access Your Application

- **Application**: http://localhost:3000
- **Database**: `postgres://neon:npg@localhost:5432/neondb?sslmode=require`

### Step 4: Stop Development Environment

```bash
docker-compose -f docker-compose.dev.yml down
```

This automatically deletes the ephemeral database branch.

### Development Features

✅ **Ephemeral Branches**: Fresh database on every start
✅ **Auto-cleanup**: No manual branch deletion needed
✅ **Hot Reload**: Source code changes reflect immediately (via volume mount)
✅ **Isolated Testing**: Each developer gets their own branch

## Production Setup (Neon Cloud)

### Step 1: Configure Production Environment

1. Copy the production environment template:
   ```bash
   cp .env.production.example .env.production
   ```

2. Edit `.env.production` and add your Neon Cloud connection string:
   ```env
   # Get this from: https://console.neon.tech -> Connection Details
   DATABASE_URL=postgres://user:password@ep-xxx-xxx.neon.tech/dbname?sslmode=require
   
   # Arcjet
   ARCJET_KEY=your_production_arcjet_key
   ```

### Step 2: Deploy Production Container

```bash
docker-compose -f docker-compose.prod.yml up -d --build
```

### Step 3: Verify Deployment

```bash
# Check container status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f app

# Health check
curl http://localhost:3000/health
```

### Step 4: Stop Production Container

```bash
docker-compose -f docker-compose.prod.yml down
```

## Environment Variables

### Development (.env.development)

| Variable | Description | Required |
|----------|-------------|----------|
| `NEON_API_KEY` | Your Neon API key | ✅ Yes |
| `NEON_PROJECT_ID` | Your Neon project ID | ✅ Yes |
| `PARENT_BRANCH_ID` | Parent branch for ephemeral branches | ✅ Yes |
| `DATABASE_URL` | Local connection string (auto-configured) | ✅ Yes |
| `PORT` | Application port | No (default: 3000) |
| `NODE_ENV` | Environment mode | No (default: development) |
| `LOG_LEVEL` | Logging level | No (default: debug) |
| `ARCJET_KEY` | Arcjet API key | ✅ Yes |

### Production (.env.production)

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | Neon Cloud connection string | ✅ Yes |
| `PORT` | Application port | No (default: 3000) |
| `NODE_ENV` | Environment mode | No (default: production) |
| `LOG_LEVEL` | Logging level | No (default: info) |
| `ARCJET_KEY` | Arcjet API key | ✅ Yes |

## How It Works

### Development Flow (Neon Local)

```mermaid
┌─────────────────┐
│   Your App      │
│  (Container)    │
└────────┬────────┘
         │ connects to
         │ postgres://neon:npg@neon-local:5432/neondb
         ↓
┌─────────────────┐
│  Neon Local     │
│    (Proxy)      │
└────────┬────────┘
         │ creates ephemeral branch
         │ routes queries to
         ↓
┌─────────────────┐
│   Neon Cloud    │
│ (Ephemeral DB)  │
└─────────────────┘
```

### Production Flow (Direct Connection)

```mermaid
┌─────────────────┐
│   Your App      │
│  (Container)    │
└────────┬────────┘
         │ connects directly to
         │ postgres://...neon.tech/dbname
         ↓
┌─────────────────┐
│   Neon Cloud    │
│ (Production DB) │
└─────────────────┘
```

## Database Migrations

### Development
```bash
# Run migrations against ephemeral branch
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Generate migrations
docker-compose -f docker-compose.dev.yml exec app npm run db:generate

# Open Drizzle Studio
docker-compose -f docker-compose.dev.yml exec app npm run db:studio
```

### Production
```bash
# Run migrations against production database
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
```

## Useful Docker Commands

```bash
# Rebuild containers
docker-compose -f docker-compose.dev.yml build --no-cache

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# View specific service logs
docker-compose -f docker-compose.dev.yml logs -f app
docker-compose -f docker-compose.dev.yml logs -f neon-local

# Execute commands in container
docker-compose -f docker-compose.dev.yml exec app sh

# Remove volumes
docker-compose -f docker-compose.dev.yml down -v

# Check resource usage
docker stats
```

## Troubleshooting

### Issue: "Cannot connect to database"

**Solution**: Ensure Neon Local is healthy:
```bash
docker-compose -f docker-compose.dev.yml ps
docker-compose -f docker-compose.dev.yml logs neon-local
```

### Issue: "NEON_API_KEY not found"

**Solution**: Make sure `.env.development` exists and contains valid credentials.

### Issue: "Port 5432 already in use"

**Solution**: Stop local PostgreSQL or change the port mapping in `docker-compose.dev.yml`:
```yaml
ports:
  - '5433:5432'  # Changed from 5432:5432
```

Then update DATABASE_URL accordingly.

### Issue: Self-signed certificate error (JavaScript apps)

**Solution**: When using the `pg` or `postgres` library, configure SSL:
```javascript
import pg from 'pg';

const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});
```

### Issue: Branch not being deleted

**Solution**: Check `DELETE_BRANCH` environment variable:
```bash
docker-compose -f docker-compose.dev.yml exec neon-local env | grep DELETE_BRANCH
```

### Issue: App crashes on startup

**Solution**: Check if app is waiting for database:
```bash
docker-compose -f docker-compose.dev.yml logs app
```

The `depends_on` with health check should ensure neon-local is ready before app starts.

## Security Best Practices

1. ✅ **Never commit** `.env.development` or `.env.production` files
2. ✅ **Use secrets management** in production (AWS Secrets Manager, HashiCorp Vault, etc.)
3. ✅ **Rotate API keys** regularly
4. ✅ **Use different credentials** for development and production
5. ✅ **Enable SSL** for all database connections
6. ✅ **Run containers as non-root user** (already configured in Dockerfile)

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and deploy
        env:
          DATABASE_URL: ${{ secrets.NEON_DATABASE_URL }}
          ARCJET_KEY: ${{ secrets.ARCJET_KEY }}
        run: |
          docker-compose -f docker-compose.prod.yml up -d --build
```

## Getting Your Neon Credentials

### Neon API Key
1. Go to https://console.neon.tech
2. Click your profile → Account Settings
3. Go to "API Keys" section
4. Click "Generate new API key"
5. Copy the key (starts with `neon_api_`)

### Neon Project ID
1. Go to https://console.neon.tech
2. Select your project
3. Go to "Project Settings" → "General"
4. Copy the "Project ID"

### Parent Branch ID
1. Go to https://console.neon.tech
2. Select your project
3. Go to "Branches" tab
4. Find your main/production branch
5. Copy the branch ID (starts with `br_`)

## Additional Resources

- [Neon Local Documentation](https://neon.com/docs/local/neon-local)
- [Neon Branching Guide](https://neon.com/docs/guides/branching)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Drizzle ORM Documentation](https://orm.drizzle.team/)

## Support

For issues or questions:
- Neon Support: https://neon.tech/docs/introduction/support
- Project Issues: https://github.com/prospermbuma/acquisitions/issues
