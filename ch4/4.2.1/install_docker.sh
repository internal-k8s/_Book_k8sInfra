#!/usr/bin/env bash

# Docker version 
docker_V='5:24.0.6-1~ubuntu.22.04~jammy' 

# install & enable docker 
apt-get install -y docker-ce=$docker_V docker-ce-cli=$docker_V 
systemctl enable --now docker
