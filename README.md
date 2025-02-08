# Kafka, Hadoop, and Log Processing Setup

## Provision the Virtual Machines

Run the following command to provision the necessary VMs:

```sh
vagrant up storage; vagrant up kafka; vagrant up hadoop; vagrant up monitoring; vagrant up nginx; vagrant up apache
```

### Service Endpoints
- **Nginx**: [http://192.168.56.10](http://192.168.56.10)
- **Apache**: [http://192.168.56.11](http://192.168.56.11)
- **Prometheus**: [http://192.168.56.13:9090](http://192.168.56.13:9090/targets)
- **Elasticsearch**: [http://192.168.56.13:9200](http://192.168.56.13:9200)
- **Grafana**: [http://192.168.56.15:3000](http://192.168.56.15:3000)
- **Kibana**: [http://192.168.56.13:5601](http://192.168.56.13:5601)
- **Hadoop**: [http://192.168.56.14:9870](http://192.168.56.14:9870)

## Kafka Log Consumption

### Step 1: Login to Kafka VM
```sh
vagrant ssh kafka
```

### Step 2: Consume Nginx Logs from Kafka Topic
```sh
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server 192.168.56.12:9092 --topic nginx-logs --from-beginning
```

### Step 3: Consume Apache Logs from Kafka Topic (In a new terminal)
```sh
vagrant ssh kafka
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server 192.168.56.12:9092 --topic apache-logs --from-beginning
```

## Running the .NET Core Kafka Consumer
Run the following commands to start the .NET Core application that reads Kafka messages and stores them in HDFS:

```sh
cd C:\Users\neha.koli\Desktop\msc-project\latest-dev\KafkaConsumerApp 
dotnet run
```

## Generating Logs

### Step 1: Generate Nginx Logs (in a new terminal)
```sh
vagrant ssh nginx
sudo apt install git virtualenv -y
git clone https://github.com/nehachitodkar/fake-log-generator.git
virtualenv dev
source dev/bin/activate
cd fake-log-generator
pip install -r requirements.txt
python fake-log-generator.py -n 0 --log-type NGINX --min-delay 1 --max-delay 100 | sudo tee /var/log/nginx/access.log
```

### Step 2: Generate Apache Logs (in a new terminal)
```sh
vagrant ssh apache
sudo apt install git virtualenv -y
git clone https://github.com/nehachitodkar/fake-log-generator.git
virtualenv dev
source dev/bin/activate
cd fake-log-generator
pip install -r requirements.txt
python fake-log-generator.py -n 0 --log-type APACHE --min-delay 1 --max-delay 100 | sudo tee /var/log/apache2/access.log
```

## Notes
- Ensure that all VMs are up and running before proceeding.
- Logs are consumed from Kafka and stored in Hadoop via the .NET Core application.
- Grafana, Kibana, and Prometheus provide monitoring and visualization.
