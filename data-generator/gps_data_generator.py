from kafka import KafkaProducer
import json
import random
import time
from datetime import datetime

producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda x: json.dumps(x).encode('utf-8')
)

def generate_gps_data():
    car_ids = list(range(1, 101))  # 100 cars
    
    while True:
        for car_id in car_ids:
            gps_data = {
                'car_id': car_id,
                'timestamp': datetime.now().isoformat(),
                'latitude': random.uniform(25.0, 49.0),  # US latitude range
                'longitude': random.uniform(-125.0, -67.0),  # US longitude range
                'speed': random.uniform(0, 120),  # Speed in km/h
                'fuel_level': random.uniform(0, 100),  # Fuel level in percentage
                'engine_status': random.choice(['running', 'idle', 'stopped'])
            }
            
            producer.send('car-gps-data', gps_data)
        
        time.sleep(1)  # Generate data every second

if __name__ == "__main__":
    generate_gps_data() 