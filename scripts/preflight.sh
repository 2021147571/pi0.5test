#!/usr/bin/env bash
set -euo pipefail

echo "===== SYSTEM ====="
uname -a

echo "===== GPU ====="
command -v nvidia-smi >/dev/null
nvidia-smi

echo "===== DISK ====="
df -h / /root/autodl-tmp 2>/dev/null || df -h /

echo "===== DOCKER ====="
if command -v docker >/dev/null; then
  docker --version
  docker compose version || true
else
  echo "Docker is not installed. Native AutoDL mode does not require it."
fi

echo "===== NVIDIA CONTAINER RUNTIME ====="
if command -v docker >/dev/null; then
  docker info 2>/dev/null | grep -E 'Runtimes|Default Runtime' || true
fi

echo "===== NETWORK TOOLS ====="
command -v git
command -v curl
