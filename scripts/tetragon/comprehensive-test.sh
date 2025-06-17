#!/bin/bash

# Tetragon + FinTech应用综合测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

echo "======================================"
echo "   Tetragon + FinTech 综合功能测试"
echo "======================================"
echo

# 1. 验证Tetragon状态
log_info "1. 验证Tetragon运行状态..."
if kubectl get pods -n kube-system -l app.kubernetes.io/name=tetragon | grep -q Running; then
    log_success "Tetragon Pods运行正常"
else
    echo -e "${RED}[ERROR]${NC} Tetragon Pods未正常运行"
    exit 1
fi

# 2. 验证TracingPolicy
log_info "2. 验证安全策略..."
POLICIES=$(kubectl get tracingpolicy --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$POLICIES" -gt 0 ]; then
    log_success "已部署 $POLICIES 个安全策略"
    kubectl get tracingpolicy --no-headers
else
    echo -e "${RED}[ERROR]${NC} 未找到安全策略"
    exit 1
fi

# 3. 验证应用服务状态
log_info "3. 验证FinTech应用服务..."
if kubectl get pods -n fintech-demo | grep -q Running; then
    RUNNING_PODS=$(kubectl get pods -n fintech-demo --no-headers | grep Running | wc -l)
    log_success "FinTech应用 $RUNNING_PODS 个Pod运行正常"
else
    echo -e "${RED}[ERROR]${NC} FinTech应用未正常运行"
    exit 1
fi

# 4. 测试前端应用
log_test "4. 测试前端应用..."
if curl -s http://fintech-demo.local/ | grep -q "金融微服務"; then
    log_success "前端应用访问正常"
else
    echo -e "${RED}[ERROR]${NC} 前端应用无法访问"
    exit 1
fi

# 5. 测试安全API
log_test "5. 测试安全API功能..."

# 测试命令注入检测
COMMAND_TEST=$(curl -s http://fintech-demo.local/api/security/test/command \
    -H "Content-Type: application/json" \
    -d '{"command":"whoami"}' | jq -r '.success // false' 2>/dev/null || echo "false")

if [ "$COMMAND_TEST" = "true" ]; then
    log_success "命令注入测试API正常"
else
    echo -e "${RED}[ERROR]${NC} 命令注入测试API失败"
fi

# 测试文件访问检测
FILE_TEST=$(curl -s http://fintech-demo.local/api/security/test/file \
    -H "Content-Type: application/json" \
    -d '{"path":"/etc/passwd"}' | jq -r '.success // false' 2>/dev/null || echo "false")

if [ "$FILE_TEST" = "true" ]; then
    log_success "文件访问测试API正常"
else
    echo -e "${RED}[ERROR]${NC} 文件访问测试API失败"
fi

# 测试网络扫描检测
NETWORK_TEST=$(curl -s http://fintech-demo.local/api/security/test/network \
    -H "Content-Type: application/json" \
    -d '{"target":"localhost","port":"22"}' | jq -r '.success // false' 2>/dev/null || echo "false")

if [ "$NETWORK_TEST" = "true" ]; then
    log_success "网络扫描测试API正常"
else
    echo -e "${RED}[ERROR]${NC} 网络扫描测试API失败"
fi

# 6. 在应用中触发可监控的进程
log_test "6. 触发Tetragon监控事件..."

# 在trading-api pod中执行一些命令来触发Tetragon监控
kubectl exec -n fintech-demo deployment/trading-api -- /bin/sh -c "echo 'Tetragon test execution'" > /dev/null 2>&1 || true
kubectl exec -n fintech-demo deployment/trading-api -- /bin/bash -c "ls /tmp" > /dev/null 2>&1 || true

log_success "已触发监控事件，可通过Tetragon日志查看"

# 7. 验证监控脚本
log_test "7. 验证监控脚本..."
if [ -x "scripts/tetragon/realtime-monitor.sh" ]; then
    log_success "实时监控脚本可执行"
else
    echo -e "${RED}[ERROR]${NC} 实时监控脚本不可执行"
fi

# 8. 显示系统状态摘要
echo
log_info "=== 系统状态摘要 ==="
echo -e "${BLUE}Tetragon状态:${NC}"
kubectl get pods -n kube-system -l app.kubernetes.io/name=tetragon --no-headers | awk '{print "  " $1 ": " $3}'

echo -e "\n${BLUE}安全策略:${NC}"
kubectl get tracingpolicy --no-headers | awk '{print "  " $1 ": " $2}'

echo -e "\n${BLUE}应用服务:${NC}"
kubectl get pods -n fintech-demo --no-headers | awk '{print "  " $1 ": " $3}'

echo -e "\n${BLUE}有用的命令:${NC}"
echo "  📊 实时监控: ./scripts/tetragon/realtime-monitor.sh"
echo "  🧪 安全测试: ./scripts/tetragon/test-tetragon-security.sh"
echo "  🌐 访问应用: http://fintech-demo.local/"
echo "  📋 查看策略: kubectl get tracingpolicy"
echo "  📄 查看日志: kubectl logs -n kube-system ds/tetragon -c tetragon -f"

echo -e "\n${GREEN}✅ 综合测试完成！Tetragon eBPF安全监控已就绪。${NC}" 