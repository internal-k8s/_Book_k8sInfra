#!/usr/bin/env bash

# delete kops cluster 
kops delete cluster --name $NAME --yes

# delete aws infra by terraform 
terraform -chdir=./terraform destroy -auto-approve 

# remove terraform files 
rm -rf ./terraform/.terraform
rm ./terraform/.terraform.lock.hcl
rm ./terraform/terraform.tfstate
rm ./terraform/terraform.tfstate.backup

echo "Successfully cleanup all!"
