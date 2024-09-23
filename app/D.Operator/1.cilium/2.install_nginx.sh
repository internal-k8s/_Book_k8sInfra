#!/usr/bin/env bash

kubectl create deploy nginx --image nginx:stable
kubectl expose deploy nginx --name nginx --type LoadBalancer --port 80 --target-port 80
