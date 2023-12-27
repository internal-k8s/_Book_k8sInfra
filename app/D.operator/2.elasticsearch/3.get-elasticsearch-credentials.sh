#!/bin/bash


echo "elastic 패스워드: $(kubectl get secret elasticsearch-es-elastic-user -o jsonpath='{ .data.elastic }' | base64 -d)"