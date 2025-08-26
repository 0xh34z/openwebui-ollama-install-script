#!/usr/bin/env bash
set -e

APP="Open WebUI"
INSTALL_DIR="/opt/open-webui"

echo "=== Installing dependencies ==="
apt update
apt install -y curl git python3 python3-pip nodejs npm

echo "=== Installing Ollama ==="
if [ ! -x "/usr/bin/ollama" ]; then
  curl -fsSLO https://ollama.com/download/ollama-linux-amd64.tgz
  tar -C /usr -xzf ollama-linux-amd64.tgz
  rm -f ollama-linux-amd64.tgz
else
  echo "Ollama already installed, skipping..."
fi

echo "=== Installing $APP ==="
if [ ! -d "$INSTALL_DIR" ]; then
  git clone https://github.com/open-webui/open-webui.git "$INSTALL_DIR"
  cd "$INSTALL_DIR"
  npm install --force
  export NODE_OPTIONS="--max-old-space-size=3584"
  npm run build
  cd backend
  pip install -r requirements.txt
else
  echo "$APP already installed, run with update flag to update."
fi

echo "=== Creating systemd service ==="
cat >/etc/systemd/system/open-webui.service <<EOF
[Unit]
Description=Open WebUI
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/npm start
Restart=always
User=root
Environment=NODE_OPTIONS=--max-old-space-size=3584

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable open-webui
systemctl start open-webui

echo "=== Installation completed ==="
IP=$(hostname -I | awk '{print $1}')
echo "Access Open WebUI at: http://$IP:8080"
