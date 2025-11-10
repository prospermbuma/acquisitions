# Production deployment script for Acquisition App
# This script starts the application in production mode with Neon Cloud Database

Write-Host "🚀 Starting Acquisition App in Production Mode" -ForegroundColor Cyan
Write-Host "===============================================`n"

# Check if .env.production exists
if (-not (Test-Path ".env.production")) {
    Write-Host "❌ Error: .env.production file not found!" -ForegroundColor Red
    Write-Host "   Please create .env.production with your production environment variables."
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

Write-Host "📦 Building and starting production container..." -ForegroundColor Yellow
Write-Host "   - Using Neon Cloud Database (no local proxy)"
Write-Host "   - Running in optimized production mode`n"

# Start production environment (detached mode)
docker compose -f docker-compose.prod.yml up --build -d

# Wait for DB to be ready (basic health check)
Write-Host "⏳ Waiting for Neon Cloud to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Run migrations with Drizzle
Write-Host "📜 Applying latest schema with Drizzle..." -ForegroundColor Yellow
npm run db:migrate

Write-Host ""
Write-Host "🎉 Production environment started!" -ForegroundColor Green
Write-Host "   Application: http://localhost:3000"
Write-Host "   Logs: docker logs acquisition-app-prod`n"

Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "   🔍 View logs: docker logs -f acquisition-app-prod"
Write-Host "   ⏹ Stop app: docker compose -f docker-compose.prod.yml down"
