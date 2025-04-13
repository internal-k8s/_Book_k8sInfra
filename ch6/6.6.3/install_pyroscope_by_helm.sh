#!/usr/bin/env bash
helm upgrade --reuse-values grafana-stack edu/grafana-stack \
--namespace monitoring \
--create-namespace \
--set pyroscope.enabled=true