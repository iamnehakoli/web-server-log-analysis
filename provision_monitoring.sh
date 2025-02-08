#!/bin/bash
set -x

get_platform() {
    local PLATFORM=$(uname -m)
    if [[ "$PLATFORM" == "aarch64" ]]; then
        PLATFORM="arm64"
    elif [[ "$PLATFORM" == "x86_64" ]]; then
        PLATFORM="amd64"
    fi
    echo "$PLATFORM"
}

install_node_exporter() {
    echo "Installing Node Exporter..."
    local PLATFORM=$(get_platform)
    local NODE_EXPORTER_VERSION="1.8.2"
    local NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${PLATFORM}.tar.gz"

    mkdir -p /opt/node_exporter
    cd /opt/node_exporter
    curl -LO ${NODE_EXPORTER_URL}
    tar -xvzf node_exporter-${NODE_EXPORTER_VERSION}.linux-${PLATFORM}.tar.gz --strip-components=1
    rm node_exporter-${NODE_EXPORTER_VERSION}.linux-${PLATFORM}.tar.gz

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

    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
}

install_node_exporter

sudo apt-get install -y apt-transport-https software-properties-common wget

sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com beta main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# Updates the list of available packages
sudo apt-get update

# Installs the latest OSS release:
sudo apt-get install grafana -y

sudo grafana-server -v

sudo systemctl start grafana-server
sudo systemctl enable grafana-server

sudo systemctl status grafana-server

# Verify installations
echo "Verifying installations..."
echo -n "Grafana status: "
systemctl is-active grafana-server

mkdir -p /var/lib/grafana/dashboards

cp /vagrant/grafana/provisioning/datasources/prometheus.yaml /etc/grafana/provisioning/datasources/
cp /vagrant/grafana/provisioning/dashboards/default.yaml /etc/grafana/provisioning/dashboards/
cp /vagrant/grafana/provisioning/dashboards/node-exporter-full.json /var/lib/grafana/dashboards

# Restart Grafana to apply the changes
sudo systemctl restart grafana-server

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
sudo apt-get install apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

sudo apt-get update && sudo apt-get install kibana
sudo echo 'elasticsearch.hosts: ["http://192.168.56.13:9200"]' >> /etc/kibana/kibana.yml
sudo echo 'server.host: "192.168.56.15"' >> /etc/kibana/kibana.yml

sudo systemctl enable kibana
sudo systemctl start kibana
sudo systemctl status kibana