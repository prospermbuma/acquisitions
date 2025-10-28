# Docker Scripts Documentation

This directory contains scripts to manage the Acquisitions API Docker environments for both Unix/Linux (`.sh`) and Windows PowerShell (`.ps1`) systems.

## 📁 Available Scripts

### Development Scripts
- **`dev.sh`** / **`dev.ps1`** - Start development environment with Neon Local
- **`dev-stop.ps1`** - Stop development environment (PowerShell only)

### Production Scripts
- **`prod.sh`** / **`prod.ps1`** - Start production environment with Neon Cloud
- **`prod-stop.ps1`** - Stop production environment (PowerShell only)

### Utility Scripts
- **`docker-logs.ps1`** - View logs and status for Docker environments (PowerShell only)

## 🚀 Quick Start

### For Windows (PowerShell)
```powershell
# Start development environment
npm run docker:dev:ps1

# Start production environment  
npm run docker:prod:ps1

# Stop environments
npm run docker:dev:stop
npm run docker:prod:stop

# View logs
npm run docker:logs
```

### For Unix/Linux/Mac (Bash)
```bash
# Start development environment
npm run docker:dev

# Start production environment
npm run docker:prod
```

## 📋 NPM Scripts Reference

### Environment Management
| Script | Command | Description |
|--------|---------|-------------|
| `docker:dev` | `sh ./scripts/dev.sh` | Start dev environment (bash) |
| `docker:prod` | `sh ./scripts/prod.sh` | Start prod environment (bash) |
| `docker:dev:ps1` | `powershell -ExecutionPolicy Bypass -File ./scripts/dev.ps1` | Start dev environment (PowerShell) |
| `docker:prod:ps1` | `powershell -ExecutionPolicy Bypass -File ./scripts/prod.ps1` | Start prod environment (PowerShell) |
| `docker:dev:stop` | `powershell -ExecutionPolicy Bypass -File ./scripts/dev-stop.ps1` | Stop dev environment |
| `docker:prod:stop` | `powershell -ExecutionPolicy Bypass -File ./scripts/prod-stop.ps1` | Stop prod environment |

### Logging & Monitoring
| Script | Command | Description |
|--------|---------|-------------|
| `docker:logs` | `powershell -ExecutionPolicy Bypass -File ./scripts/docker-logs.ps1` | Show logs for all environments |
| `docker:logs:dev` | `powershell -ExecutionPolicy Bypass -File ./scripts/docker-logs.ps1 -Environment dev` | Show dev environment logs |
| `docker:logs:prod` | `powershell -ExecutionPolicy Bypass -File ./scripts/docker-logs.ps1 -Environment prod` | Show prod environment logs |
| `docker:logs:follow` | `powershell -ExecutionPolicy Bypass -File ./scripts/docker-logs.ps1 -Follow` | Follow logs in real-time |

## 🔧 Script Details

### Development Scripts (`dev.sh` / `dev.ps1`)

**What it does:**
- ✅ Checks if `.env.development` exists
- ✅ Verifies Docker is running
- ✅ Creates `.neon_local` directory
- ✅ Updates `.gitignore` with Neon Local exclusions
- ✅ Starts Neon Local proxy with ephemeral database branch
- ✅ Starts application container with hot reload

**Requirements:**
- Docker Desktop running
- `.env.development` configured with Neon credentials

**Usage:**
```powershell
# PowerShell (Windows)
npm run docker:dev:ps1

# Bash (Unix/Linux/Mac)
npm run docker:dev
```

### Production Scripts (`prod.sh` / `prod.ps1`)

**What it does:**
- ✅ Checks if `.env.production` exists
- ✅ Verifies Docker is running
- ✅ Starts production container with Neon Cloud connection
- ✅ Runs database migrations automatically
- ✅ Shows container status and useful commands

**Requirements:**
- Docker Desktop running
- `.env.production` configured with production DATABASE_URL

**Usage:**
```powershell
# PowerShell (Windows)
npm run docker:prod:ps1

# Bash (Unix/Linux/Mac)  
npm run docker:prod
```

### Stop Scripts (`dev-stop.ps1` / `prod-stop.ps1`)

**What they do:**
- ✅ Stop Docker containers gracefully
- ✅ Remove containers (not volumes)
- ✅ Clean up network resources
- ✅ Show confirmation messages

**Usage:**
```powershell
# Stop development environment
npm run docker:dev:stop

# Stop production environment
npm run docker:prod:stop
```

### Logging Script (`docker-logs.ps1`)

**What it does:**
- ✅ Shows container status for dev/prod environments
- ✅ Displays recent logs (last 50 lines)
- ✅ Supports real-time log following
- ✅ Environment-specific or combined view

**Parameters:**
- `-Environment`: `dev`, `prod`, or `both` (default: `both`)
- `-Follow`: Follow logs in real-time

**Usage:**
```powershell
# View all environments
npm run docker:logs

# View specific environment
npm run docker:logs:dev
npm run docker:logs:prod

# Follow logs in real-time
npm run docker:logs:follow

# Direct PowerShell usage with parameters
powershell -ExecutionPolicy Bypass -File ./scripts/docker-logs.ps1 -Environment dev -Follow
```

## 🛠️ Manual Script Execution

### PowerShell Scripts (Windows)
```powershell
# Navigate to project root
cd C:\Users\PC\acquisitions

# Run development script
.\scripts\dev.ps1

# Run production script
.\scripts\prod.ps1

# Stop development environment
.\scripts\dev-stop.ps1

# Stop production environment
.\scripts\prod-stop.ps1

# View logs with parameters
.\scripts\docker-logs.ps1 -Environment dev -Follow
```

### Bash Scripts (Unix/Linux/Mac)
```bash
# Navigate to project root
cd /path/to/acquisitions

# Make scripts executable (if needed)
chmod +x scripts/*.sh

# Run development script
./scripts/dev.sh

# Run production script
./scripts/prod.sh
```

## 🔍 Troubleshooting

### PowerShell Execution Policy Issues
If you get execution policy errors, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Or use bypass for single execution:
```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/dev.ps1
```

### Docker Not Running
All scripts check if Docker is running and provide helpful error messages:
```
❌ Error: Docker is not running!
   Please start Docker Desktop and try again.
```

### Missing Environment Files
Scripts check for required environment files:
```
❌ Error: .env.development file not found!
   Please copy .env.development from the template and update with your Neon credentials.
```

## 🎯 Common Workflows

### Daily Development (Windows)
```powershell
# Start development
npm run docker:dev:ps1

# View logs while developing
npm run docker:logs:dev

# Stop when done
npm run docker:dev:stop
```

### Production Deployment
```powershell
# Deploy to production
npm run docker:prod:ps1

# Monitor production
npm run docker:logs:prod

# Check status
npm run docker:logs:prod
```

### Cross-Platform Development
```bash
# Unix/Linux/Mac developers
npm run docker:dev

# Windows developers  
npm run docker:dev:ps1
```

## 📊 Script Features Comparison

| Feature | Bash Scripts | PowerShell Scripts |
|---------|-------------|-------------------|
| Environment checks | ✅ | ✅ |
| Docker validation | ✅ | ✅ |
| Colored output | ✅ | ✅ |
| Error handling | ✅ | ✅ |
| Stop scripts | ❌ | ✅ |
| Log viewing | ❌ | ✅ |
| Status monitoring | ❌ | ✅ |
| Parameters support | ❌ | ✅ |

## 🔒 Security Notes

- Scripts use `-ExecutionPolicy Bypass` only for the specific file execution
- No global execution policy changes are made
- Environment files are validated before container startup
- Scripts include safety checks for Docker daemon availability

## 📚 Related Documentation

- [Docker Deployment Guide](../README-DOCKER.md)
- [Neon Local Documentation](https://neon.com/docs/local/neon-local)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## 🤝 Contributing

When adding new scripts:
1. Create both `.sh` (bash) and `.ps1` (PowerShell) versions when possible
2. Add corresponding npm scripts to `package.json`
3. Update this documentation
4. Include error handling and validation
5. Use consistent color coding and messaging