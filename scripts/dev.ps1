# Development startup script for Acquisition App with Neon Local
# This script starts the application in development mode with Neon Local

Write-Host "🚀 Starting Acquisition App in Development Mode" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

# Check if .env.development exists
if (-Not (Test-Path ".env.development")) {
    Write-Host "❌ Error: .env.development file not found!" -ForegroundColor Red
    Write-Host "   Please copy .env.development from the template and update with your Neon credentials." -ForegroundColor Yellow
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

# Create .neon_local directory if it doesn't exist
if (-Not (Test-Path ".neon_local")) {
    New-Item -ItemType Directory -Path ".neon_local" | Out-Null
    Write-Host "✅ Created .neon_local directory" -ForegroundColor Green
}

# Add .neon_local to .gitignore if not already present
$gitignoreContent = ""
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw
}

if ($gitignoreContent -notmatch "\.neon_local/") {
    Add-Content -Path ".gitignore" -Value "`n.neon_local/"
    Write-Host "✅ Added .neon_local/ to .gitignore" -ForegroundColor Green
}

Write-Host "📦 Building and starting development containers..." -ForegroundColor Cyan
Write-Host "   - Neon Local proxy will create an ephemeral database branch" -ForegroundColor Gray
Write-Host "   - Application will run with hot reload enabled" -ForegroundColor Gray
Write-Host ""

# Start development environment
Write-Host "🔨 Starting Docker containers..." -ForegroundColor Cyan
docker-compose -f docker-compose.dev.yml up --build

Write-Host ""
Write-Host "🎉 Development environment started!" -ForegroundColor Green
Write-Host "   Application: http://localhost:3000" -ForegroundColor Yellow
Write-Host "   Database: postgres://neon:npg@localhost:5432/neondb" -ForegroundColor Yellow
Write-Host ""
Write-Host "To stop the environment, press Ctrl+C or run: docker-compose -f docker-compose.dev.yml down" -ForegroundColor Gray