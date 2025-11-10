# Development startup script for Acquisition App with Neon Local
# This script starts the application in development mode with Neon Local

Write-Host "🚀 Starting Acquisition App in Development Mode" -ForegroundColor Cyan
Write-Host "================================================`n"

# Check if .env.development exists
if (-not (Test-Path ".env.development")) {
    Write-Host "❌ Error: .env.development file not found!" -ForegroundColor Red
    Write-Host "   Please copy .env.development from the template and update with your Neon credentials."
    exit 1
}

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "❌ Error: Docker is not running!" -ForegroundColor Red
    Write-Host "   Please start Docker Desktop and try again."
    exit 1
}

# Create .neon_local directory if it doesn't exist
if (-not (Test-Path ".neon_local")) {
    New-Item -ItemType Directory -Path ".neon_local" | Out-Null
}

# Add .neon_local to .gitignore if not already present
if (-not (Select-String -Path ".gitignore" -Pattern ".neon_local/" -Quiet)) {
    Add-Content ".gitignore" ".neon_local/"
    Write-Host "✅ Added .neon_local/ to .gitignore" -ForegroundColor Green
}

Write-Host "📦 Building and starting development containers..." -ForegroundColor Yellow
Write-Host "   - Neon Local proxy will create an ephemeral database branch"
Write-Host "   - Application will run with hot reload enabled`n"

# Run migrations with Drizzle
Write-Host "📜 Applying latest schema with Drizzle..." -ForegroundColor Yellow
npm run db:migrate

# Wait for the database to be ready
Write-Host "⏳ Waiting for the database to be ready..." -ForegroundColor Yellow
docker compose exec neon-local psql -U neon -d neondb -c "SELECT 1"

# Start development environment
docker compose -f docker-compose.dev.yml up --build

Write-Host ""
Write-Host "🎉 Development environment started!" -ForegroundColor Green
Write-Host "   Application: http://localhost:3000"
Write-Host "   Database: postgres://neon:npg@localhost:5432/neondb`n"
Write-Host "To stop the environment, press Ctrl+C or run: docker compose down"
