#!/usr/bin/env bash

kubectl exec -it elasticsearch-es-default-0 -- curl -k https://elasticsearch-es-default-0.elasticsearch-es-default.default.svc.cluster.local:9200 -u elastic:$1
