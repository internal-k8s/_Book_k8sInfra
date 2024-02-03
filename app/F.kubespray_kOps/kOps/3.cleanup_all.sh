#!/usr/bin/env bash

# delete kops cluster 
kops delete cluster --name $NAME --yes

# delete aws infra by terraform 
terraform -chdir=./tf-files destroy -auto-approve 

# remove terraform files 
rm -rf ./tf-files/.terraform
rm ./tf-files/.terraform.lock.hcl
rm ./tf-files/terraform.tfstate
rm ./tf-files/terraform.tfstate.backup

echo "Successfully cleanup all!"
