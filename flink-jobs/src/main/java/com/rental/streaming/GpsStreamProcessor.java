package com.rental.streaming;

import org.apache.flink.api.common.functions.AggregateFunction;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.windowing.assigners.TumblingProcessingTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import com.google.gson.JsonParser;
import com.google.gson.JsonObject;

import java.util.Properties;

public class GpsStreamProcessor {
    public static void main(String[] args) throws Exception {
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        Properties properties = new Properties();
        properties.setProperty("bootstrap.servers", "kafka:9092");
        properties.setProperty("group.id", "gps-processor");

        FlinkKafkaConsumer<String> consumer = new FlinkKafkaConsumer<>(
            "car-gps-data",
            new SimpleStringSchema(),
            properties
        );

        DataStream<String> stream = env.addSource(consumer);

        // Process GPS data
        stream
            .map(value -> {
                JsonObject json = JsonParser.parseString(value).getAsJsonObject();
                return new GpsData(
                    json.get("car_id").getAsString(),
                    json.get("speed").getAsDouble(),
                    json.get("latitude").getAsDouble(),
                    json.get("longitude").getAsDouble()
                );
            })
            .keyBy(GpsData::getCarId)
            .window(TumblingProcessingTimeWindows.of(Time.minutes(5)))
            .aggregate(new AverageSpeedAggregator())
            .map(result -> {
                JsonObject output = new JsonObject();
                output.addProperty("car_id", result.getCarId());
                output.addProperty("avg_speed", result.getAverageSpeed());
                output.addProperty("window_end", result.getWindowEnd());
                return output.toString();
            });

        env.execute("GPS Stream Processor");
    }
}

class GpsData {
    private String carId;
    private double speed;
    private double latitude;
    private double longitude;

    public GpsData(String carId, double speed, double latitude, double longitude) {
        this.carId = carId;
        this.speed = speed;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public String getCarId() { return carId; }
    public double getSpeed() { return speed; }
}

class AverageSpeedAggregator implements AggregateFunction<GpsData, SpeedAccumulator, SpeedResult> {
    @Override
    public SpeedAccumulator createAccumulator() {
        return new SpeedAccumulator();
    }

    @Override
    public SpeedAccumulator add(GpsData value, SpeedAccumulator acc) {
        acc.sum += value.getSpeed();
        acc.count++;
        acc.carId = value.getCarId();
        return acc;
    }

    @Override
    public SpeedResult getResult(SpeedAccumulator acc) {
        return new SpeedResult(acc.carId, acc.sum / acc.count, System.currentTimeMillis());
    }

    @Override
    public SpeedAccumulator merge(SpeedAccumulator a, SpeedAccumulator b) {
        a.sum += b.sum;
        a.count += b.count;
        return a;
    }
}

class SpeedAccumulator {
    public String carId;
    public double sum = 0;
    public int count = 0;
}

class SpeedResult {
    private String carId;
    private double averageSpeed;
    private long windowEnd;

    public SpeedResult(String carId, double averageSpeed, long windowEnd) {
        this.carId = carId;
        this.averageSpeed = averageSpeed;
        this.windowEnd = windowEnd;
    }

    public String getCarId() { return carId; }
    public double getAverageSpeed() { return averageSpeed; }
    public long getWindowEnd() { return windowEnd; }
} 