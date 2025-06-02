@echo off
echo ========================================
echo Starting BTCPay Server Development Environment
echo With Multi-Crypto Support (BTC + USDT TRC20/ERC20)
echo Using External TRON API (TronGrid)
echo ========================================

echo.
echo [INFO] Creating necessary directories...
if not exist "config\postgres" mkdir config\postgres

echo.
echo [INFO] Creating PostgreSQL initialization script...
echo CREATE DATABASE IF NOT EXISTS nbxplorer; > config\postgres\01-init.sql
echo CREATE DATABASE IF NOT EXISTS btcpayserver; >> config\postgres\01-init.sql
echo GRANT ALL PRIVILEGES ON DATABASE nbxplorer TO postgres; >> config\postgres\01-init.sql
echo GRANT ALL PRIVILEGES ON DATABASE btcpayserver TO postgres; >> config\postgres\01-init.sql

echo.
echo [1/5] Stopping any existing containers...
docker-compose -f docker-compose.dev.yml down

echo.
echo [2/5] Pulling latest images...
docker-compose -f docker-compose.dev.yml pull

echo.
echo [3/5] Starting core services (Database, Bitcoin, Redis)...
docker-compose -f docker-compose.dev.yml up -d postgres bitcoind redis

echo.
echo [4/5] Waiting for core services to initialize...
timeout /t 30 /nobreak > nul

echo.
echo [5/5] Starting Ethereum and NBXplorer...
docker-compose -f docker-compose.dev.yml up -d geth
timeout /t 15 /nobreak > nul
docker-compose -f docker-compose.dev.yml up -d nbxplorer

echo.
echo [INFO] Waiting for all services to be ready...
timeout /t 30 /nobreak > nul

echo.
echo ========================================
echo Service Health Check
echo ========================================

echo.
echo Checking PostgreSQL...
docker exec btcpay_postgres_regtest pg_isready -U postgres > nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PostgreSQL is ready
) else (
    echo ✗ PostgreSQL is not ready
    echo   Checking logs...
    docker logs btcpay_postgres_regtest --tail 5
)

echo.
echo Checking Redis...
docker exec btcpay_redis redis-cli -a btcpay123 ping > nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Redis is ready
) else (
    echo ✗ Redis is not ready
)

echo.
echo Checking Bitcoin Node...
curl -s -o nul -w "%%{http_code}" --user btcpay:btcpay123 --data-binary "{\"jsonrpc\":\"1.0\",\"id\":\"test\",\"method\":\"getblockchaininfo\",\"params\":[]}" -H "content-type: text/plain;" http://localhost:18443/ > temp_btc.txt 2>nul
set /p btc_status=<temp_btc.txt
del temp_btc.txt > nul 2>&1
if "%btc_status%"=="200" (
    echo ✓ Bitcoin Node is ready
) else (
    echo ✗ Bitcoin Node is not ready ^(Status: %btc_status%^)
)

echo.
echo Checking External TRON API...
curl -s -o nul -w "%%{http_code}" https://api.trongrid.io/wallet/getnowblock > temp_tron.txt 2>nul
set /p tron_status=<temp_tron.txt
del temp_tron.txt > nul 2>&1
if "%tron_status%"=="200" (
    echo ✓ External TRON API is accessible
) else (
    echo ✗ External TRON API is not accessible ^(Status: %tron_status%^)
    echo   Note: Check internet connection
)

echo.
echo Checking Ethereum Node...
curl -s -o nul -w "%%{http_code}" -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" http://localhost:8545 > temp_eth.txt 2>nul
set /p eth_status=<temp_eth.txt
del temp_eth.txt > nul 2>&1
if "%eth_status%"=="200" (
    echo ✓ Ethereum Node is ready
) else (
    echo ✗ Ethereum Node is not ready ^(Status: %eth_status%^)
    echo   Note: Ethereum node may take time to sync
)

echo.
echo Checking NBXplorer...
curl -s -o nul -w "%%{http_code}" http://localhost:32838/v1/health > temp_nbx.txt 2>nul
set /p nbx_status=<temp_nbx.txt
del temp_nbx.txt > nul 2>&1
if "%nbx_status%"=="200" (
    echo ✓ NBXplorer is ready
) else (
    echo ✗ NBXplorer is not ready ^(Status: %nbx_status%^)
    echo   Checking NBXplorer logs...
    docker logs btcpay_nbxplorer_regtest --tail 5
)

echo.
echo ========================================
echo Environment Status Summary
echo ========================================
echo.
echo ✅ Core Services:
echo   • PostgreSQL Database: localhost:39372
echo   • Redis Cache:         localhost:6379
echo.
echo 🔗 Blockchain Services:
echo   • Bitcoin RPC:         localhost:18443 ^(regtest^)
echo   • TRON API:            https://api.trongrid.io ^(external^)
echo   • Ethereum JSON-RPC:   http://localhost:8545 ^(mainnet^)
echo   • Ethereum WebSocket:  ws://localhost:8546
echo.
echo 🔍 Block Explorer:
echo   • NBXplorer API:       http://localhost:32838
echo.
echo 💰 Supported Payment Methods:
echo   ✓ Bitcoin (BTC) - Native SegWit
echo   ✓ Bitcoin Lightning Network  
echo   ✓ USDT TRC20 (via external TronGrid API)
echo   ✓ USDT ERC20 (Ethereum Network)
echo.
echo 🚀 Next Steps:
echo   1. Start BTCPay Server from Visual Studio
echo   2. Access BTCPay Server at: http://localhost:14142
echo   3. Install USDT Plugin:
echo      - Go to Settings ^> Plugins ^> Available Plugins
echo      - Install "BTCPayServer.Plugins.USDt"
echo      - Restart BTCPay Server
echo   4. Configure payment methods in Store Settings
echo.
echo 📋 Configuration Endpoints for BTCPay Server:
echo   • TRON API:             https://api.trongrid.io
echo   • Ethereum RPC:         http://localhost:8545
echo   • Database Connection:  postgres://postgres:postgres@localhost:39372/btcpayserver
echo.
echo 🔧 Development Tools:
echo   • View logs: docker-compose -f docker-compose.dev.yml logs [service_name]
echo   • Stop all:  docker-compose -f docker-compose.dev.yml down
echo   • Rebuild:   docker-compose -f docker-compose.dev.yml up --build -d
echo.
echo ⚠️  Important Notes:
echo   • TRON uses external API ^(no local sync required^)
echo   • Ethereum node needs time to sync for local development
echo   • For production: use your own TRON RPC endpoint
echo   • Monitor API rate limits for external TRON service
echo.

echo Press any key to continue...
pause > nul

echo.
echo 🎯 Quick Test Commands:
echo.
echo Test Bitcoin RPC:
echo curl --user btcpay:btcpay123 --data-binary "{\"jsonrpc\":\"1.0\",\"id\":\"test\",\"method\":\"getblockchaininfo\",\"params\":[]}" -H "content-type: text/plain;" http://localhost:18443/
echo.
echo Test TRON API ^(external^):
echo curl -X POST https://api.trongrid.io/wallet/getnowblock
echo.
echo Test Ethereum RPC:
echo curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" http://localhost:8545
echo.
echo Test NBXplorer:
echo curl http://localhost:32838/v1/health
echo.

pause