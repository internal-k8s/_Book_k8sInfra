#!/usr/bin/env bash

# terraform init 
terraform -chdir=./tf-files init

# deploy aws infra by terraform 
terraform -chdir=./tf-files apply -auto-approve

