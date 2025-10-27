# Docker Deployment Guide - Acquisitions API

Complete guide for running the Acquisitions API with Docker, supporting both development (Neon Local) and production (Neon Cloud) environments.

## 🏗️ Architecture Overview

### Development Environment
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Your App      │◄──►│  Neon Local     │◄──►│   Neon Cloud    │
│  (Container)    │    │    (Proxy)      │    │ (Ephemeral DB)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
  localhost:3000         localhost:5432         managed remotely
```

### Production Environment
```
┌─────────────────┐                           ┌─────────────────┐
│   Your App      │◄─────────────────────────►│   Neon Cloud    │
│  (Container)    │        Direct Connection  │ (Production DB) │
└─────────────────┘                           └─────────────────┘
  localhost:3000                                managed remotely
```

## 📋 Prerequisites

1. **Docker Desktop** - Install from [docker.com](https://www.docker.com/products/docker-desktop)
2. **Neon Account** - Sign up at [neon.tech](https://neon.tech)
3. **Neon Credentials** - Get these from your Neon console:
   - API Key
   - Project ID 
   - Branch ID (for production)

## 🚀 Quick Start

### Development Setup (Neon Local)

1. **Configure environment variables**:
   ```bash
   # Edit .env.development with your credentials
   NEON_API_KEY=neon_api_xxxxxxxxxxxx
   NEON_PROJECT_ID=your-project-id
   PARENT_BRANCH_ID=br_xxxxxxxxxxxxxx
   ARCJET_KEY=your_arcjet_key
   ```

2. **Start development environment**:
   ```bash
   docker-compose -f docker-compose.dev.yml up --build
   ```

3. **Access your application**:
   - API: http://localhost:3000
   - Database: `postgres://neon:npg@localhost:5432/neondb`

4. **Stop and cleanup**:
   ```bash
   docker-compose -f docker-compose.dev.yml down
   # This automatically deletes the ephemeral database branch
   ```

### Production Setup (Neon Cloud)

1. **Configure production environment**:
   ```bash
   # Edit .env.production with your production DATABASE_URL
   DATABASE_URL=postgres://user:password@ep-xxx-xxx.neon.tech/dbname?sslmode=require
   ARCJET_KEY=your_production_arcjet_key
   ```

2. **Deploy production container**:
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

3. **Monitor deployment**:
   ```bash
   # Check status
   docker-compose -f docker-compose.prod.yml ps
   
   # View logs
   docker-compose -f docker-compose.prod.yml logs -f
   
   # Health check
   curl http://localhost:3000/health
   ```

## 🔧 Configuration Details

### Environment Files

#### `.env.development` (Local Development)
```env
# Server Configuration
PORT=3000
NODE_ENV=development
LOG_LEVEL=debug

# Database (Neon Local - auto-configured)
DATABASE_URL=postgres://neon:npg@neon-local:5432/neondb?sslmode=require

# Neon Configuration (Required for ephemeral branches)
NEON_API_KEY=neon_api_xxxxxxxxxxxx
NEON_PROJECT_ID=your-project-id
PARENT_BRANCH_ID=br_xxxxxxxxxxxxxx

# Other services
ARCJET_KEY=your_arcjet_key
```

#### `.env.production` (Production Deployment)
```env
# Server Configuration
PORT=3000
NODE_ENV=production
LOG_LEVEL=info

# Database (Direct Neon Cloud Connection)
DATABASE_URL=postgres://user:password@ep-xxx-xxx.neon.tech/dbname?sslmode=require

# Other services
ARCJET_KEY=your_production_arcjet_key
```

### Docker Compose Files

#### `docker-compose.dev.yml` - Development with Neon Local
- Runs Neon Local proxy container
- Creates ephemeral database branches
- Enables hot reload with volume mounts
- Auto-cleanup on container stop

#### `docker-compose.prod.yml` - Production with Neon Cloud
- Direct connection to Neon Cloud
- No proxy containers
- Health checks and auto-restart
- Production optimizations

## 📊 Key Features

### Development Environment
✅ **Ephemeral Database Branches** - Fresh database on every startup  
✅ **Auto-cleanup** - Branches deleted when containers stop  
✅ **Hot Reload** - Code changes reflect immediately  
✅ **Isolated Testing** - Each developer gets their own branch  
✅ **Zero Configuration** - Works out of the box with valid credentials

### Production Environment  
✅ **Direct Cloud Connection** - No proxy overhead  
✅ **Health Monitoring** - Built-in health checks  
✅ **Auto-restart** - Automatic recovery from failures  
✅ **Security** - Non-root user, minimal attack surface  
✅ **Performance** - Multi-stage build, optimized layers

## 🛠️ Database Operations

### Run Migrations
```bash
# Development
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Production
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
```

### Generate New Migrations
```bash
# Development
docker-compose -f docker-compose.dev.yml exec app npm run db:generate
```

### Open Drizzle Studio
```bash
# Development
docker-compose -f docker-compose.dev.yml exec app npm run db:studio
```

## 🔍 Monitoring & Debugging

### View Logs
```bash
# All services
docker-compose -f docker-compose.dev.yml logs -f

# Specific service
docker-compose -f docker-compose.dev.yml logs -f app
docker-compose -f docker-compose.dev.yml logs -f neon-local
```

### Execute Commands in Container
```bash
# Development
docker-compose -f docker-compose.dev.yml exec app sh

# Production  
docker-compose -f docker-compose.prod.yml exec app sh
```

### Check Container Status
```bash
# Development
docker-compose -f docker-compose.dev.yml ps

# Production
docker-compose -f docker-compose.prod.yml ps
```

## 🚨 Troubleshooting

### Common Issues

#### "Cannot connect to database"
**Cause**: Neon Local not ready or invalid credentials  
**Solution**:
```bash
# Check Neon Local health
docker-compose -f docker-compose.dev.yml logs neon-local

# Verify credentials in .env.development
echo $NEON_API_KEY
```

#### "Port 5432 already in use"
**Cause**: Local PostgreSQL running  
**Solution**: Stop local PostgreSQL or change port mapping:
```yaml
# In docker-compose.dev.yml
ports:
  - '5433:5432'  # Changed from 5432:5432
```

#### "SSL certificate error"
**Cause**: Self-signed certificate in Neon Local  
**Solution**: Already configured in connection string with `sslmode=require`

#### "Branch not being deleted"
**Cause**: `DELETE_BRANCH` not set  
**Solution**: Check environment variable:
```bash
docker-compose -f docker-compose.dev.yml exec neon-local env | grep DELETE_BRANCH
```

### Advanced Debugging

#### Check Database Connection
```bash
# Test connection inside container
docker-compose -f docker-compose.dev.yml exec app node -e "
const { Client } = require('pg');
const client = new Client({ connectionString: process.env.DATABASE_URL });
client.connect().then(() => console.log('Connected!')).catch(console.error);
"
```

#### Monitor Resource Usage
```bash
# View container resource consumption
docker stats
```

## 📖 Getting Neon Credentials

### Neon API Key
1. Go to [Neon Console](https://console.neon.tech)
2. Click Profile → Account Settings
3. Navigate to "API Keys" section
4. Click "Generate new API key"
5. Copy the key (starts with `neon_api_`)

### Neon Project ID
1. Go to [Neon Console](https://console.neon.tech) 
2. Select your project
3. Go to "Project Settings" → "General"
4. Copy the "Project ID"

### Parent Branch ID (for ephemeral branches)
1. Go to [Neon Console](https://console.neon.tech)
2. Select your project  
3. Go to "Branches" tab
4. Find your main/production branch
5. Copy the branch ID (starts with `br_`)

### Production DATABASE_URL
1. Go to [Neon Console](https://console.neon.tech)
2. Select your project
3. Go to "Connection Details"
4. Copy the connection string
5. Use format: `postgres://[user]:[password]@[endpoint]/[dbname]?sslmode=require`

## 🔒 Security Best Practices

1. ✅ **Never commit** environment files to version control
2. ✅ **Use different credentials** for development and production  
3. ✅ **Rotate API keys** regularly
4. ✅ **Use secrets management** in production (AWS Secrets Manager, etc.)
5. ✅ **Run containers as non-root** (already configured)
6. ✅ **Enable SSL** for all database connections

## 🚀 CI/CD Integration

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
      - uses: actions/checkout@v4
      
      - name: Deploy with Docker Compose
        env:
          DATABASE_URL: ${{ secrets.NEON_DATABASE_URL }}
          ARCJET_KEY: ${{ secrets.ARCJET_KEY }}
        run: |
          docker-compose -f docker-compose.prod.yml up -d --build
```

### Environment Variables for CI/CD
Set these secrets in your CI/CD platform:
- `NEON_DATABASE_URL` - Production database connection string
- `ARCJET_KEY` - Production Arcjet API key

## 🔄 Development Workflow

### Daily Development
```bash
# 1. Start development environment
docker-compose -f docker-compose.dev.yml up --build

# 2. Make code changes (hot reload active)
# Files in ./src/ automatically update in container

# 3. Run database migrations if needed
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# 4. Stop environment (auto-cleanup)
docker-compose -f docker-compose.dev.yml down
```

### Production Deployment
```bash
# 1. Configure production environment
vim .env.production

# 2. Deploy
docker-compose -f docker-compose.prod.yml up -d --build

# 3. Verify deployment
curl http://localhost:3000/health

# 4. Monitor
docker-compose -f docker-compose.prod.yml logs -f
```

## 📚 Additional Resources

- [Neon Local Documentation](https://neon.com/docs/local/neon-local)
- [Neon Branching Guide](https://neon.com/docs/guides/branching) 
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Drizzle ORM Documentation](https://orm.drizzle.team/)

## 💬 Support

For issues related to:
- **Neon Database**: [Neon Support](https://neon.tech/docs/introduction/support)
- **This Application**: [GitHub Issues](https://github.com/prospermbuma/acquisitions/issues)
- **Docker**: [Docker Documentation](https://docs.docker.com/)

---

## 📄 File Structure
```
acquisitions/
├── Dockerfile                 # Multi-stage Node.js container
├── docker-compose.dev.yml     # Development with Neon Local
├── docker-compose.prod.yml    # Production with Neon Cloud  
├── .dockerignore              # Docker build exclusions
├── .env.development           # Development configuration
├── .env.production            # Production configuration
└── src/                       # Application source code
```

Ready to develop with confidence! 🎉