#!/bin/bash
# set -x

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

install_apache() {
    echo "Installing Apache..."
    apt-get update -y
    apt-get install apache2 -y
    systemctl enable apache2
    systemctl start apache2
    echo "Apache installed and started successfully."
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

install_filebeat() {
    echo "Installing Filebeat..."
    local PLATFORM=$(get_platform)
    curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.17.1-${PLATFORM}.deb
    dpkg -i filebeat-8.17.1-${PLATFORM}.deb

    cp /vagrant/beats/filebeat-elastic.yml /etc/filebeat/filebeat.yml
    cp /vagrant/beats/apache.yml /etc/filebeat/modules.d/apache.yml

    filebeat modules enable apache
    filebeat setup

    systemctl enable filebeat
    systemctl start filebeat
    systemctl status filebeat

    cp -R /etc/filebeat /etc/filebeat-kafka
    cp /vagrant/beats/filebeat-kafka.yml /etc/filebeat-kafka/filebeat.yml
    cp /vagrant/beats/filebeat-kafka.service /etc/systemd/system/filebeat-kafka.service

    systemctl enable filebeat-kafka
    systemctl start filebeat-kafka
    systemctl status filebeat-kafka
}

install_metricbeat() {
    echo "Installing Metricbeat..."
    local PLATFORM=$(get_platform)
    curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.17.1-${PLATFORM}.deb
    dpkg -i metricbeat-8.17.1-${PLATFORM}.deb

    cp /vagrant/beats/metricbeat.yml /etc/metricbeat/metricbeat.yml
    metricbeat modules enable apache
    metricbeat setup

    systemctl enable metricbeat
    systemctl start metricbeat
    systemctl status metricbeat
}

verify_installations() {
    echo "Verifying installations..."
    echo -n "Apache status: "
    systemctl is-active apache2
    echo -n "Node Exporter status: "
    systemctl is-active node_exporter
    echo -n "Filebeat status: "
    systemctl is-active filebeat
    echo -n "Filebeat-Kafka status: "
    systemctl is-active filebeat-kafka
    echo -n "Metricbeat status: "
    systemctl is-active metricbeat
    echo "Installation and configuration of Apache and monitoring tools completed successfully!"
}

# Main execution
install_apache
install_node_exporter
install_filebeat
install_metricbeat
verify_installations
