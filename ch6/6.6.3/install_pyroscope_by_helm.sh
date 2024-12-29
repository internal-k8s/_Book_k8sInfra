#!/usr/bin/env bash
helm install pyroscope edu/pyroscope \
--namespace monitoring \
--create-namespace 
