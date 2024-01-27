#!/usr/bin/env bash

# terraform init 
terraform -chdir=./terraform init

# deploy aws infra by terraform 
terraform -chdir=./terraform apply -auto-approve

