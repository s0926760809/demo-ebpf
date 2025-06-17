#!/bin/bash

# FinTech eBPF Demo v3.7 构建脚本
# 构建并推送所有微服务镜像到 quay.io

set -e

# 配置
REGISTRY="quay.io/s0926760809/fintech-demo"
VERSION="v3.7"
SERVICES=("trading-api" "risk-engine" "payment-gateway" "audit-service" "frontend")

echo "🚀 开始构建 FinTech eBPF Demo v3.7 镜像..."
echo "📦 Registry: $REGISTRY"
echo "🏷️  Version: $VERSION"
echo "🔧 Services: ${SERVICES[*]}"

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行或无权限访问"
    echo "💡 尝试运行: sudo chmod 666 /var/run/docker.sock"
    exit 1
fi

# 构建后端服务
echo ""
echo "🔨 构建后端服务..."
for service in "trading-api" "risk-engine" "payment-gateway" "audit-service"; do
    echo ""
    echo "📦 构建 $service..."
    
    cd backend/$service
    
    # 构建镜像
    docker build -t $REGISTRY/$service:$VERSION .
    
    # 推送镜像
    echo "📤 推送 $service:$VERSION..."
    docker push $REGISTRY/$service:$VERSION
    
    # 标记为latest
    docker tag $REGISTRY/$service:$VERSION $REGISTRY/$service:latest
    docker push $REGISTRY/$service:latest
    
    echo "✅ $service 构建完成"
    cd ../..
done

# 构建前端
echo ""
echo "🔨 构建前端..."
cd frontend

# 清理并重新安装依赖（v3.7关键步骤）
echo "🧹 清理前端依赖..."
rm -rf node_modules package-lock.json dist .vite

echo "📦 安装前端依赖..."
npm install

# 构建前端
echo "🏗️  构建前端应用..."
npm run build

# 构建Docker镜像
echo "🐳 构建前端Docker镜像..."
docker build -t $REGISTRY/frontend:$VERSION .

# 推送镜像
echo "📤 推送前端镜像..."
docker push $REGISTRY/frontend:$VERSION

# 标记为latest
docker tag $REGISTRY/frontend:$VERSION $REGISTRY/frontend:latest
docker push $REGISTRY/frontend:latest

echo "✅ 前端构建完成"
cd ..

# 显示构建结果
echo ""
echo "🎉 所有镜像构建完成！"
echo ""
echo "📋 构建的镜像:"
for service in "${SERVICES[@]}"; do
    echo "  - $REGISTRY/$service:$VERSION"
done

echo ""
echo "🔍 验证镜像:"
for service in "${SERVICES[@]}"; do
    if docker images | grep -q "$REGISTRY/$service.*$VERSION"; then
        echo "  ✅ $service:$VERSION"
    else
        echo "  ❌ $service:$VERSION"
    fi
done

echo ""
echo "📝 下一步:"
echo "  1. 更新 Helm values.yaml 中的镜像标签为 $VERSION"
echo "  2. 运行: helm upgrade fintech-demo k8s/helm/fintech-chart -n fintech-demo"
echo "  3. 验证部署: kubectl get pods -n fintech-demo"

echo ""
echo "🔧 调试命令:"
echo "  - 查看镜像: docker images | grep $REGISTRY"
echo "  - 测试镜像: docker run --rm $REGISTRY/frontend:$VERSION"
echo "  - 清理镜像: docker rmi \$(docker images $REGISTRY/* -q)" 