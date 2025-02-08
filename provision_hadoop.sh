#!/bin/bash

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

# ============================== Step 1: Update System ==============================
echo "Updating system packages..."
sudo apt update -y

# ============================== Step 2: Install Required Packages ==============================
echo "Installing required packages..."
sudo apt install -y openjdk-11-jdk ssh rsync

# Verify Java installation
JAVA_VERSION=$(java -version 2>&1 | grep version | awk '{print $3}')
if [[ -z "$JAVA_VERSION" ]]; then
  echo "Java installation failed. Exiting..."
  exit 1
else
  echo "Java installed successfully: $JAVA_VERSION"
fi

# ============================== Step 3: Create Hadoop User ==============================
echo "Creating 'hadoop' user..."
sudo adduser --disabled-password --gecos "" hadoop
sudo usermod -aG sudo hadoop

# Set up passwordless SSH for the 'hadoop' user
echo "Setting up passwordless SSH for 'hadoop' user..."
sudo su - hadoop <<EOF
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
ssh-keyscan localhost >> ~/.ssh/known_hosts
EOF

# ============================== Step 4: Download and Install Hadoop ==============================
echo "Downloading and installing Hadoop..."
HADOOP_VERSION="3.3.6"
HADOOP_URL="https://downloads.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION-aarch64.tar.gz"

# Download Hadoop
wget -q $HADOOP_URL -O /tmp/hadoop.tar.gz

# Extract Hadoop to /opt/hadoop
sudo tar -xzf /tmp/hadoop.tar.gz -C /opt/
sudo mv /opt/hadoop-$HADOOP_VERSION /opt/hadoop
sudo chown -R hadoop:hadoop /opt/hadoop

# Clean up downloaded file
rm -f /tmp/hadoop.tar.gz

# ============================== Step 5: Configure Environment Variables ==============================
echo "Configuring environment variables for 'hadoop' user..."
sudo su - hadoop <<EOF
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64' >> ~/.bashrc
echo 'export HADOOP_HOME=/opt/hadoop' >> ~/.bashrc
echo 'export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin' >> ~/.bashrc
source ~/.bashrc
EOF

# ============================== Step 6: Configure Hadoop ==============================
echo "Configuring Hadoop..."

# Update core-site.xml
sudo su - hadoop <<EOF
cat <<EOT > /opt/hadoop/etc/hadoop/core-site.xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://192.168.56.14:9000</value>
    </property>
</configuration>
EOT
EOF

# Update hdfs-site.xml
sudo su - hadoop <<EOF
cat <<EOT > /opt/hadoop/etc/hadoop/hdfs-site.xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>

    <!-- DataNode HTTP address -->
    <property>
        <name>dfs.datanode.http.address</name>
        <value>192.168.56.14:9864</value>
    </property>

    <!-- Enable WebHDFS -->
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>

    <!-- Disable hostname resolution -->
    <property>
        <name>dfs.client.use.datanode.hostname</name>
        <value>false</value>
    </property>

    <!-- Support append operations -->
    <property>
        <name>dfs.support.append</name>
        <value>true</value>
    </property>

   <!-- Set the NameNode's HTTP address -->
    <property>
        <name>dfs.namenode.http.address</name>
        <value>192.168.56.14:9870</value>
    </property>
</configuration>
EOT
EOF

# Create directories for NameNode and DataNode
sudo su - hadoop <<EOF
mkdir -p ~/hadoop_data/namenode
mkdir -p ~/hadoop_data/datanode
EOF

# Update hadoop-env.sh
sudo su - hadoop <<EOF
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64' >> /opt/hadoop/etc/hadoop/hadoop-env.sh
EOF

# ============================== Step 7: Format HDFS ==============================
echo "Formatting HDFS..."
sudo su - hadoop <<EOF
/opt/hadoop/bin/hdfs namenode -format
EOF

# ============================== Step 8: Start Hadoop Services ==============================
echo "Starting Hadoop services..."
sudo su - hadoop <<EOF
/opt/hadoop/sbin/start-all.sh
EOF

# ============================== Step 9: Verify Hadoop Installation ==============================
echo "Verifying Hadoop installation..."
sudo su - hadoop <<EOF
jps
EOF

echo "Verifying Hadoop installation..."
sudo su - hadoop <<EOF
/opt/hadoop/bin/hdfs dfs -mkdir /logs
/opt/hadoop/bin/hdfs dfs -chmod 777 /logs
/opt/hadoop/bin/hdfs dfs -touchz /logs/nginx.log
/opt/hadoop/bin/hdfs dfs -ls /logs
EOF

echo "Hadoop setup completed successfully!"