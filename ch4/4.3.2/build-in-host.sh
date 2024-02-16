#!/usr/bin/env bash
./mvnw clean package
docker build -t optimal-img .
