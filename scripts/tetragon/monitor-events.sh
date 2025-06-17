#!/bin/bash

echo "=== 启动Tetragon事件监控 ==="
echo "按Ctrl+C停止监控"

kubectl exec -n kube-system ds/tetragon -- tetra getevents \
    --namespace fintech-demo \
    --output compact
