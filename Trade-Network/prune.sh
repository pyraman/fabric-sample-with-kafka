#!/bin/bash

rm -rf crypto-config
docker kill $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker image prune -f
docker container prune -f
docker volume prune -f
docker network prune -f
docker system prune -f