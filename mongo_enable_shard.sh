#Mongo DB related initialization from: https://stackoverflow.com/a/68552274
sudo docker exec -it mongos1 bash -c "echo 'rs.initiate({_id: \"mongors1conf\",configsvr: true, members: [{ _id : 0, host : \"mongocfg1:27019\", priority: 2 },{ _id : 1, host : \"mongocfg2:27019\" }, { _id : 2, host : \"mongocfg3:27019\" }]})' | mongo --host mongocfg1:27019"

sudo docker exec -it mongos1 bash -c "echo 'rs.initiate({_id : \"mongors1\", members: [{ _id : 0, host : \"mongors1n1:27018\", priority: 2 },{ _id : 1, host : \"mongors1n2:27018\" },{ _id : 2, host : \"mongors1n3:27018\" }]})' | mongo --host mongors1n1:27018"

sudo docker exec -it mongos1 bash -c "echo 'rs.initiate({_id : \"mongors2\", members: [{ _id : 0, host : \"mongors2n1:27018\", priority: 2 },{ _id : 1, host : \"mongors2n2:27018\" },{ _id : 2, host : \"mongors2n3:27018\" }]})' | mongo --host mongors2n1:27018"


sleep 15
sudo docker exec -it mongos1 bash -c "echo 'sh.addShard(\"mongors1/mongors1n1:27018,mongors1n2:27018,mongors1n2:27018\")' | mongo"
sudo docker exec -it mongos1 bash -c "echo 'sh.addShard(\"mongors2/mongors2n1:27018,mongors2n2:27018,mongors2n3:27018\")' | mongo"
