# Stop production environment script
# This script stops the production containers

Write-Host "🛑 Stopping Production Environment" -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow
Write-Host ""

# Stop and remove containers
Write-Host "📦 Stopping production containers..." -ForegroundColor Cyan
docker-compose -f docker-compose.prod.yml down

Write-Host ""
Write-Host "✅ Production environment stopped!" -ForegroundColor Green
Write-Host "   Production database remains intact in Neon Cloud" -ForegroundColor Gray