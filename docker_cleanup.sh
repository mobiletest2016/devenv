sudo docker ps -a  | cut -f1 -d' ' | xargs sudo docker rm

sudo docker volume ls | cut -f2- -d' ' | xargs sudo docker volume rm

