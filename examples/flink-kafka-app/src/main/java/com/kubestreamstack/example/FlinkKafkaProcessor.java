package com.kubestreamstack.example;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.connector.base.DeliveryGuarantee;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Properties;

public class FlinkKafkaProcessor {

    public static void main(String[] args) throws Exception {
        // Set up the streaming execution environment
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // Kafka broker address (adjust if your Kafka is not on localhost:9092)
        String kafkaBroker = "kafka:9092"; // Assuming Kafka is accessible via this address

        System.out.println("Using Kafka broker: " + kafkaBroker);

        // Input and Output Kafka topics
        String inputTopic = "input-topic";
        String outputTopic = "output-topic";

        // Kafka Consumer Properties
        Properties consumerProps = new Properties();
        consumerProps.setProperty("group.id", "flink-kafka-processor-group");

        // Create Kafka Source
        KafkaSource<String> source = KafkaSource.<String>builder()
                .setBootstrapServers(kafkaBroker)
                .setTopics(inputTopic)
                .setGroupId(consumerProps.getProperty("group.id"))
                .setStartingOffsets(OffsetsInitializer.earliest())
                .setValueOnlyDeserializer(new SimpleStringSchema())
                .build();

        // Read data from Kafka
        DataStream<String> inputMessages = env.fromSource(source, WatermarkStrategy.noWatermarks(), "Kafka Source");

        // Process the messages: convert to uppercase and add a timestamp
        DataStream<String> processedMessages = inputMessages
                .map(message -> {
                    String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                    return "PROCESSED: " + message.toUpperCase() + " - " + timestamp;
                })
                .name("Uppercase and Timestamp Transformation");

        // Kafka Producer Properties
       // Properties producerProps = new Properties();
       // producerProps.setProperty("transaction.timeout.ms", "60000"); // 1 minute

        // Create Kafka Sink
        KafkaSink<String> sink = KafkaSink.<String>builder()
                .setBootstrapServers(kafkaBroker)
                .setRecordSerializer(KafkaRecordSerializationSchema.builder()
                        .setValueSerializationSchema(new SimpleStringSchema())
                        .setTopic(outputTopic)
                        .build())
                .setDeliveryGuarantee(DeliveryGuarantee.AT_LEAST_ONCE)
                .setTransactionalIdPrefix("flink-transactional-id") // Required for AT_LEAST_ONCE
                .build();

        // Write processed data to Kafka
        processedMessages.sinkTo(sink).name("Kafka Sink");

        // Execute the Flink job
        env.execute("Flink Kafka Processor 2");
    }
} 