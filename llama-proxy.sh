#!/bin/bash
set -e

LLAMA_URL="https://github.com/superalix/llama/raw/refs/heads/main/llama-proxy.tar.gz"
INSTALL_DIR="/opt/llama"

echo ">>> Updating system and installing dependencies..."
apt-get update >/dev/null
apt-get install -y wget >/dev/null

echo ">>> Configuring Huge Pages..."
(grep -q "vm.nr_hugepages=1280" /etc/sysctl.conf || echo "vm.nr_hugepages=1280" >> /etc/sysctl.conf) \
&& sysctl -p

echo ">>> Downloading and extracting Llama..."
mkdir -p ${INSTALL_DIR}
wget -O - "${LLAMA_URL}" | tar -xz -C ${INSTALL_DIR} --strip-components=1

echo ">>> Creating systemd service..."
cat > /etc/systemd/system/llama-proxy.service << EOF
[Unit]
Description=Llama Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=${INSTALL_DIR}/llama-proxy --config=${INSTALL_DIR}/config.json
Restart=always
RestartSec=10
Nice=-20

[Install]
WantedBy=multi-user.target
EOF

echo ">>> Enabling and starting Llama service..."
systemctl daemon-reload
systemctl enable llama-proxy.service
systemctl restart llama-proxy.service

echo ">>> Deployment complete. Llama proxy is running as a service."
echo ">>> Check status with: systemctl status llama-proxy.service"
echo ">>> Check logs with: journalctl -u llama-proxy -f"

