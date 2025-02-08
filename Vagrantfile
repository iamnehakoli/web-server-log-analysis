Vagrant.configure("2") do |config|

  config.vm.box = "bento/debian-11"

    # Nginx Server
    config.vm.define "nginx" do |nginx|
    nginx.vm.hostname = "nginx"
    nginx.vm.network "private_network", ip: "192.168.56.10"
    nginx.vm.provision "shell", path: "provision_nginx.sh"

    # Set the VM name in the hypervisor
    nginx.vm.provider "virtualbox" do |vb|
      vb.name = "nginx"
    end
  end

  # Apache Server
  config.vm.define "apache" do |apache|
    apache.vm.hostname = "apache"
    apache.vm.network "private_network", ip: "192.168.56.11"
    apache.vm.provision "shell", path: "provision_apache.sh"

    # Set the VM name in the hypervisor
    apache.vm.provider "virtualbox" do |vb|
      vb.name = "apache"
    end
  end

  # Kafka Server
  config.vm.define "kafka" do |kafka|
    kafka.vm.hostname = "kafka"
    kafka.vm.network "private_network", ip: "192.168.56.12"

    # Set the VM name in the hypervisor
    kafka.vm.provider "virtualbox" do |vb|
      vb.name = "kafka"
    end

    kafka.vm.provision "shell", path: "provision_kafka.sh"
  end

  # Storage: Prometheus and Elasticsearch
  config.vm.define "storage" do |storage|
    storage.vm.hostname = "storage"
    storage.vm.network "private_network", ip: "192.168.56.13"
    storage.vm.provision "shell", path: "provision_storage.sh"

    # Set the VM name in the hypervisor
    storage.vm.provider "virtualbox" do |vb|
      vb.name = "storage"
    end
  end

  # Hadoop Server
  config.vm.define "hadoop" do |hadoop|
    hadoop.vm.hostname = "hadoop"
    hadoop.vm.network "private_network", ip: "192.168.56.14"
    hadoop.vm.provider "virtualbox" do |vb|
      vb.name = "hadoop"
      vb.memory = "2048" # Hadoop might need more memory
    end

    hadoop.vm.provision "shell", path: "provision_hadoop.sh"
  end

  # Visualization: Grafana and Kibana
  config.vm.define "monitoring" do |monitoring|
    monitoring.vm.hostname = "visualization"
    monitoring.vm.network "private_network", ip: "192.168.56.15"
    monitoring.vm.provision "shell", path: "provision_monitoring.sh"

    # Set the VM name in the hypervisor
    monitoring.vm.provider "virtualbox" do |vb|
      vb.name = "monitoring"
    end
  end
end
