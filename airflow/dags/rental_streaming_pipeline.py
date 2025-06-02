from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.providers.apache.flink.operators.flink import FlinkSubmitJobOperator
from datetime import datetime, timedelta
import sys
import os

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'rental_streaming_pipeline',
    default_args=default_args,
    description='Rental Car Streaming Pipeline',
    schedule_interval=timedelta(days=1),
    catchup=False
)

def start_gps_generator():
    sys.path.append('/opt/airflow/data-generator')
    from gps_data_generator import generate_gps_data
    generate_gps_data()

start_gps_generator_task = PythonOperator(
    task_id='start_gps_generator',
    python_callable=start_gps_generator,
    dag=dag
)

submit_flink_job = FlinkSubmitJobOperator(
    task_id='submit_flink_job',
    job_name='rental-gps-processor',
    jar_path='/opt/airflow/flink-jobs/target/rental-streaming-1.0-SNAPSHOT.jar',
    flink_config={
        'jobmanager.rpc.address': 'flink-jobmanager',
        'parallelism.default': '2'
    },
    dag=dag
)

start_gps_generator_task >> submit_flink_job 