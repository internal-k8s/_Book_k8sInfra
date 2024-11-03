#!/usr/bin/env bash

helm install prometheus-stack edu/kube-prometheus-stack  \
--set defaultRules.create="false" \
--set defaultRules.rules.alertmanager="false" \
--set alertmanager.enabled="false" \
--set prometheus.service.type="LoadBalancer" \
--set server.service.loadBalancerIP="192.168.1.11" \
--set prometheus.service.port="80" \
--set prometheus.prometheusSpec.scrapeInterval="15s" \
--set prometheus.prometheusSpec.evaluationInterval="15s" \
--set grafana.adminPassword="admin" \
--set grafana.image.tag="11.3.0" \
--set grafana.service.type="LoadBalancer" \
--set grafana.service.loadBalancerIP="192.168.1.12" \
--set grafana.persistence.enabled="true" \
--set grafana."grafana\.ini".server.root_url="http://192.168.1.12" \
--namespace=monitoring \
--create-namespace \
-f $HOME/_Book_k8sInfra/ch7/7.1.2/values.yaml