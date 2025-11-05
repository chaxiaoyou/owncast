ssh root@47.84.0.225 'bash -s' <<'EOF'
#!/bin/bash
set -e

MONGO_CONTAINER=mongodb
ROCKET_CONTAINER=rocketchat
MONGO_VERSION=6.0
ROCKET_VERSION=latest
MONGO_DATA=~/rocketchat_data/mongo
PORT=3000

echo "🧱 清理旧容器..."
docker stop $ROCKET_CONTAINER $MONGO_CONTAINER 2>/dev/null || true
docker rm $ROCKET_CONTAINER $MONGO_CONTAINER 2>/dev/null || true

echo "🧹 清理旧数据..."
rm -rf $MONGO_DATA
mkdir -p $MONGO_DATA

echo "🚀 启动 MongoDB 副本集..."
docker run -d \
  --name $MONGO_CONTAINER \
  -p 27017:27017 \
  -v $MONGO_DATA:/data/db \
  mongo:$MONGO_VERSION --replSet rs0 --oplogSize 128

echo "⏳ 等待 MongoDB 启动中..."
sleep 20

# 获取容器内部主机名
MONGO_HOST=$(docker exec $MONGO_CONTAINER hostname)
echo "🔍 MongoDB 内部主机名为: $MONGO_HOST"

echo "⚙️ 初始化副本集..."
docker exec $MONGO_CONTAINER mongosh --eval "rs.initiate({
  _id: 'rs0',
  members: [{ _id: 0, host: '${MONGO_HOST}:27017' }]
})" || echo "Replica set may already be initialized."

sleep 5
docker exec $MONGO_CONTAINER mongosh --eval "rs.status()" || true

echo "💬 启动 Rocket.Chat..."
docker run -d \
  --name $ROCKET_CONTAINER \
  --link $MONGO_CONTAINER:mongodb \
  -p $PORT:3000 \
  -e MONGO_URL="mongodb://${MONGO_HOST}:27017/rocketchat?replicaSet=rs0" \
  -e ROOT_URL="http://localhost:$PORT" \
  -e PORT=3000 \
  rocketchat/rocket.chat:$ROCKET_VERSION

echo ""
echo "✅ 部署完成！访问 👉 http://localhost:$PORT"
EOF
