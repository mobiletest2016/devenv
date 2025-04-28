### [Spark High Availability](spark_high_availability.md)  <br>

### INIT

Start a docker compose

Run: sudo bash add_docker_container_to_hosts.sh
Run: sudo sysctl -w vm.max_map_count=262144 

# All services (Very heavy)

sudo docker-compose -f big_data_docker_compose.yml up  <br>

After a min run:  <br>
$ bash mongo_enable_shard.sh  <br>


Error and fix:  <br>
  For error [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]:  <br>
    $ sudo sysctl -w vm.max_map_count=262144  <br>


Elastic check nodes:  <br>
curl -X GET "localhost:9200/_cat/nodes?v&pretty"  <br>


# Airflow

https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html  <br>

After downloading docker-compose remove all restart: always to avoid starting containers at boot  <br>
	$ sed -i '/restart/d' airflow-docker-compose.yml   <br>


Commands:	(Refer to above link for new commands)  <br>
mkdir airflow  <br>
cd airflow/  <br>
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.6.3/docker-compose.yaml'  <br>
mv docker-compose.yml airflow-docker-compose.yml  <br>

mkdir -p ./dags ./logs ./plugins ./config  <br>
AIRFLOW_UID=50000  <br>
echo -e "AIRFLOW_UID=$(id -u)" > .env  <br>

Initialize the database:  <br>
sudo docker compose -f airflow-docker-compose.yml up airflow-init		(Should terminate after few minutes)  <br>

After above command run airflow:  <br>
sudo docker compose -f airflow-docker-compose.yml up -d  <br>

Web UI: <br>
URL: http://localhost:8080/ <br>
Username: airflow  <br>
Password: airflow  <br>


# Kafka  <br>

To use Kafka from host, start docker-compose and add these entries to /etc/hosts  <br>

127.0.0.1 kafka-0  <br>
127.0.0.1 kafka-1  <br>
127.0.0.1 kafka-2  <br>


### Start Kafka producer and consumer:  <br>
sudo docker exec -it kafka-0 /opt/bitnami/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka-0:19092,kafka-1:29092,kafka-2:39092 --topic test --from-beginning  <br>
sudo docker exec -it kafka-0 /opt/bitnami/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka-0:19092,kafka-1:29092,kafka-2:39092 --topic test  <br>

(Type messages in producer)  <br>

### Create a new topic (10 partitions):  <br>
sudo docker exec -ti kafka-0 /opt/bitnami/kafka/bin/kafka-topics.sh --create --topic hello --partitions 10 --bootstrap-server kafka-0:19092,kafka-1:29092,kafka-2:39092

### Create a new topic (10 partitions, 3 replication factor):  <br>
sudo docker exec -it kafka-0 /opt/bitnami/kafka/bin/kafka-topics.sh --create --topic hello2 --bootstrap-server --replication-factor 3 --partitions 3 kafka-0:19092,kafka-1:29092,kafka-2:39092  <br>

### To list all topics:  <br>
sudo docker exec -it kafka-0 /opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server kafka-0:19092,kafka-1:29092,kafka-2:39092  <br>

### Partition balancing <br>
Run 1 consumer and one producer <br>

sudo docker exec -it kafka-0 /opt/bitnami/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka-0:19092,kafka-1:29092,kafka-2:39092 --topic hello --from-beginning --consumer-property group.id=group1  <br>
sudo docker exec -it kafka-0 /opt/bitnami/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka-0:19092,kafka-1:29092,kafka-2:39092 --topic hello  <br>

Start 2nd consumer and watch docker log for rebalancing <br>
sudo docker exec -it kafka-0 /opt/bitnami/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka-0:19092,kafka-1:29092,kafka-2:39092 --topic hello --from-beginning --consumer-property group.id=group1  <br>

# Spark:  <br>

Make sure INIT steps are done

UI: http://localhost:8080/  <br>
Submit a Spark job:  <br>
sudo docker run -it --rm --network="big_data_default" bde2020/spark-submit:3.2.0-hadoop3.2 /spark/bin/spark-submit --master spark://spark-master:7077 --class org.apache.spark.examples.SparkPi /spark/examples/jars/spark-examples_2.12-3.2.0.jar

If any error is seen check the network parameter and spark master container name and ports

Run a Spark job using spark master:  <br>
sudo docker cp out/artifacts/Spark_jar/mysql-connector-java-8.0.28.jar spark-master:/tmp/  <br>
sudo docker cp out/artifacts/Spark_jar/mysql-connector-java-8.0.28.jar spark-master:/tmp/  <br>
sudo docker exec -it spark-master /spark/bin/spark-submit --master spark://spark-master:7077 --class adv.ReadMySQL --jars /tmp/mysql-connector-java-8.0.28.jar /tmp/Spark.jar  <br>


# Flink <br>

Flink UI: http://localhost:8091  <br>
sudo docker ps (Take the Flink jobmanager container id)  <br>
flink_jobmanager_container=4403e9d22b12  <br>
sudo docker exec -it $flink_jobmanager_container /opt/flink/bin/flink run /opt/flink/examples/streaming/TopSpeedWindowing.jar  <br>

# Flink SQL <br>

Tested with version: flink:1.18-scala_2.12

sudo docker exec -ti kafka-0 /opt/bitnami/kafka/bin/kafka-topics.sh --create --topic hello --partitions 10 --bootstrap-server kafka-0:19092,kafka-1:29092,kafka-2:39092 <br>

Download dependency jars on host machine and copy it to docker (Downloading on docker is having issues) <br>
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/3.3.0-1.20/flink-connector-kafka-3.3.0-1.20.jar <br>
wget https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.3.0-1.20/flink-sql-connector-kafka-3.3.0-1.20.jar <br>
wget https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.8.1/kafka-clients-3.8.1.jar <br>

sudo docker exec jobmanager mkdir /jars/
sudo docker cp flink-sql-connector-kafka-3.3.0-1.20.jar jobmanager:/jars/ <br>
sudo docker cp flink-connector-kafka-3.3.0-1.20.jar jobmanager:/jars/ <br>
sudo docker cp kafka-clients-3.8.1.jar jobmanager:/jars/ <br>

sudo docker exec -it jobmanager /opt/flink/bin/sql-client.sh -l /jars/ <br>
OR
sudo docker exec -it jobmanager /opt/flink/bin/sql-client.sh -l file:///jars/ (For new version) <br>

```
CREATE TABLE KafkaTable (
  `data` STRING
) WITH (
  'connector' = 'kafka',
  'topic' = 'hello',
  'properties.bootstrap.servers' = 'kafka-0:19092,kafka-1:29092,kafka-2:39092',
  'properties.group.id' = 'group1',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'csv'
)
```

sudo docker exec -it kafka-0 /opt/bitnami/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka-0:19092,kafka-1:29092,kafka-2:39092 --topic hello
(Enter words)

Flink SQL> select * from KafkaTable

Flink SQL> select data, count(data) from KafkaTable group by data 

# HDFS/YARN <br>

HDFS UI: http://localhost:9870/  <br>
YARN UI: http://localhost:8088/  <br>


# Hive:  <br>

sudo docker exec -it hive-server bash  <br>
#/opt/hive/bin/beeline -u jdbc:hive2://localhost:10000  <br>
> CREATE TABLE pokes (foo INT, bar STRING);  <br>
> LOAD DATA LOCAL INPATH '/opt/hive/examples/files/kv1.txt' OVERWRITE INTO TABLE pokes;  <br>
> select * from pokes;  <br>


# Hbase:  <br>

sudo docker exec -it hbase-master bash  <br>
#/opt/hbase-1.2.6/bin/hbase shell  <br>
> list  <br>
> create 'person','person_info'  <br>
> put 'person',1,'person_info:name','Ram'  <br>
> put 'person',2,'person_info:name','Sham'  <br>
> put 'person',3,'person_info:name','Guru'  <br>
> scan 'person'  <br>
> get 'person',1  <br>



# Cassandra:  <br>

sudo docker exec -it cassandra1 cqlsh  <br>


# Solr:  <br>

Visit: http://localhost:8983/solr/  <br>



### Query hive with trino:  <br>

sudo docker exec -it $trino_container trino --server localhost:8080 --catalog hive --schema default  <br>

trino:default> show CATALOGS;		(Make sure hive is availble)  <br>

trino:default> select * from pokes;  <br>
trino:default> select foo, count(*) as cnt from pokes group by foo;  <br>
