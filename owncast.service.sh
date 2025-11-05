ssh root@47.84.0.225 'bash -s' <<'EOF'
#!/bin/bash
SERVICE_FILE="/etc/systemd/system/owncast.service"
OWNCAST_DIR="/var/owncast"
EXEC="$OWNCAST_DIR/owncast"
HTTP_PORT=8080
RTMP_PORT=10080

echo "🛠️ 配置 Owncast 服务中..."

if [ ! -f "$EXEC" ]; then
  echo "❌ 未找到 Owncast 主程序: $EXEC"
  exit 1
fi

CONFIG_FILE="$OWNCAST_DIR/config.json"
if [ -f "$CONFIG_FILE" ]; then
  echo "🔧 更新 config.json 中端口设置..."
  sed -i "s/\"webServerPort\": *[0-9]\+/\"webServerPort\": $HTTP_PORT/" "$CONFIG_FILE"
  sed -i "s/\"rtmpServerPort\": *[0-9]\+/\"rtmpServerPort\": $RTMP_PORT/" "$CONFIG_FILE"
else
  echo "⚠️ 未找到 config.json，使用默认配置启动。"
fi

# 写入 systemd 服务文件
cat <<EOT > $SERVICE_FILE
[Unit]
Description=Owncast Server
After=network.target

[Service]
Type=simple
ExecStart=$EXEC
WorkingDirectory=$OWNCAST_DIR
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOT

echo "🔄 重新加载并启动 Owncast..."
systemctl daemon-reload
systemctl enable owncast
systemctl restart owncast

sleep 2
if systemctl is-active --quiet owncast; then
  IP=$(hostname -I | awk '{print $1}')
  echo "✅ Owncast 启动成功！"
  echo "🌐 前端访问: http://${IP}:${HTTP_PORT}"
  echo "📡 OBS 推流地址: rtmp://${IP}:${RTMP_PORT}/live"
  echo "🔑 推流密钥在 config.json 中的 'streamKey'"
else
  echo "❌ 启动失败，请查看日志: journalctl -u owncast -f"
fi
EOF




