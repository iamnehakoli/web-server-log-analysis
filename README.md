# Kafka, Hadoop, and Log Processing Setup

## Provision the Virtual Machines

Run the following command to provision the necessary VMs:

```sh
vagrant up storage; vagrant up kafka; vagrant up hadoop; vagrant up monitoring; vagrant up nginx; vagrant up apache
```

## Kafka Log Consumption

### Step 1: Login to Kafka VM
Open a new terminal, and run below command to login
```sh
vagrant ssh kafka
```

### Step 2: Consume Nginx Logs from Kafka Topic
```sh
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server 192.168.56.12:9092 --topic nginx-logs --from-beginning
```

### Step 3: Consume Apache Logs from Kafka Topic (In a new terminal)
Open a new terminal, and run below command to login
```sh
vagrant ssh kafka
```
Run Kafka consumer script
```sh
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server 192.168.56.12:9092 --topic apache-logs --from-beginning
```

## Running the .NET Core Kafka Consumer
a. Open a new terminal and run the following commands to start the .NET Core application 
that reads Kafka messages and stores them in HDFS \
b. Change working directory
```sh
cd C:\Users\neha.koli\Desktop\msc-project\latest-dev\KafkaConsumerApp 
```
Run .NET application to read Kafka messages and write them to HDFS
```sh
dotnet run
```

## Generating Logs

### Step 1: Generate Nginx Logs (in a new terminal)
Open a new terminal, and run below command to login
Login to Nginx VM
```sh
vagrant ssh nginx
```

Clone, install required dependencies and run script to generate fake Nginx logs
```sh
sudo apt install git virtualenv -y
git clone https://github.com/nehachitodkar/fake-log-generator.git
virtualenv dev
source dev/bin/activate
cd fake-log-generator
pip install -r requirements.txt
python fake-log-generator.py -n 0 --log-type NGINX --min-delay 1 --max-delay 100 | sudo tee /var/log/nginx/access.log
```

### Step 2: Generate Apache Logs (in a new terminal)
Open a new terminal, and run below command to login
Login to Nginx VM
```sh
vagrant ssh apache
```

Clone, install required dependencies and run script to generate fake Apache logs
```sh
sudo apt install git virtualenv -y
git clone https://github.com/nehachitodkar/fake-log-generator.git
virtualenv dev
source dev/bin/activate
cd fake-log-generator
pip install -r requirements.txt
python fake-log-generator.py -n 0 --log-type APACHE --min-delay 1 --max-delay 100 | sudo tee /var/log/apache2/access.log
```

### Service Endpoints
- **Nginx**: <a href="http://192.168.56.10" target="_blank" rel="noopener noreferrer">http://192.168.56.10</a>
- **Apache**: <a href="http://192.168.56.11" target="_blank" rel="noopener noreferrer">http://192.168.56.11</a>
- **Prometheus**: <a href="http://192.168.56.13:9090/targets" target="_blank" rel="noopener noreferrer">http://192.168.56.13:9090</a>
- **Elasticsearch**: <a href="http://192.168.56.13:9200" target="_blank" rel="noopener noreferrer">http://192.168.56.13:9200</a>
- **Grafana**: <a href="http://192.168.56.15:3000" target="_blank" rel="noopener noreferrer">http://192.168.56.15:3000</a>
- **Kibana**: <a href="http://192.168.56.13:5601" target="_blank" rel="noopener noreferrer">http://192.168.56.13:5601</a>
- **Hadoop**: <a href="http://192.168.56.14:9870" target="_blank" rel="noopener noreferrer">http://192.168.56.14:9870</a>


## Notes
- Ensure that all VMs are up and running before proceeding.
- Logs are consumed from Kafka and stored in Hadoop via the .NET Core application.
- Grafana, Kibana, and Prometheus provide monitoring and visualization.
