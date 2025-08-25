# OpenWebUI + Ollama Install Script

This repository provides a one-step installation script to set up [Open WebUI](https://github.com/open-webui/open-webui) and [Ollama](https://ollama.com/) on a fresh Ubuntu/Debian-based system.

## Features
- Installs all required dependencies (git, curl, nodejs, npm, python3-pip)
- Installs Ollama
- Clones the Open WebUI repository
- Installs and builds frontend and backend dependencies
- Sets up Open WebUI as a systemd service

---

## Quick Start

### 1. Clone the Repository

```
git clone https://github.com/0xh34z/openwebui-ollama-install-script.git
cd openwebui-ollama-install-script
```

### 2. Run the Install Script

> **Note:** You must run this script as root (use `sudo`).

```
sudo bash setup.sh
```

---

## Alternative: Run Directly from GitHub (Raw Branch)

You can run the script directly without cloning:

```
curl -fsSL https://raw.githubusercontent.com/0xh34z/openwebui-ollama-install-script/main/setup.sh | sudo bash
```

---

## After Installation

- Open WebUI will be running as a systemd service.
- Access the UI at: `http://<your-server-ip>:3000`

---

## Requirements
- Ubuntu/Debian-based system
- Root privileges (sudo)

---

## Uninstall
To remove the service and files, run:

```
sudo systemctl stop open-webui.service
sudo systemctl disable open-webui.service
sudo rm /etc/systemd/system/open-webui.service
sudo rm -rf /opt/open-webui
sudo systemctl daemon-reload
```

---

## License
MIT
