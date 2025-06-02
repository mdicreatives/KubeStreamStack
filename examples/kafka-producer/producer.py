from kafka import KafkaProducer
import json
import time

# Kafka broker address (adjust if your Kafka is not on localhost:9092)
# You might need to port-forward Kafka service if running in Minikube:
# kubectl port-forward service/kafka 9092:9092
KAFKA_BROKER = 'localhost:9092'
TOPIC_NAME = 'input-topic'

def create_producer():
    """Creates and returns a KafkaProducer instance."""
    try:
        producer = KafkaProducer(
            bootstrap_servers=[KAFKA_BROKER],
            value_serializer=lambda v: str(v).encode('utf-8')
        )
        print(f"Kafka producer connected to {KAFKA_BROKER}")
        return producer
    except Exception as e:
        print(f"Error connecting to Kafka: {e}")
        return None

def send_messages(producer):
    """Sends sample messages to the Kafka topic."""
    messages = [
        "Hello World",
        "Flink Kafka Example",
        "Streaming Data",
        "KubeStreamStack is awesome",
        "Real-time processing"
    ]

    print(f"Sending {len(messages)} messages to topic: {TOPIC_NAME}")
    for i, msg in enumerate(messages):
        try:
            future = producer.send(TOPIC_NAME, value=msg)
            record_metadata = future.get(timeout=10) # Block until send is complete
            print(f"Sent: '{msg}' to partition {record_metadata.partition} offset {record_metadata.offset}")
            time.sleep(1) # Wait a bit between messages
        except Exception as e:
            print(f"Failed to send message '{msg}': {e}")

    producer.flush() # Ensure all messages are sent
    print("All messages sent.")

if __name__ == "__main__":
    producer = create_producer()
    if producer:
        send_messages(producer)
        producer.close()
        print("Producer closed.")
    else:
        print("Producer could not be created. Exiting.") 