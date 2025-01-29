# Install apache
echo "Installing apache..."
apt-get update -y
apt-get install apache2 -y

# Enable and start apache service
echo "Configuring apache..."
systemctl enable apache2
systemctl start apache2
echo "apache installed and started successfully."

# Download and install Node Exporter for ARM64
echo "Installing Node Exporter..."
NODE_EXPORTER_VERSION="1.8.2"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64.tar.gz"

# Create a directory for Node Exporter
mkdir -p /opt/node_exporter
cd /opt/node_exporter

# Download and extract Node Exporter
curl -LO ${NODE_EXPORTER_URL}
tar -xvzf node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64.tar.gz --strip-components=1
rm node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64.tar.gz

# Create a systemd service for Node Exporter
echo "Creating systemd service for Node Exporter..."
cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/opt/node_exporter/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start Node Exporter
echo "Starting Node Exporter..."
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Verify installations
echo "Verifying installations..."
echo -n "apache status: "
systemctl is-active apache2
echo -n "Node Exporter status: "
systemctl is-active node_exporter

echo "Installation and configuration of apache and Node Exporter completed successfully!"

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.17.1-arm64.deb
sudo dpkg -i filebeat-8.17.1-arm64.deb

sudo cp /vagrant/filebeat/filebeat.yml /etc/filebeat/filebeat.yml
sudo cp /vagrant/filebeat/apache.yml /etc/filebeat/modules.d/apache.yml

sudo filebeat modules enable apache
sudo filebeat setup

sudo systemctl enable filebeat
sudo systemctl start filebeat
sudo systemctl status filebeat