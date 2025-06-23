from kafka import KafkaConsumer
import json

# Kafka broker address (adjust if your Kafka is not on localhost:9092)
# You might need to port-forward Kafka service if running in Minikube:
# kubectl port-forward service/kafka 9092:9092
KAFKA_BROKER = 'localhost:9094'
TOPIC_NAME = 'output-topic'
GROUP_ID = 'flink-example-consumer-group'

def create_consumer():
    """Creates and returns a KafkaConsumer instance."""
    try:
        consumer = KafkaConsumer(
            TOPIC_NAME,
            bootstrap_servers=[KAFKA_BROKER],
            group_id=GROUP_ID,
            auto_offset_reset='earliest', # Start reading from the beginning of the topic
            enable_auto_commit=True,
            value_deserializer=lambda x: x.decode('utf-8')
        )
        print(f"Kafka consumer connected to {KAFKA_BROKER}, consuming from topic '{TOPIC_NAME}' with group '{GROUP_ID}'")
        return consumer
    except Exception as e:
        print(f"Error connecting to Kafka: {e}")
        return None

def consume_messages(consumer):
    """Continuously consumes messages from the Kafka topic."""
    print("Waiting for messages...")
    try:
        for message in consumer:
            print(f"Received message: {message.value}")
    except KeyboardInterrupt:
        print("\nConsumer stopped by user.")
    except Exception as e:
        print(f"An error occurred during consumption: {e}")
    finally:
        consumer.close()
        print("Consumer closed.")

if __name__ == "__main__":
    consumer = create_consumer()
    if consumer:
        consume_messages(consumer)
    else:
        print("Consumer could not be created. Exiting.") 