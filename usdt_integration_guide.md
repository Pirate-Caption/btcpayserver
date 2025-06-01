# BTCPay Server USDT 集成配置指南

## 概述

本指南将帮助你在BTCPay Server中配置USDT支付支持，包括TRC20和ERC20网络。

## 支持的支付方式

### ✅ 已配置支持
- **Bitcoin (BTC)** - 原生 SegWit 和 Lightning Network
- **USDT TRC20** - TRON 网络 (低手续费)
- **USDT ERC20** - 以太坊网络
- **Liquid USDT** - Blockstream Liquid 侧链

## 快速开始

### 1. 启动开发环境

```bash
# 运行启动脚本
start-dev-environment.bat

# 或者手动启动
docker-compose -f docker-compose.dev.yml up -d
```

### 2. 验证服务状态

访问以下端点确认服务正常运行：

- **PostgreSQL**: `localhost:39372`
- **Bitcoin RPC**: `http://localhost:18443` (用户名: btcpay, 密码: btcpay123)
- **TRON API**: `http://localhost:8090`
- **Ethereum RPC**: `http://localhost:8545`
- **NBXplorer**: `http://localhost:32838`

### 3. 安装USDT插件

1. 启动BTCPay Server (通过Visual Studio)
2. 登录管理后台: `http://localhost:14142`
3. 导航到 **Settings** > **Plugins** > **Available Plugins**
4. 搜索并安装 `BTCPayServer.Plugins.USDt`
5. 重启BTCPay Server

## 详细配置

### TRC20 USDT 配置

1. **创建TRON钱包**
   ```bash
   # 使用 TronLink, Trust Wallet, 或 Ledger
   # 生成用于接收USDT的TRON地址
   ```

2. **配置支付方法**
   - Store Settings > Payment Methods
   - 添加 "USDT-TRON" 支付方法
   - RPC端点: `http://localhost:8090`
   - 输入你的TRON钱包地址

3. **测试配置**
   ```bash
   # 测试TRON连接
   curl -X POST http://localhost:8090/wallet/getnowblock
   ```

### ERC20 USDT 配置

1. **配置以太坊钱包**
   - 使用 MetaMask, Ledger 或其他以太坊钱包
   - 获取用于接收USDT的以太坊地址

2. **配置NBXplorer**
   - 以太坊RPC已在docker-compose中配置
   - USDT合约地址: `0xdAC17F958D2ee523a2206206994597C13D831ec7` (主网)

3. **测试以太坊连接**
   ```bash
   curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
     http://localhost:8545
   ```

### Liquid USDT 配置 (推荐用于低手续费)

1. **启用Liquid支持**
   - 在BTCPay Server中启用Liquid Bitcoin
   - 这会自动启用Liquid USDT支持

2. **配置Liquid钱包**
   - 下载 Blockstream Green
   - 创建Liquid钱包
   - 获取Liquid地址用于接收L-USDT

## 网络选择建议

### 开发环境
- **Bitcoin**: Regtest (快速确认)
- **TRON**: Shasta Testnet 或 Nile Testnet
- **Ethereum**: Goerli 或 Sepolia Testnet

### 生产环境
- **Bitcoin**: Mainnet
- **TRON**: Mainnet
- **Ethereum**: Mainnet
- **Liquid**: Mainnet

## 手续费对比

| 网络 | 平均手续费 | 确认时间 | 适用场景 |
|------|------------|----------|----------|
| TRC20 | ~$1 | 3秒 | 小额支付 |
| ERC20 | $5-50 | 15秒-5分钟 | 大额支付 |
| Liquid | ~$0.10 | 1分钟 | 平衡选择 |

## 故障排除

### 常见问题

1. **TRON节点同步慢**
   ```bash
   # 检查同步状态
   curl http://localhost:8090/wallet/getnowblock
   
   # 查看日志
   docker logs btcpay_tron_node
   ```

2. **以太坊节点内存不足**
   ```bash
   # 增加缓存大小 (在docker-compose.yml中)
   --cache=2048
   ```

3. **NBXplorer连接失败**
   ```bash
   # 检查NBXplorer日志
   docker logs btcpay_nbxplorer_regtest
   
   # 重启NBXplorer
   docker-compose restart nbxplorer
   ```

### 性能优化

1. **磁盘空间管理**
   ```bash
   # 启用区块链剪枝 (Bitcoin)
   # 在bitcoin.conf中添加: prune=5000
   
   # 监控磁盘使用
   docker system df
   ```

2. **内存优化**
   ```bash
   # 为高内存使用的服务分配更多内存
   # 在docker-compose.yml中调整:
   deploy:
     resources:
       limits:
         memory: 4G
   ```

## 生产部署注意事项

### 安全配置

1. **网络安全**
   - 使用防火墙限制端口访问
   - 启用SSL/TLS加密
   - 定期更新容器镜像

2. **密钥管理**
   - 使用硬件钱包存储私钥
   - 定期备份钱包种子词
   - 实施多重签名

3. **监控和备份**
   - 设置服务监控告警
   - 定期备份数据库
   - 监控区块链同步状态

### 扩展性考虑

1. **使用外部RPC提供商**
   ```yaml
   # 生产环境建议使用外部RPC
   # TRON: https://api.trongrid.io
   # Ethereum: Infura, Alchemy, QuickNode
   ```

2. **负载均衡**
   - 为高流量场景配置多个RPC端点
   - 使用Redis进行会话管理和缓存

## 测试检查清单

- [ ] Bitcoin节点正常运行并同步
- [ ] TRON节点API响应正常
- [ ] 以太坊节点同步并响应RPC调用
- [ ] NBXplorer连接所有区块链节点
- [ ] PostgreSQL数据库连接正常
- [ ] USDT插件安装并激活
- [ ] 创建测试发票包含USDT支付选项
- [ ] 使用测试网代币完成支付流程
- [ ] 验证支付状态更新

## 支持资源

- **BTCPay Server文档**: https://docs.btcpayserver.org/
- **USDT插件GitHub**: https://github.com/btcpayserver-tether/BTCPayServer.Plugins.USDt
- **TRON开发者文档**: https://developers.tron.network/
- **以太坊开发者文档**: https://ethereum.org/developers/

## 联系支持

如果遇到问题，可以通过以下渠道寻求帮助：

- **BTCPay Server社区**: https://chat.btcpayserver.org/
- **GitHub Issues**: https://github.com/btcpayserver/btcpayserver/issues
- **USDT插件支持**: https://github.com/btcpayserver-tether/BTCPayServer.Plugins.USDt/issues

## 开发工具和实用命令

### Docker 管理命令

```bash
# 查看所有容器状态
docker-compose -f docker-compose.dev.yml ps

# 查看服务日志
docker-compose -f docker-compose.dev.yml logs [service_name]

# 重启特定服务
docker-compose -f docker-compose.dev.yml restart [service_name]

# 完全重建环境
docker-compose -f docker-compose.dev.yml down -v
docker-compose -f docker-compose.dev.yml up --build -d

# 进入容器进行调试
docker exec -it btcpay_tron_node bash
docker exec -it btcpay_geth_mainnet geth attach http://localhost:8545
```

### 区块链交互命令

```bash
# Bitcoin CLI 命令
docker exec btcpay_bitcoind_regtest bitcoin-cli -regtest -rpcuser=btcpay -rpcpassword=btcpay123 getblockchaininfo

# 生成测试区块 (regtest)
docker exec btcpay_bitcoind_regtest bitcoin-cli -regtest -rpcuser=btcpay -rpcpassword=btcpay123 generatetoaddress 10 [address]

# TRON API 测试
curl -X POST http://localhost:8090/wallet/getaccount -d '{"address":"TRX_ADDRESS_HERE"}'

# 以太坊余额查询
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0xETH_ADDRESS_HERE","latest"],"id":1}' http://localhost:8545
```

### 数据库管理

```bash
# 连接PostgreSQL
docker exec -it btcpay_postgres_regtest psql -U postgres -d btcpayserver

# 查看NBXplorer数据
docker exec -it btcpay_postgres_regtest psql -U postgres -d nbxplorer -c "SELECT * FROM transactions LIMIT 10;"

# 备份数据库
docker exec btcpay_postgres_regtest pg_dump -U postgres btcpayserver > backup_$(date +%Y%m%d).sql
```

## 高级配置

### 自定义USDT合约配置

如果需要支持其他TRC20或ERC20代币，可以修改配置：

```json
// TRC20代币配置示例
{
  "contractAddress": "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", // USDT TRC20
  "decimals": 6,
  "symbol": "USDT",
  "name": "Tether USD"
}

// ERC20代币配置示例  
{
  "contractAddress": "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT ERC20
  "decimals": 6,
  "symbol": "USDT", 
  "name": "Tether USD"
}
```

### 多环境配置

创建不同环境的配置文件：

```bash
# 开发环境
docker-compose -f docker-compose.dev.yml up -d

# 测试环境  
docker-compose -f docker-compose.test.yml up -d

# 生产环境
docker-compose -f docker-compose.prod.yml up -d
```

### 负载均衡和高可用

```yaml
# nginx 负载均衡配置示例
upstream btcpay_backend {
    server btcpay_server_1:5000;
    server btcpay_server_2:5000;
    server btcpay_server_3:5000;
}

upstream tron_rpc {
    server tron_node_1:8090;
    server tron_node_2:8090;
    server api.trongrid.io:443;
}
```

## 监控和告警

### Prometheus 监控配置

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'btcpay-server'
    static_configs:
      - targets: ['localhost:14142']
  
  - job_name: 'nbxplorer'
    static_configs:
      - targets: ['localhost:32838']
```

### 关键指标监控

- **区块链同步状态**
- **交易处理时间**  
- **RPC响应时间**
- **数据库连接数**
- **内存和CPU使用率**
- **磁盘空间使用**

## 常见错误及解决方案

### 1. TRON节点启动失败

```bash
# 错误: Java heap space
# 解决: 增加JVM内存
environment:
  - JAVA_OPTS=-Xmx4g -XX:+UseG1GC
```

### 2. 以太坊同步慢

```bash
# 使用快照同步模式
--syncmode=snap
# 或使用外部RPC提供商
NBXPLORER_ETHRPCURL: https://mainnet.infura.io/v3/YOUR_PROJECT_ID
```

### 3. NBXplorer连接超时

```bash
# 增加超时时间
NBXPLORER_RPCREADWRITETIMEOUT: 300
# 检查防火墙设置
```

### 4. 数据库连接池耗尽

```bash
# 增加最大连接数
postgres -c max_connections=500
# 优化连接池配置
```

## 性能调优建议

### 1. 系统资源分配

| 服务 | 最小内存 | 推荐内存 | 最小磁盘 | 推荐磁盘 |
|------|----------|----------|----------|----------|
| Bitcoin节点 | 2GB | 4GB | 500GB | 1TB |
| TRON节点 | 4GB | 8GB | 200GB | 500GB |
| 以太坊节点 | 8GB | 16GB | 750GB | 2TB |
| PostgreSQL | 1GB | 4GB | 50GB | 200GB |
| NBXplorer | 1GB | 2GB | 10GB | 50GB |

### 2. 网络优化

```yaml
# Docker网络优化
networks:
  btcpay_network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "true"
      com.docker.network.bridge.enable_ip_masquerade: "true"
      com.docker.network.driver.mtu: "1500"
```

### 3. 存储优化

```yaml
# 使用SSD存储卷
volumes:
  bitcoin_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/ssd/bitcoin_data
```

## 安全最佳实践

### 1. 网络安全

```bash
# 防火墙配置
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP  
ufw allow 443/tcp     # HTTPS
ufw allow 9735/tcp    # Lightning
ufw deny 18443/tcp    # Bitcoin RPC (仅内部)
ufw deny 8090/tcp     # TRON API (仅内部)
ufw deny 8545/tcp     # Ethereum RPC (仅内部)
```

### 2. 访问控制

```yaml
# 使用环境变量管理敏感信息
environment:
  - BITCOIN_RPC_USER=${BITCOIN_RPC_USER}
  - BITCOIN_RPC_PASSWORD=${BITCOIN_RPC_PASSWORD}
  - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
  - TRON_API_KEY=${TRON_API_KEY}
```

### 3. 备份策略

```bash
#!/bin/bash
# 自动备份脚本
DATE=$(date +%Y%m%d_%H%M%S)

# 备份数据库
docker exec btcpay_postgres_regtest pg_dump -U postgres btcpayserver > backup_db_$DATE.sql

# 备份配置文件
tar -czf backup_config_$DATE.tar.gz docker-compose.dev.yml config/

# 上传到云存储
aws s3 cp backup_db_$DATE.sql s3://your-backup-bucket/
```

## 部署检查清单

### 部署前检查

- [ ] 服务器资源满足最低要求
- [ ] 域名和SSL证书配置完成
- [ ] 防火墙规则正确设置
- [ ] 备份策略已实施
- [ ] 监控系统已配置

### 部署后验证

- [ ] 所有服务正常启动
- [ ] 区块链节点同步完成
- [ ] BTCPay Server Web界面可访问
- [ ] 支付流程端到端测试通过
- [ ] 备份和恢复流程验证
- [ ] 监控告警正常工作

---

*本指南最后更新时间: 2025年6月*

*如有任何问题或建议，请通过GitHub Issues或社区论坛联系我们。*