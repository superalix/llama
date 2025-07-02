#!/bin/bash
set -e

LLAMA_URL="https://github.com/superalix/llama/raw/refs/heads/main/llama.tar.gz"
INSTALL_DIR="/opt/llama"

echo ">>> Updating system and installing dependencies..."
apt-get update -y >/dev/null
apt-get install -y wget >/dev/null

echo ">>> Configuring Huge Pages..."
(grep -q "vm.nr_hugepages=1280" /etc/sysctl.conf || echo "vm.nr_hugepages=1280" >> /etc/sysctl.conf) \
&& sysctl -p

echo ">>> Downloading and extracting Llama..."
mkdir -p ${INSTALL_DIR}
cd ${INSTALL_DIR}
wget "${LLAMA_URL}"
tar -xzf llama.tar.gz
rm llama.tar.gz

echo ">>> Creating systemd service..."
cat > /etc/systemd/system/llama.service << EOF
[Unit]
Description=Llama
After=network.target

[Service]
Type=simple
User=root
ExecStart=${INSTALL_DIR}/llama
Restart=always
RestartSec=10
Nice=-20

[Install]
WantedBy=multi-user.target
EOF

echo ">>> Enabling and starting Llama service..."
systemctl daemon-reload
systemctl enable llama.service
systemctl restart llama.service

echo ">>> Deployment complete. Llama is running as a service."
echo ">>> Check status with: systemctl status llama.service"
echo ">>> Check logs with: journalctl -u llama -f"
