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

install_updates() {
    apt-get update -y
}

install_node_exporter() {
    echo "Installing Node Exporter..."
    PLATFORM=$(get_platform)
    NODE_EXPORTER_VERSION="1.8.2"
    NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${PLATFORM}.tar.gz"

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

    echo -n "Node Exporter status: "
    systemctl is-active node_exporter
}

install_java() {
    sudo apt install openjdk-11-jdk -y
}

install_kafka() {
    echo "Installing Kafka..."
    wget https://dlcdn.apache.org/kafka/3.9.0/kafka_2.13-3.9.0.tgz
    tar -xzf kafka_2.13-3.9.0.tgz
    mv kafka_2.13-3.9.0 kafka
    sudo mv kafka /opt/

    sudo mkdir -p /opt/kafka/logs
    sudo chmod -R 777 /opt/kafka/logs

    sudo echo "listeners=PLAINTEXT://192.168.56.12:9092" >> /opt/kafka/config/server.properties
    sudo echo "advertised.listeners=PLAINTEXT://192.168.56.12:9092" >> /opt/kafka/config/server.properties
}

start_kafka_services() {
    echo "Starting Zookeeper and Kafka..."
    /opt/kafka/bin/zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties
    /opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties
    sleep 10
    /opt/kafka/bin/kafka-topics.sh --create --topic nginx-logs --bootstrap-server 192.168.56.12:9092 --partitions 1 --replication-factor 1
    # /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server 192.168.56.12:9092 --topic nginx-logs --group nginx-logs-consumer --from-beginning

}

start_kafka_ui() {
    echo "Installing Docker..."
    sudo apt install docker.io -y
    echo "Configuring Docker..."
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
    # docker run hello-world

    echo "Starting Kafka UI..."
    docker run -d --name=kafka-ui \
    -p 8080:8080 \
    -e KAFKA_CLUSTERS_0_NAME=kafka \
    -e KAFKA_CLUSTERS_0_BOOTSTRAP_SERVERS=192.168.56.12:9092 \
    provectuslabs/kafka-ui

    docker ps
}

install_updates
install_node_exporter
install_java
install_kafka
start_kafka_services
start_kafka_ui
echo "Installation and configuration of Node Exporter and Kafka completed successfully!"