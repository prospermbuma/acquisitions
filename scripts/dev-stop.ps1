# Stop development environment script
# This script stops the development containers and cleans up

Write-Host "🛑 Stopping Development Environment" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow
Write-Host ""

# Stop and remove containers
Write-Host "📦 Stopping development containers..." -ForegroundColor Cyan
docker-compose -f docker-compose.dev.yml down

# Optional: Remove volumes (uncomment if you want to clean up data)
# Write-Host "🧹 Removing volumes..." -ForegroundColor Cyan
# docker-compose -f docker-compose.dev.yml down -v

Write-Host ""
Write-Host "✅ Development environment stopped!" -ForegroundColor Green
Write-Host "   Ephemeral database branch has been automatically deleted" -ForegroundColor Gray