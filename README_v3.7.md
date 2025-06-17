# FinTech eBPF Demo v3.7

## 🎯 版本概述

FinTech eBPF Demo v3.7 是一个完全修复和优化的版本，解决了从 v1.0 到 v3.7 过程中发现的所有关键问题。

## 🔥 v3.7 关键修复

### 1. React createContext 错误修复
- **问题**: React.createContext 在某些环境下不可用
- **修复**: 在 main.tsx 中添加 React 可用性检查和全局暴露
- **影响**: 解决了 antd 组件无法正常工作的问题

### 2. Vite 配置优化
- **React 模块去重**: 使用 `dedupe: ['react', 'react-dom']`
- **别名配置**: 确保 React 从单一来源加载
- **依赖预构建**: 强制重新预构建依赖 `force: true`
- **Chunk 分割优化**: 更精确的代码分割策略

### 3. 依赖版本统一
- **React Types**: 升级到 v19.0.0 兼容版本
- **Ant Design**: 升级到 v5.26.0 稳定版本
- **Icons**: 升级到 v6.0.0 最新版本

### 4. 构建流程改进
- **清理脚本**: 添加 `clean` 和 `fresh-install` 命令
- **缓存清理**: 自动清理 `.vite` 缓存目录
- **依赖重装**: 强制重新安装所有依赖

## 📦 快速开始

### 前置要求
- Node.js >= 18.0.0
- Docker & Docker Compose
- Kubernetes 集群
- Helm >= 3.0

### 1. 克隆项目
```bash
git clone <repository-url>
cd fintech-ebpf-demo
```

### 2. 构建镜像
```bash
# 构建所有服务的 v3.7 镜像
./build-v3.7.sh
```

### 3. 部署到 Kubernetes
```bash
# 部署到 Kubernetes 集群
./deploy-v3.7.sh
```

### 4. 验证部署
```bash
# 查看 Pod 状态
kubectl get pods -n fintech-demo

# 端口转发访问前端
kubectl port-forward svc/frontend-service 3000:80 -n fintech-demo

# 访问应用
open http://localhost:3000
```

## 🏗️ 架构组件

### 前端 (React + TypeScript)
- **版本**: 3.7.0
- **技术栈**: React 18, Ant Design 5.26, Vite 5
- **特性**: 
  - 完整的错误边界处理
  - React 模块加载修复
  - 优化的构建配置
  - 调试工具集成

### 后端微服务
- **trading-api**: 交易API服务 (端口: 8080)
- **risk-engine**: 风险引擎 (端口: 8081)
- **payment-gateway**: 支付网关 (端口: 8082)
- **audit-service**: 审计服务 (端口: 8083)

### 数据存储
- **PostgreSQL**: 主数据库
- **Redis**: 缓存和会话存储

## 🔧 开发指南

### 前端开发
```bash
cd frontend

# 清理并重新安装依赖 (v3.7 关键步骤)
npm run clean
npm run fresh-install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build

# 类型检查
npm run type-check
```

### 后端开发
```bash
cd backend/<service-name>

# 构建镜像
docker build -t fintech-demo/<service>:v3.7 .

# 运行容器
docker run -p 8080:8080 fintech-demo/<service>:v3.7
```

## 🐛 故障排除

### 前端问题

#### React createContext 错误
```bash
# 症状: Cannot read property 'createContext' of undefined
# 解决: 清理依赖并重新安装
cd frontend
npm run clean
npm run fresh-install
```

#### Vite 构建错误
```bash
# 症状: Module resolution errors
# 解决: 清理 Vite 缓存
rm -rf .vite node_modules/.vite
npm install
```

#### 依赖冲突
```bash
# 症状: Peer dependency warnings
# 解决: 使用 npm 的 overrides 功能
npm install --legacy-peer-deps
```

### 后端问题

#### 镜像拉取失败
```bash
# 检查镜像是否存在
docker pull quay.io/s0926760809/fintech-demo/frontend:v3.7

# 检查认证
docker login quay.io
```

#### Pod 启动失败
```bash
# 查看 Pod 详情
kubectl describe pod <pod-name> -n fintech-demo

# 查看日志
kubectl logs <pod-name> -n fintech-demo
```

## 📊 监控和调试

### 前端调试
```javascript
// 浏览器控制台中可用的调试工具
window.debugApp.checkReact()        // 检查 React 状态
window.debugApp.triggerError()      // 触发测试错误
window.debugApp.getAppConfig()      // 获取应用配置
```

### 后端监控
```bash
# 健康检查
curl http://localhost:8083/health

# 指标监控
curl http://localhost:8083/metrics

# 审计日志
kubectl logs -f deployment/audit-service -n fintech-demo
```

## 🔒 安全特性

### eBPF 集成
- 系统调用监控
- 网络流量分析
- 安全事件检测

### 审计日志
- 所有交易记录
- 用户操作追踪
- 安全事件日志

## 📈 性能优化

### 前端优化
- **代码分割**: 按需加载组件
- **缓存策略**: 静态资源缓存
- **Bundle 分析**: 使用 `npm run analyze`

### 后端优化
- **连接池**: 数据库连接优化
- **缓存层**: Redis 缓存策略
- **负载均衡**: Kubernetes 服务发现

## 🚀 部署选项

### 开发环境
```bash
# 本地开发
docker-compose up -d

# 前端开发服务器
cd frontend && npm run dev
```

### 生产环境
```bash
# Kubernetes 部署
./deploy-v3.7.sh

# 或手动部署
helm install fintech-demo k8s/helm/fintech-chart -n fintech-demo
```

## 📝 版本历史

### v3.7.0 (当前版本)
- ✅ 修复 React createContext 错误
- ✅ 优化 Vite 配置
- ✅ 统一依赖版本
- ✅ 改进构建流程
- ✅ 完善错误处理

### v3.0.0
- 基础功能实现
- 微服务架构
- Kubernetes 部署

### v1.0.0
- 初始版本
- 基本交易功能

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支: `git checkout -b feature/amazing-feature`
3. 提交更改: `git commit -m 'Add amazing feature'`
4. 推送分支: `git push origin feature/amazing-feature`
5. 创建 Pull Request

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 📞 支持

- 📧 Email: support@fintech-demo.com
- 📖 文档: [docs.fintech-demo.com](https://docs.fintech-demo.com)
- 🐛 问题报告: [GitHub Issues](https://github.com/fintech-security/ebpf-demo/issues)

---

**🎉 FinTech eBPF Demo v3.7 - 稳定、可靠、生产就绪！** 