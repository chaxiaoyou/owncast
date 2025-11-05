#!/bin/bash
# ==========================================================
# 🚀 一键部署 Rocket.Chat + MongoDB (Linux 版)
# 适用环境：Ubuntu / CentOS / Debian / Amazon Linux
# 作者：ChatGPT GPT-5
# ==========================================================

set -e

# ========== 配置 ==========
MONGO_CONTAINER=mongodb
ROCKET_CONTAINER=rocketchat
MONGO_VERSION=5.0
ROCKET_VERSION=latest
MONGO_DATA=$HOME/rocketchat_data/mongo
ROCKET_PORT=3000
MONGO_PORT=27017
# ==========================

echo "📦 检查 Docker 环境..."
if ! command -v docker &> /dev/null; then
  echo "🔧 未检测到 Docker，正在安装..."
  curl -fsSL https://get.docker.com | bash
  systemctl enable docker
  systemctl start docker
fi

echo "✅ Docker 已准备就绪"

echo "📁 创建数据目录..."
mkdir -p $MONGO_DATA

# 启动 MongoDB
if [ ! "$(docker ps -q -f name=$MONGO_CONTAINER)" ]; then
  echo "🧱 启动 MongoDB..."
  docker run -d \
    --name $MONGO_CONTAINER \
    -p $MONGO_PORT:27017 \
    -v $MONGO_DATA:/data/db \
    mongo:$MONGO_VERSION --replSet rs0 --oplogSize 128
else
  echo "✅ MongoDB 已在运行"
fi

# 等待 Mongo 启动完成
echo "⏳ 等待 MongoDB 初始化..."
sleep 10

# 初始化副本集（Rocket.Chat 需要）
echo "🧩 初始化 Mongo 副本集..."
docker exec $MONGO_CONTAINER mongosh --eval "rs.initiate({ _id: 'rs0', members: [{ _id: 0, host: 'localhost:$MONGO_PORT' }] })" || true

# 启动 Rocket.Chat
if [ ! "$(docker ps -q -f name=$ROCKET_CONTAINER)" ]; then
  echo "🚀 启动 Rocket.Chat..."
  docker run -d \
    --name $ROCKET_CONTAINER \
    --link $MONGO_CONTAINER:mongo \
    -p $ROCKET_PORT:3000 \
    -e MONGO_URL="mongodb://mongo:27017/rocketchat?replicaSet=rs0" \
    -e ROOT_URL="http://$(hostname -I | awk '{print $1}'):$ROCKET_PORT" \
    -e PORT=3000 \
    rocketchat/rocket.chat:$ROCKET_VERSION
else
  echo "✅ Rocket.Chat 已在运行"
fi

echo ""
echo "🎉 Rocket.Chat 部署完成！"
echo "🌍 访问地址:  http://$(hostname -I | awk '{print $1}'):$ROCKET_PORT"
echo "🔑 第一次打开时可通过网页创建管理员账户。"
echo ""
echo "🧩 MongoDB 数据路径: $MONGO_DATA"
echo "🧱 Docker 容器: $MONGO_CONTAINER + $ROCKET_CONTAINER"
