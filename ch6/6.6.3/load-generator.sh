#!/usr/bin/env bash
echo "Trace generate."
echo "Write data to redis from user(id: 1000)"
curl -X 'POST' -w '\n' \
  'http://192.168.1.13/api/v1/score/1000' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
  "score": 100
}'
echo "Read data to user(id: 1000) from from redis"
curl -X 'GET' -w '\n' \
  'http://192.168.1.13/api/v1/score/1000' \
  -H 'accept: application/json'