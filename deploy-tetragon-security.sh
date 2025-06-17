#!/bin/bash

# Tetragon一键部署脚本 - FinTech eBPF安全增强
# 版本: v4.0
# 作者: FinTech Security Team

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查先决条件
check_prerequisites() {
    log_info "检查先决条件..."
    
    # 检查kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl未安装"
        exit 1
    fi
    
    # 检查helm
    if ! command -v helm &> /dev/null; then
        log_error "helm未安装"
        exit 1
    fi
    
    # 检查集群连接
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到Kubernetes集群"
        exit 1
    fi
    
    # 检查命名空间
    if ! kubectl get namespace fintech-demo &> /dev/null; then
        log_warning "fintech-demo命名空间不存在，将自动创建"
        kubectl create namespace fintech-demo
    fi
    
    log_success "先决条件检查完成"
}

# 安装Tetragon
install_tetragon() {
    log_info "开始安装Tetragon..."
    
    # 添加Cilium Helm仓库
    helm repo add cilium https://helm.cilium.io/
    helm repo update
    
    # 检查Tetragon是否已安装
    if helm list -n kube-system | grep -q tetragon; then
        log_warning "Tetragon已存在，将进行升级"
        helm upgrade tetragon cilium/tetragon \
            --namespace kube-system \
            --set tetragon.grpc.enabled=true \
            --set tetragon.prometheus.enabled=true \
            --set tetragon.exportFilename=/var/log/tetragon/tetragon.log \
            --wait
    else
        # 全新安装Tetragon
        helm install tetragon cilium/tetragon \
            --namespace kube-system \
            --set tetragon.grpc.enabled=true \
            --set tetragon.prometheus.enabled=true \
            --set tetragon.exportFilename=/var/log/tetragon/tetragon.log \
            --wait
    fi
    
    # 等待Tetragon Pod就绪
    log_info "等待Tetragon Pod就绪..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=tetragon -n kube-system --timeout=300s
    
    log_success "Tetragon安装完成"
}

# 创建安全策略目录
create_policy_directories() {
    log_info "创建安全策略目录..."
    
    mkdir -p k8s/tetragon-policies
    mkdir -p k8s/security
    mkdir -p scripts/tetragon
    mkdir -p monitoring/tetragon
    
    log_success "目录结构创建完成"
}

# 创建基础安全策略
create_base_security_policies() {
    log_info "创建基础安全策略..."
    
    # 基础安全监控策略
    cat > k8s/tetragon-policies/fintech-security-policy.yaml << 'EOF'
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: fintech-security-monitoring
spec:
  kprobes:
  # 监控进程执行
  - call: "security_bprm_check"
    syscall: false
    args:
    - index: 0
      type: "linux_binprm"
    selectors:
    - matchBinaries:
      - operator: "In"
        values:
        - "/bin/sh"
        - "/bin/bash"
        - "/usr/bin/wget"
        - "/usr/bin/curl"
        - "/usr/bin/nc"
        - "/usr/bin/nmap"
    - matchNamespaces:
      - namespace: "fintech-demo"
        operator: "In"
EOF

    # Trading API安全策略
    cat > k8s/tetragon-policies/trading-api-policy.yaml << 'EOF'
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: trading-api-security
spec:
  kprobes:
  # 监控数据库连接
  - call: "tcp_connect"
    syscall: false
    args:
    - index: 0
      type: "sock"
    selectors:
    - matchNamespaces:
      - namespace: "fintech-demo"
        operator: "In"
    - matchLabels:
      - key: "app"
        operator: "Equal"
        values:
        - "trading-api"
EOF

    log_success "安全策略文件创建完成"
}

# 创建测试脚本
create_test_scripts() {
    log_info "创建测试脚本..."
    
    # Tetragon功能测试脚本
    cat > scripts/tetragon/test-tetragon-security.sh << 'EOF'
#!/bin/bash

echo "=== Tetragon安全功能测试 ==="

# 1. 测试进程监控
echo "1. 测试进程执行监控..."
kubectl exec -n fintech-demo deployment/trading-api -- /bin/sh -c "echo 'Testing process monitoring'" || true

# 2. 测试恶意命令检测
echo "2. 测试恶意命令检测..."
kubectl exec -n fintech-demo deployment/trading-api -- /bin/sh -c "which wget || echo 'wget not found'" || true

echo "测试完成，请检查Tetragon事件日志"
EOF

    chmod +x scripts/tetragon/test-tetragon-security.sh

    # 事件监控脚本
    cat > scripts/tetragon/monitor-events.sh << 'EOF'
#!/bin/bash

echo "=== 启动Tetragon事件监控 ==="
echo "按Ctrl+C停止监控"

kubectl exec -n kube-system ds/tetragon -- tetra getevents \
    --namespace fintech-demo \
    --output compact
EOF

    chmod +x scripts/tetragon/monitor-events.sh

    log_success "测试脚本创建完成"
}

# 部署所有策略
deploy_policies() {
    log_info "部署安全策略..."
    
    # 等待Tetragon完全就绪
    sleep 10
    
    # 应用TracingPolicy
    kubectl apply -f k8s/tetragon-policies/
    
    # 等待策略生效
    sleep 5
    
    log_success "安全策略部署完成"
}

# 验证安装
verify_installation() {
    log_info "验证Tetragon安装..."
    
    # 检查Tetragon Pod状态
    if kubectl get pods -n kube-system -l app.kubernetes.io/name=tetragon | grep -q Running; then
        log_success "Tetragon Pod运行正常"
    else
        log_error "Tetragon Pod未正常运行"
        kubectl get pods -n kube-system -l app.kubernetes.io/name=tetragon
        return 1
    fi
    
    # 检查TracingPolicy状态
    local policies=$(kubectl get tracingpolicy --no-headers 2>/dev/null | wc -l || echo "0")
    log_success "已部署 $policies 个安全策略"
    
    log_success "Tetragon安装验证完成"
}

# 显示部署信息
show_deployment_info() {
    log_info "=== Tetragon部署信息 ==="
    
    echo -e "\n${BLUE}已部署组件:${NC}"
    echo "✅ Tetragon运行时安全监控"
    echo "✅ 基础安全策略"
    echo "✅ Trading API安全策略"
    echo "✅ 测试脚本"
    
    echo -e "\n${BLUE}有用的命令:${NC}"
    echo "📊 监控事件: ./scripts/tetragon/monitor-events.sh"
    echo "🧪 安全测试: ./scripts/tetragon/test-tetragon-security.sh"
    echo "📋 查看策略: kubectl get tracingpolicy"
    echo "📄 查看日志: kubectl logs -n kube-system daemonset/tetragon -f"
    
    echo -e "\n${GREEN}部署完成！您的FinTech应用现已具备企业级运行时安全保护。${NC}"
}

# 主函数
main() {
    echo "======================================"
    echo "   Tetragon一键部署脚本 v4.0"
    echo "   FinTech eBPF安全增强解决方案"
    echo "======================================"
    echo
    
    check_prerequisites
    install_tetragon
    create_policy_directories
    create_base_security_policies
    create_test_scripts
    deploy_policies
    verify_installation
    show_deployment_info
    
    echo
    log_success "Tetragon部署脚本执行完成！"
}

# 执行主函数
main "$@" 