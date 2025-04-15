#!/usr/bin/env bash
helm install colosseum edu/colosseum \
--namespace colosseum \
--create-namespace \
--set monitoring.mode=log 
