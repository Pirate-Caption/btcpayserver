@echo off
echo ========================================
echo Starting BTCPay Server Development Environment
echo With Multi-Crypto Support (BTC + USDT TRC20/ERC20)
echo ========================================

echo.
echo [INFO] Creating necessary directories...
if not exist "config\postgres" mkdir config\postgres
if not exist "config\tron" mkdir config\tron
if not exist "config\nginx" mkdir config\nginx
if not exist "contracts" mkdir contracts

echo.
echo [INFO] Creating PostgreSQL initialization script...
echo CREATE DATABASE IF NOT EXISTS nbxplorer; > config\postgres\01-init.sql
echo CREATE DATABASE IF NOT EXISTS btcpayserver; >> config\postgres\01-init.sql
echo GRANT ALL PRIVILEGES ON DATABASE nbxplorer TO postgres; >> config\postgres\01-init.sql
echo GRANT ALL PRIVILEGES ON DATABASE btcpayserver TO postgres; >> config\postgres\01-init.sql

echo.
echo [1/7] Stopping any existing containers...
docker-compose -f docker-compose.dev.yml down

echo.
echo [2/7] Pulling latest images...
docker-compose -f docker-compose.dev.yml pull

echo.
echo [3/7] Starting core services (Database, Bitcoin)...
docker-compose -f docker-compose.dev.yml up -d postgres bitcoind redis

echo.
echo [4/7] Waiting for core services to initialize...
timeout /t 30 /nobreak > nul

echo.
echo [5/7] Starting blockchain nodes (TRON, Ethereum)...
docker-compose -f docker-compose.dev.yml up -d tron-node geth

echo.
echo [6/7] Waiting for blockchain nodes...
timeout /t 45 /nobreak > nul

echo.
echo [7/7] Starting NBXplorer...
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
docker exec btcpay_postgres_regtest pg_isready -U postgres
if %errorlevel% equ 0 (
    echo ✓ PostgreSQL is ready
) else (
    echo ✗ PostgreSQL is not ready
    echo   Checking logs...
    docker logs btcpay_postgres_regtest --tail 10
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
curl -s -o nul -w "%%{http_code}" --user btcpay:btcpay123 --data-binary "{\"jsonrpc\":\"1.0\",\"id\":\"test\",\"method\":\"getblockchaininfo\",\"params\":[]}" -H "content-type: text/plain;" http://localhost:18443/ > temp_btc.txt
set /p btc_status=<temp_btc.txt
del temp_btc.txt
if "%btc_status%"=="200" (
    echo ✓ Bitcoin Node is ready
) else (
    echo ✗ Bitcoin Node is not ready ^(Status: %btc_status%^)
)

echo.
echo Checking TRON Node...
curl -s -o nul -w "%%{http_code}" http://localhost:8090/wallet/getnowblock > temp_tron.txt
set /p tron_status=<temp_tron.txt
del temp_tron.txt
if "%tron_status%"=="200" (
    echo ✓ TRON Node is ready
) else (
    echo ✗ TRON Node is not ready ^(Status: %tron_status%^)
    echo   Note: TRON node may take several minutes to sync
)

echo.
echo Checking Ethereum Node...
curl -s -o nul -w "%%{http_code}" -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" http://localhost:8545 > temp_eth.txt
set /p eth_status=<temp_eth.txt
del temp_eth.txt
if "%eth_status%"=="200" (
    echo ✓ Ethereum Node is ready
) else (
    echo ✗ Ethereum Node is not ready ^(Status: %eth_status%^)
    echo   Note: Ethereum node may take time to sync
)

echo.
echo Checking NBXplorer...
curl -s -o nul -w "%%{http_code}" http://localhost:32838/v1/health > temp_nbx.txt
set /p nbx_status=<temp_nbx.txt
del temp_nbx.txt
if "%nbx_status%"=="200" (
    echo ✓ NBXplorer is ready
) else (
    echo ✗ NBXplorer is not ready ^(Status: %nbx_status%^)
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
echo 🔗 Blockchain Nodes:
echo   • Bitcoin RPC:         localhost:18443 ^(regtest^)
echo   • TRON HTTP API:       http://localhost:8090
echo   • TRON gRPC API:       localhost:8091
echo   • Ethereum JSON-RPC:   http://localhost:8545
echo   • Ethereum WebSocket:  ws://localhost:8546
echo.
echo 🔍 Block Explorers:
echo   • NBXplorer API:       http://localhost:32838
echo.
echo 💰 Supported Payment Methods:
echo   ✓ Bitcoin (BTC) - Native SegWit
echo   ✓ Bitcoin Lightning Network  
echo   ✓ USDT TRC20 (TRON Network)
echo   ✓ USDT ERC20 (Ethereum Network)
echo   ✓ Liquid Bitcoin ^(L-BTC^)
echo   ✓ Liquid Tether ^(L-USDT^)
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
echo 📋 Configuration Endpoints:
echo   • TRON RPC for plugin:  http://localhost:8090
echo   • Ethereum RPC:         http://localhost:8545
echo   • Database Connection:  postgres://postgres:postgres@localhost:39372/btcpayserver
echo.
echo 🔧 Development Tools:
echo   • View logs: docker-compose -f docker-compose.dev.yml logs [service_name]
echo   • Stop all:  docker-compose -f docker-compose.dev.yml down
echo   • Rebuild:   docker-compose -f docker-compose.dev.yml up --build -d
echo.
echo ⚠️  Important Notes:
echo   • TRON and Ethereum nodes need time to sync
echo   • Use testnet/regtest for development
echo   • Monitor disk space - blockchain data grows over time
echo   • For production: switch to mainnet and use external RPC providers
echo.

echo Press any key to continue...
pause > nul

echo.
echo 🎯 Quick Test Commands:
echo.
echo Test Bitcoin RPC:
echo curl --user btcpay:btcpay123 --data-binary "{\"jsonrpc\":\"1.0\",\"id\":\"test\",\"method\":\"getblockchaininfo\",\"params\":[]}" -H "content-type: text/plain;" http://localhost:18443/
echo.
echo Test TRON API:
echo curl -X POST http://localhost:8090/wallet/getnowblock
echo.
echo Test Ethereum RPC:
echo curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" http://localhost:8545
echo.
echo Test NBXplorer:
echo curl http://localhost:32838/v1/health
echo.

pause