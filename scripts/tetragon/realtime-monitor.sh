#!/bin/bash

# Tetragon实时监控脚本
# 监控安全事件并解析输出

echo "=== Tetragon实时安全监控 ==="
echo "监控进程执行事件 (按Ctrl+C停止)"
echo "正在监控命名空间: fintech-demo"
echo "监控策略: simple-process-monitoring"
echo "----------------------------------------"

# 获取Tetragon Pod名称
TETRAGON_POD=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=tetragon -o jsonpath='{.items[0].metadata.name}')

if [ -z "$TETRAGON_POD" ]; then
    echo "错误: 未找到Tetragon Pod"
    exit 1
fi

echo "使用Tetragon Pod: $TETRAGON_POD"
echo

# 启动监控
kubectl logs -n kube-system -c tetragon $TETRAGON_POD -f | \
    grep -E "(process_exec|process_kprobe|security_bprm_check)" | \
    while read line; do
        echo "[$(date +'%H:%M:%S')] $line"
    done 