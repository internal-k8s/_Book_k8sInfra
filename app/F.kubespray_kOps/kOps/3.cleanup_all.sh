#!/usr/bin/env bash

# delete kops cluster 
kops delete cluster --name $NAME --yes

# delete aws infra by terraform 
terraform destroy -auto-approve 

# remove terraform files 
rm -rf .terraform
rm .terraform.lock.hcl
rm terraform.tfstate
rm terraform.tfstate.backup

# remove tools 
rm /usr/local/bin/kops
rm /usr/local/bin/terraform
rm /usr/local/bin/aws
rm /usr/local/bin/aws_completer
rm -rf /usr/local/aws-cli

echo "Successfully cleanup all!"
