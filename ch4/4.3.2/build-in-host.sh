#!/usr/bin/env bash
./mvnw clean package
apt-get install openjdk-21-jdk -y 
docker build -t optimal-img .
