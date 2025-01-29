#!/bin/bash

# Set versions for Prometheus and Elasticsearch
PROMETHEUS_VERSION="3.1.0"  # Specify the desired Prometheus version
ELASTICSEARCH_VERSION="8"  # Specify the desired Elasticsearch version

# Install Prometheus
echo "Installing Prometheus version: $PROMETHEUS_VERSION"

# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-arm64.tar.gz -O prometheus.tar.gz

# Extract and Install
tar xvf prometheus.tar.gz
mkdir -p /opt/prometheus /etc/prometheus/ /var/lib/prometheus/data
mv ./prometheus-$PROMETHEUS_VERSION*/* /opt/prometheus/

cp /vagrant/prometheus/prometheus.yml /etc/prometheus/

# Create Prometheus Service
echo "[Unit]
Description=Prometheus Monitoring System
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
ExecStart=/opt/prometheus/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/data
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/prometheus.service

# Reload systemd and start Prometheus
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

echo "Prometheus installation completed."

# # Install Elasticsearch
# echo "Installing Elasticsearch version: $ELASTICSEARCH_VERSION"

# # Install dependencies
# sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates wget curl gnupg

# # Add Elasticsearch GPG key
# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

# # Add the Elasticsearch APT repository
# echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

# # Install Elasticsearch
# sudo apt-get update
# sudo apt-get install -y elasticsearch=$ELASTICSEARCH_VERSION

# # Enable and start Elasticsearch service
# sudo systemctl enable elasticsearch
# sudo systemctl start elasticsearch

# # Verify Elasticsearch
# curl -X GET "localhost:9200/?pretty"

# echo "Elasticsearch installation completed."

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

sudo apt-get install apt-transport-https openjdk-17-jdk

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

sudo apt-get update && sudo apt-get install elasticsearch

echo "network.host: 192.168.56.12" >> /etc/elasticsearch/elasticsearch.yml
sudo sed -i '/xpack.security.enabled/c\xpack.security.enabled: false' /etc/elasticsearch/elasticsearch.yml

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service

sudo systemctl start elasticsearch.service

# # Verify installations
echo "Verifying installations..."
echo -n "Prometheus status: "
systemctl is-active prometheus
echo -n "Elasticsearch status: "
systemctl is-active elasticsearch