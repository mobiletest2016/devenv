#!/bin/bash

if [ "$EUID" -ne 0 ]
then
  echo "RUN THIS SCRIPT WITH SUDO...."
  sleep 3
  exit
fi

sed -i '/#docker/d' /etc/hosts

sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' /etc/hosts

echo -en "\n\n" >> /etc/hosts


docker ps | tail -n+2 | cut -f1 -d' ' | xargs docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{ .Name }}     #docker' | sed 's/ \// /' >> /etc/hosts
