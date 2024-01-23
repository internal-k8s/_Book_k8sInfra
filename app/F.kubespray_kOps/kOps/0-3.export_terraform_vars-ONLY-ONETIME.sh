#!/usr/bin/env bash

# check input $1 
if [ $# -eq 0 ]; then
  echo "usage: export_terraform_vars.sh <s3_name>"; exit 0
fi

# input terraform's vars
echo -e "\n# terraform vars" >> ~/.bashrc 
echo "export TF_VAR_state_store=$1" >> ~/.bashrc
echo "export NAME=kops.k8s.local" >> ~/.bashrc
echo 'export KOPS_STATE_STORE=s3://$TF_VAR_state_store' >> ~/.bashrc

# confirm input vars 
tail -n4 ~/.bashrc 
