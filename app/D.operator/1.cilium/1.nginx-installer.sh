#!/usr/bin/env bash

# TODO: chk-hn 써보는게 어떨까?
kubectl create deploy nginx --image nginx:stable
kubectl expose deploy nginx --name nginx --type LoadBalancer --port 80 --target-port 80