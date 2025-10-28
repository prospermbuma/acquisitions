# Production deployment script for Acquisition App
# This script starts the application in production mode with Neon Cloud Database

Write-Host "🚀 Starting Acquisition App in Production Mode" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# Check if .env.production exists
if (-Not (Test-Path ".env.production")) {
    Write-Host "❌ Error: .env.production file not found!" -ForegroundColor Red
    Write-Host "   Please create .env.production with your production environment variables." -ForegroundColor Yellow
    exit 1
}

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "❌ Error: Docker is not running!" -ForegroundColor Red
    Write-Host "   Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "📦 Building and starting production container..." -ForegroundColor Cyan
Write-Host "   - Using Neon Cloud Database (no local proxy)" -ForegroundColor Gray
Write-Host "   - Running in optimized production mode" -ForegroundColor Gray
Write-Host ""

# Start production environment
Write-Host "🔨 Starting Docker containers..." -ForegroundColor Cyan
docker-compose -f docker-compose.prod.yml up --build -d

# Wait for container to be ready
Write-Host "⏳ Waiting for container to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check container status
Write-Host "🔍 Checking container status..." -ForegroundColor Cyan
docker-compose -f docker-compose.prod.yml ps

# Run migrations with Drizzle
Write-Host "📜 Applying latest schema with Drizzle..." -ForegroundColor Cyan
try {
    docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
} catch {
    Write-Host "⚠️  Could not run migrations automatically. You may need to run them manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Production environment started!" -ForegroundColor Green
Write-Host "   Application: http://localhost:3000" -ForegroundColor Yellow
Write-Host "   Container: acquisitions-app-prod" -ForegroundColor Yellow
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "   View logs: docker-compose -f docker-compose.prod.yml logs -f app" -ForegroundColor Gray
Write-Host "   Stop app:  docker-compose -f docker-compose.prod.yml down" -ForegroundColor Gray
Write-Host "   Status:    docker-compose -f docker-compose.prod.yml ps" -ForegroundColor Gray