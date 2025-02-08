#!/bin/bash
set -x

# Global platform detection
get_platform() {
    local PLATFORM=$(uname -m)
    if [[ "$PLATFORM" == "aarch64" ]]; then
        PLATFORM="arm64"
    elif [[ "$PLATFORM" == "x86_64" ]]; then
        PLATFORM="amd64"
    fi
    echo "$PLATFORM"
}

PLATFORM=$(get_platform)
# Set versions for Prometheus and Elasticsearch
PROMETHEUS_VERSION="3.1.0" 
ELASTICSEARCH_VERSION="8"

# Function to install Prometheus
install_prometheus() {
    echo "Installing Prometheus version: $PROMETHEUS_VERSION"

    wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-${PLATFORM}.tar.gz -O prometheus.tar.gz
    tar xvf prometheus.tar.gz
    mkdir -p /opt/prometheus /etc/prometheus/ /var/lib/prometheus/data
    mv ./prometheus-$PROMETHEUS_VERSION*/* /opt/prometheus/
    cp /vagrant/prometheus/prometheus.yml /etc/prometheus/

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

    sudo systemctl daemon-reload
    sudo systemctl enable prometheus
    sudo systemctl start prometheus

    echo "Prometheus installation completed."
}

# Function to install Elasticsearch
install_elasticsearch() {
    echo "Installing Elasticsearch version: $ELASTICSEARCH_VERSION"

    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
    sudo apt-get install -y apt-transport-https openjdk-17-jdk
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/${ELASTICSEARCH_VERSION}.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-${ELASTICSEARCH_VERSION}.x.list

    sudo apt-get update && sudo apt-get install -y elasticsearch
    echo "network.host: 192.168.56.13" >> /etc/elasticsearch/elasticsearch.yml
    sudo sed -i '/xpack.security.enabled/c\xpack.security.enabled: false' /etc/elasticsearch/elasticsearch.yml

    sudo systemctl daemon-reload
    sudo systemctl enable elasticsearch.service
    sudo systemctl start elasticsearch.service

    echo "Elasticsearch installation completed."
}

# Function to verify installations
verify_installations() {
    echo "Verifying installations..."
    echo -n "Prometheus status: "; systemctl is-active prometheus
    echo -n "Elasticsearch status: "; systemctl is-active elasticsearch
}

install_prometheus
install_elasticsearch
verify_installations
