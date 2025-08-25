msg_info() {
    echo -e "\033[1;36m[INFO]\033[0m $1"
}

msg_ok() {
    echo -e "\033[1;32m[OK]\033[0m $1"
}

msg_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
    exit 1
}

if [[ $EUID -ne 0 ]]; then
   msg_error "This script must be run as root. Please use 'sudo'."
fi

msg_info "Updating system packages..."
apt-get update -y || msg_error "Failed to update package list."
apt-get upgrade -y || msg_error "Failed to upgrade packages."

msg_info "Installing necessary dependencies (git, curl, nodejs, npm, python3-pip)..."
apt-get install -y git curl nodejs npm python3-pip || msg_error "Failed to install dependencies."

msg_info "Checking Node.js and npm versions..."
node -v
npm -v

msg_info "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh || msg_error "Failed to install Ollama."
msg_ok "Ollama installed successfully."

OPENWEBUI_DIR="/opt/open-webui"
if [ ! -d "$OPENWEBUI_DIR" ]; then
    msg_info "Cloning Open WebUI repository to $OPENWEBUI_DIR..."
    git clone https://github.com/open-webui/open-webui.git "$OPENWEBUI_DIR" || msg_error "Failed to clone Open WebUI repository."
    msg_ok "Open WebUI repository cloned."
else
    msg_info "Open WebUI directory already exists. Skipping clone."
fi

cd "$OPENWEBUI_DIR" || msg_error "Failed to change directory to $OPENWEBUI_DIR."

msg_info "Installing Open WebUI npm dependencies..."
npm install --force || msg_error "Failed to install npm dependencies."

msg_info "Building Open WebUI frontend (this may take a few minutes)..."
export NODE_OPTIONS="--max-old-space-size=3584"
npm run build || msg_error "Failed to build Open WebUI."

msg_info "Installing Open WebUI backend dependencies..."
cd ./backend || msg_error "Failed to change directory to backend."
pip install -r requirements.txt -U || msg_error "Failed to install backend dependencies."

msg_info "Creating and starting Open WebUI systemd service..."

SERVICE_FILE_CONTENT="[Unit]
Description=Open WebUI
After=network.target

[Service]
ExecStart=/usr/bin/npm start
WorkingDirectory=/opt/open-webui
User=root
Group=root
Restart=always

[Install]
WantedBy=multi-user.target"

echo "$SERVICE_FILE_CONTENT" > /etc/systemd/system/open-webui.service || msg_error "Failed to create service file."

systemctl daemon-reload
systemctl enable open-webui.service
systemctl start open-webui.service

msg_ok "Open WebUI service created and started."

IP_ADDRESS=$(hostname -I | awk '{print $1}')
msg_ok "Installation completed successfully!"
echo -e "\n---------------------------------------------------"
echo -e "Open WebUI should now be running."
echo -e "Access it by navigating to http://$IP_ADDRESS:3000 in your web browser."
echo -e "---------------------------------------------------\n"

# --- Netplan Configuration Section ---
msg_info "Checking for netplan configuration..."
NETPLAN_DIR="/etc/netplan"
if [ -d "$NETPLAN_DIR" ]; then
    NETPLAN_FILE=$(ls $NETPLAN_DIR/*.yaml 2>/dev/null | head -n 1)
    if [ -n "$NETPLAN_FILE" ]; then
        echo -e "\nNetplan file detected: $NETPLAN_FILE"
        read -p "Do you want to configure a static IP address? (y/n): " CONFIGURE_NETPLAN
        if [[ "$CONFIGURE_NETPLAN" =~ ^[Yy]$ ]]; then
            read -p "Enter the desired static IP address (e.g., 192.168.1.100/24): " STATIC_IP
            read -p "Enter the gateway (e.g., 192.168.1.1): " GATEWAY
            read -p "Enter DNS servers (comma separated, e.g., 8.8.8.8,8.8.4.4): " DNS_SERVERS
            # Find the interface name
            INTERFACE=$(ls /sys/class/net | grep -v lo | head -n 1)
            if [ -z "$INTERFACE" ]; then
                msg_error "Could not detect a network interface."
            fi
            msg_info "Backing up original netplan file..."
            cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak" || msg_error "Failed to backup netplan file."
            cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses: [$STATIC_IP]
      gateway4: $GATEWAY
      nameservers:
        addresses: [${DNS_SERVERS//,/ }]
EOF
            msg_info "Applying netplan configuration..."
            netplan apply || msg_error "Failed to apply netplan configuration."
            msg_ok "Netplan static IP configuration applied."
        else
            msg_info "Skipping netplan static IP configuration."
        fi
    else
        msg_info "No netplan YAML file found in $NETPLAN_DIR. Skipping netplan configuration."
    fi
else
    msg_info "Netplan directory not found. Skipping netplan configuration."
fi
