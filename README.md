# Web Server Log Analysis System

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Setup and Deployment](#setup-and-deployment)
  - [Provision Virtual Machines](#provision-virtual-machines)
- [Kafka Log Consumption](#kafka-log-consumption)
  - [Consume Nginx Logs](#consume-nginx-logs)
  - [Consume Apache Logs](#consume-apache-logs)
- [Running .NET Core Kafka Consumer](#running-net-core-kafka-consumer)
- [Generating Logs](#generating-logs)
  - [Generate Nginx Logs](#generate-nginx-logs)
  - [Generate Apache Logs](#generate-apache-logs)
- [Service Endpoints](#service-endpoints)
- [Notes](#notes)

---

## Overview
The **Web Server Log Analysis System** is designed to collect, process, and analyze web server logs using Kafka, Hadoop, and .NET Core applications. Logs from Nginx and Apache are consumed via Kafka and stored in Hadoop for further processing. Monitoring and visualization are handled using Prometheus, Grafana, and Kibana.

## Architecture

![System Architecture](./images/web-server-log-analysis-system-architecture.png)

---

## Setup and Deployment

### Clone the Repository
To clone the repository, run the following command:

```sh
cd ~/Documents/
git clone https://github.com/nehachitodkar/web-server-log-analysis.git
cd web-server-log-analysis
```
### Provision Virtual Machines
To set up the required virtual machines, run the following command:

```sh
vagrant up storage; vagrant up kafka; vagrant up hadoop; vagrant up monitoring; vagrant up nginx; vagrant up apache
```

---

## Kafka Log Consumption
### Consume Nginx Logs
#### Step 1: Login to Kafka VM
Open a new terminal and run below command,
```sh
vagrant ssh kafka
```

#### Step 2: Consume Nginx Logs from Kafka Topic
Run the below command in the same terminal,
```sh
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server 192.168.56.12:9092 --topic nginx-logs --from-beginning
```

### Consume Apache Logs
#### Step 1: Login to second instance of Kafka VM
Open a new terminal and run below command,
```sh
vagrant ssh kafka
```

#### Step 2: Consume Apache Logs from Kafka Topic
Run the below command in the same terminal,
```sh
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server 192.168.56.12:9092 --topic apache-logs --from-beginning
```

---

## Running .NET Core Kafka Consumer
Open a new terminal to start the .NET Core application that reads Kafka messages and stores them in HDFS:

```sh
cd Documents\web-server-log-analysis\KafkaConsumerApp
dotnet run
```

---

## Generating Logs

### Generate Nginx Logs
#### Step 1: Login to Nginx VM
Run below command in a separate terminal,
```sh
vagrant ssh nginx
```
Run below command once you're in the terminal, to switch to root user
```sh
sudo su
```
#### Step 2: Clone and Set Up Fake Log Generator
```sh
git clone https://github.com/nehachitodkar/fake-log-generator.git
virtualenv dev
source dev/bin/activate
cd fake-log-generator
pip install -r requirements.txt
python fake-log-generator.py -n 0 --log-type NGINX --sleep 1
```

### Generate Apache Logs
#### Step 1: Login to Apache VM
Run below command in a separate terminal,
```sh
vagrant ssh apache
```
Run below command once you're in the terminal, to switch to root user
```sh
sudo su
```
#### Step 2: Clone and Set Up Fake Log Generator
```sh
git clone https://github.com/nehachitodkar/fake-log-generator.git
virtualenv dev
source dev/bin/activate
cd fake-log-generator
pip install -r requirements.txt
python fake-log-generator.py -n 0 --log-type APACHE --sleep 1
```

---

## Service Endpoints
- **Nginx (nginx)**: [http://192.168.56.10](http://192.168.56.10)
- **Apache (apache)**: [http://192.168.56.11](http://192.168.56.11)
- **Kafka (kafka)**: [http://192.168.56.12:8080](http://192.168.56.12:8080)
- **Prometheus (storage)**: [http://192.168.56.13:9090](http://192.168.56.13:9090/targets)
- **Elasticsearch (storage)**: [http://192.168.56.13:9200](http://192.168.56.13:9200)
- **Hadoop (hadoop)**: [http://192.168.56.14:9870](http://192.168.56.14:9870)
- **Grafana (monitoring)**: [http://192.168.56.15:3000](http://192.168.56.15:3000)
- **Kibana (monitoring)**: [http://192.168.56.15:5601](http://192.168.56.15:5601)

---

## Notes
- Ensure all virtual machines are up and running before proceeding.
- Kafka is used to consume logs from Nginx and Apache and store them in Hadoop.
- Grafana, Kibana, and Prometheus provide monitoring and visualization capabilities.
