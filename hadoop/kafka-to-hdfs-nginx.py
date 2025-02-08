from confluent_kafka import Consumer
from hdfs import InsecureClient

# Kafka Configuration
KAFKA_BROKER = '192.168.56.12:9092'
KAFKA_TOPIC = 'nginx-logs'
KAFKA_GROUP = 'nginx_consumer_group'

# HDFS Configuration
HDFS_URL = 'http://192.168.56.14:9870'  # Change based on your setup
HDFS_PATH = '/logs/nginx.log'

# Initialize Kafka Consumer
consumer_conf = {
    'bootstrap.servers': KAFKA_BROKER,
    'group.id': KAFKA_GROUP,
    'auto.offset.reset': 'earliest'
}
consumer = Consumer(consumer_conf)
consumer.subscribe([KAFKA_TOPIC])

# Initialize HDFS Client
hdfs_client = InsecureClient(HDFS_URL, user='hadoop')

def write_to_hdfs(data):
    """Append data to HDFS file"""
    with hdfs_client.write(HDFS_PATH, encoding='utf-8', append=True) as writer:
        writer.write(data + "\n")

# Kafka Consumption Loop
try:
    print("Consuming messages from Kafka and writing to HDFS...")
    while True:
        msg = consumer.poll(1.0)  # Poll with a timeout of 1 second
        if msg is None:
            continue
        if msg.error():
            print(f"Kafka error: {msg.error()}")
            continue
        
        message_value = msg.value().decode('utf-8')
        print(f"Received: {message_value}")

        # Write to HDFS
        write_to_hdfs(message_value)

except KeyboardInterrupt:
    print("Stopping Kafka consumer...")
finally:
    consumer.close()

