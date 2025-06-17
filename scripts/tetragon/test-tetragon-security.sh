#!/bin/bash

echo "=== Tetragon安全功能测试 ==="

# 1. 测试进程监控
echo "1. 测试进程执行监控..."
kubectl exec -n fintech-demo deployment/trading-api -- /bin/sh -c "echo 'Testing process monitoring'" || true

# 2. 测试恶意命令检测
echo "2. 测试恶意命令检测..."
kubectl exec -n fintech-demo deployment/trading-api -- /bin/sh -c "which wget || echo 'wget not found'" || true

echo "测试完成，请检查Tetragon事件日志"
