#!/bin/bash

# -----------------------------
# 配置项
# -----------------------------
REMOTE_USER="root"                # 服务器用户名
REMOTE_HOST="47.251.244.157"               # 服务器 IP
REMOTE_WEBROOT="/var/owncast/webroot"  # Owncast webroot
SSH_PORT=22                           # SSH 端口，默认22
LOCAL_BUILD_DIR="./out"               # 前端导出目录
FRONTEND_DIR="./web"               # Owncast 前端源码目录

# -----------------------------
# 编译前端
# -----------------------------cd 
echo "Step 1: Build and export frontend..."
cd "$FRONTEND_DIR" || { echo "Frontend directory not found!"; exit 1; }
# npm run build || { echo "npm run build failed!"; exit 1; }

# -----------------------------
# 上传文件
# -----------------------------
echo "Uploading frontend files to $REMOTE_HOST:$REMOTE_WEBROOT ..."

# 使用 rsync 增量上传，保持目录结构
rsync -avz --delete -e "ssh -p $SSH_PORT" "$LOCAL_BUILD_DIR/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_WEBROOT/"

# -----------------------------
# 完成提示
# -----------------------------
if [ $? -eq 0 ]; then
    echo "Upload completed successfully!"
else
    echo "Upload failed!"
fi