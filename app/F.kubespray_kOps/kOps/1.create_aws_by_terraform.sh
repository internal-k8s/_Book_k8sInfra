#!/usr/bin/env bash

# terraform init 
terraform init

# deploy aws infra by terraform 
terraform apply -auto-approve 

