#!/bin/bash

# FinTech eBPF Demo v3.7 部署脚本
# 使用Helm部署到Kubernetes集群

set -e

# 配置
NAMESPACE="fintech-demo"
RELEASE_NAME="fintech-demo"
CHART_PATH="k8s/helm/fintech-chart"
VERSION="v3.7"

echo "🚀 开始部署 FinTech eBPF Demo v3.7..."
echo "📦 Namespace: $NAMESPACE"
echo "🏷️  Release: $RELEASE_NAME"
echo "📂 Chart Path: $CHART_PATH"
echo "🔖 Version: $VERSION"

# 检查kubectl连接
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ 无法连接到Kubernetes集群"
    echo "💡 请检查kubectl配置"
    exit 1
fi

# 检查Helm
if ! command -v helm &> /dev/null; then
    echo "❌ Helm 未安装"
    echo "💡 请安装Helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

# 创建命名空间（如果不存在）
echo "🔧 检查命名空间..."
if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    echo "📦 创建命名空间: $NAMESPACE"
    kubectl create namespace $NAMESPACE
else
    echo "✅ 命名空间已存在: $NAMESPACE"
fi

# 添加依赖的Helm仓库
echo "📦 添加Helm仓库..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 检查Chart语法
echo "🔍 验证Helm Chart..."
helm lint $CHART_PATH

# 部署或升级
echo "🚀 部署应用..."
if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
    echo "🔄 升级现有部署..."
    helm upgrade $RELEASE_NAME $CHART_PATH \
        --namespace $NAMESPACE \
        --timeout 10m \
        --wait \
        --debug
else
    echo "🆕 首次部署..."
    helm install $RELEASE_NAME $CHART_PATH \
        --namespace $NAMESPACE \
        --timeout 10m \
        --wait \
        --debug
fi

# 等待Pod就绪
echo "⏳ 等待Pod启动..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$RELEASE_NAME -n $NAMESPACE --timeout=300s || true

# 显示部署状态
echo ""
echo "📊 部署状态:"
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "🔍 服务状态:"
kubectl get svc -n $NAMESPACE

echo ""
echo "📋 Helm发布信息:"
helm list -n $NAMESPACE

echo ""
echo "🎉 部署完成！"

echo ""
echo "🔧 验证命令:"
echo "  - 查看Pod状态: kubectl get pods -n $NAMESPACE"
echo "  - 查看日志: kubectl logs -f deployment/frontend -n $NAMESPACE"
echo "  - 端口转发: kubectl port-forward svc/frontend-service 3000:80 -n $NAMESPACE"
echo "  - 访问应用: http://localhost:3000"

echo ""
echo "🐛 调试命令:"
echo "  - 描述Pod: kubectl describe pod <pod-name> -n $NAMESPACE"
echo "  - 进入容器: kubectl exec -it <pod-name> -n $NAMESPACE -- /bin/sh"
echo "  - 查看事件: kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"

echo ""
echo "🗑️  清理命令:"
echo "  - 删除部署: helm uninstall $RELEASE_NAME -n $NAMESPACE"
echo "  - 删除命名空间: kubectl delete namespace $NAMESPACE" 