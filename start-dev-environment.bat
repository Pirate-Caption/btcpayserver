@echo off
echo ========================================
echo Starting BTCPay Server Development Environment
echo ========================================

echo.
echo [1/4] Starting Docker services...
docker-compose -f docker-compose.dev.yml up -d

echo.
echo [2/4] Waiting for services to initialize...
timeout /t 30 /nobreak > nul

echo.
echo [3/4] Creating databases if they don't exist...
docker exec btcpay_postgres_regtest psql -U postgres -c "CREATE DATABASE IF NOT EXISTS nbxplorer;" 2>nul

echo.
echo [4/4] Checking service health...
echo Checking PostgreSQL...
docker exec btcpay_postgres_regtest pg_isready -U postgres
if %errorlevel% equ 0 (
    echo ✓ PostgreSQL is ready
) else (
    echo ✗ PostgreSQL is not ready
)

echo.
echo Checking NBXplorer...
curl -s -o nul -w "%%{http_code}" http://localhost:32838/v1/health > temp_status.txt
set /p status=<temp_status.txt
del temp_status.txt
if "%status%"=="200" (
    echo ✓ NBXplorer is ready
) else (
    echo ✗ NBXplorer is not ready ^(Status: %status%^)
)

echo.
echo ========================================
echo Development environment is ready!
echo ========================================
echo.
echo Services:
echo   • PostgreSQL: localhost:39372
echo   • NBXplorer:  http://localhost:32838
echo   • Bitcoin RPC: localhost:18443
echo.
echo You can now start BTCPay Server from Visual Studio
echo Access BTCPay Server at: http://localhost:14142
echo.
pause