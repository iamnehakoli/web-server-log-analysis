Vagrant.configure("2") do |config|

  config.vm.box = "bento/debian-12"

  # Disable synced folders for simplicity
  config.vm.synced_folder ".", "/vagrant", disabled: false

  # Storage: Prometheus and Elasticsearch
  config.vm.define "storage" do |storage|
    storage.vm.hostname = "storage-server"
    storage.vm.network "private_network", ip: "192.168.56.12"
    storage.vm.provision "shell", path: "provision_storage.sh"
    
    # Set the VM name in the hypervisor
    storage.vm.provider "parallels" do |pr|
      pr.name = "database-vm"
    end
  end

  # Visualization: Grafana and Kibana
  config.vm.define "monitoring" do |monitoring|
    monitoring.vm.hostname = "visualization-server"
    monitoring.vm.network "private_network", ip: "192.168.56.13"
    monitoring.vm.provision "shell", path: "provision_monitoring.sh"

    # Set the VM name in the hypervisor
    monitoring.vm.provider "parallels" do |pr|
      pr.name = "monitoring-vm"
    end
  end

   # Nginx Server
   config.vm.define "nginx" do |nginx|
    nginx.vm.hostname = "nginx-server"
    nginx.vm.network "private_network", ip: "192.168.56.10"
    nginx.vm.provision "shell", path: "provision_nginx.sh"

    # Set the VM name in the hypervisor
    nginx.vm.provider "parallels" do |pr|
      pr.name = "nginx-vm"
    end
  end

  # Apache Server
  config.vm.define "apache" do |apache|
    apache.vm.hostname = "apache-server"
    apache.vm.network "private_network", ip: "192.168.56.11"
    apache.vm.provision "shell", path: "provision_apache.sh"

    # Set the VM name in the hypervisor
    apache.vm.provider "parallels" do |pr|
      pr.name = "apache-vm"
    end
  end

  # Kafka Server
  config.vm.define "kafka" do |kafka|
    kafka.vm.hostname = "kafka-server"
    kafka.vm.network "private_network", ip: "192.168.56.14"
  end

  # Hadoop Server
  config.vm.define "hadoop" do |hadoop|
    hadoop.vm.hostname = "hadoop-server"
    hadoop.vm.network "private_network", ip: "192.168.56.15"
    hadoop.vm.provider "virtualbox" do |vb|
      vb.memory = "2048" # Hadoop might need more memory
    end
  end
end