sudo docker-compose -f big_data_docker_compose.yml up

After a min run:
$ bash mongo_enable_shard.sh


Error and fix:
  For error [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]:
    $ sudo sysctl -w vm.max_map_count=262144


Elastic check nodes:
curl -X GET "localhost:9200/_cat/nodes?v&pretty"



sudo docker ps (Take the kafka container id)
kafka_container=03f56284e52a


Start Kafka producer and consumer:
sudo docker exec -it $kafka_container /opt/bitnami/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka-0:9092,kafka-1:9092,kafka-2:9092 --topic test --from-beginning
sudo docker exec -it $kafka_container /opt/bitnami/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka-0:9092,kafka-1:9092,kafka-2:9092 --topic test

(Type messages in producer)

To create a new topic:
sudo docker exec -it $kafka_container /opt/bitnami/kafka/bin/kafka-topics.sh --create --topic sample-topic --bootstrap-server kafka-0:9092,kafka-1:9092,kafka-2:9092

To list all topics:
sudo docker exec -it $kafka_container /opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server kafka-0:9092,kafka-1:9092,kafka-2:9092

Spark:
UI: http://localhost:8080/
Submit a Spark job:
sudo docker run -it --rm --network="host" bde2020/spark-submit:3.2.0-hadoop3.2 /spark/bin/spark-submit --master spark://localhost:7077 --class org.apache.spark.examples.SparkPi /spark/examples/jars/spark-examples_2.12-3.2.0.jar		(This runs within image: bde2020/spark-submit not within the docker-compose network)
Run a Spark job within docker-compose network:
sudo docker cp out/artifacts/Spark_jar/mysql-connector-java-8.0.28.jar spark-master:/tmp/
sudo docker cp out/artifacts/Spark_jar/mysql-connector-java-8.0.28.jar spark-master:/tmp/
sudo docker exec -it spark-master /spark/bin/spark-submit --master spark://spark-master:7077 --class adv.ReadMySQL --jars /tmp/mysql-connector-java-8.0.28.jar /tmp/Spark.jar



Flink UI: http://localhost:8091
sudo docker ps (Take the kafka container id)
flink_container=4403e9d22b12
sudo docker exec -it 4403e9d22b12 /opt/flink/bin/flink run /opt/flink/examples/streaming/TopSpeedWindowing.jar


HDFS UI: http://localhost:9870/
YARN UI: http://localhost:8088/



Hive:
sudo docker exec -it $hive_server_container bash
# /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
> CREATE TABLE pokes (foo INT, bar STRING);
> LOAD DATA LOCAL INPATH '/opt/hive/examples/files/kv1.txt' OVERWRITE INTO TABLE pokes;
> select * from pokes;


Hbase:
sudo docker exec -it $hbase_master_container bash
# /opt/hbase-1.2.6/bin/hbase shell
> list
> create 'person','person_info'
> put 'person',1,'person_info:name','Ram'
> put 'person',2,'person_info:name','Sham'
> put 'person',3,'person_info:name','Guru'
> scan 'person'
> get 'person',1



Cassandra:
sudo docker exec -it $cassandra_container cqlsh


Solr:
Visit: http://localhost:8983/solr/



Query hive with trino:
sudo docker exec -it $trino_container trino --server localhost:8080 --catalog hive --schema default

trino:default> show CATALOGS;		(Make sure hive is availble)

trino:default> select * from pokes;
trino:default> select foo, count(*) as cnt from pokes group by foo;

