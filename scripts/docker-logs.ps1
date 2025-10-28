# Docker logs and status script
# This script shows logs and status for both development and production environments

param(
    [Parameter()]
    [ValidateSet("dev", "prod", "both")]
    [string]$Environment = "both",
    
    [Parameter()]
    [switch]$Follow
)

Write-Host "📋 Docker Environment Status & Logs" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

$followFlag = if ($Follow) { "-f" } else { "" }

if ($Environment -eq "dev" -or $Environment -eq "both") {
    Write-Host "🔍 Development Environment:" -ForegroundColor Cyan
    Write-Host "----------------------------" -ForegroundColor Gray
    
    # Check if dev containers are running
    $devContainers = docker-compose -f docker-compose.dev.yml ps --services --filter "status=running"
    
    if ($devContainers) {
        Write-Host "Status:" -ForegroundColor Yellow
        docker-compose -f docker-compose.dev.yml ps
        
        Write-Host "`nLogs:" -ForegroundColor Yellow
        if ($Follow) {
            docker-compose -f docker-compose.dev.yml logs -f
        } else {
            docker-compose -f docker-compose.dev.yml logs --tail=50
        }
    } else {
        Write-Host "❌ No development containers running" -ForegroundColor Red
    }
    Write-Host ""
}

if ($Environment -eq "prod" -or $Environment -eq "both") {
    Write-Host "🔍 Production Environment:" -ForegroundColor Cyan
    Write-Host "---------------------------" -ForegroundColor Gray
    
    # Check if prod containers are running
    $prodContainers = docker-compose -f docker-compose.prod.yml ps --services --filter "status=running"
    
    if ($prodContainers) {
        Write-Host "Status:" -ForegroundColor Yellow
        docker-compose -f docker-compose.prod.yml ps
        
        Write-Host "`nLogs:" -ForegroundColor Yellow
        if ($Follow) {
            docker-compose -f docker-compose.prod.yml logs -f
        } else {
            docker-compose -f docker-compose.prod.yml logs --tail=50
        }
    } else {
        Write-Host "❌ No production containers running" -ForegroundColor Red
    }
}

if (-not $Follow) {
    Write-Host ""
    Write-Host "Usage examples:" -ForegroundColor Gray
    Write-Host "  .\scripts\docker-logs.ps1 -Environment dev -Follow    # Follow dev logs" -ForegroundColor Gray
    Write-Host "  .\scripts\docker-logs.ps1 -Environment prod           # Show prod status/logs" -ForegroundColor Gray
}