#!/usr/bin/env bash

# terraform
curl -LO https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
mv terraform /usr/local/bin/terraform
rm terraform_1.6.6_linux_amd64.zip

# kops
curl -LO https://github.com/kubernetes/kops/releases/download/v1.28.2/kops-linux-amd64
chmod 744 kops-linux-amd64
mv kops-linux-amd64 /usr/local/bin/kops

# awscli
curl -L https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.15.5.zip -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip
rm -rf ./aws

# verification the tools 
INSTALLED_TERRAFORM_VERSION=$(terraform version | head -n 1 | awk -F 'v' '{print $2}')
INSTALLED_KOPS_VERSION=$(kops version | awk -F ' ' '{print $3}')
INSTALLED_AWS_CLI_VERSION=$(aws --version | awk -F ' ' '{print $1}' | awk -F '/' '{print $2}')

echo "installed tools"
echo "terraform: $INSTALLED_TERRAFORM_VERSION"
echo "kops: $INSTALLED_KOPS_VERSION"
echo "AWS CLI: $INSTALLED_AWS_CLI_VERSION"



# default config for aws 
mkdir ~/.aws && \
cat <<EOF > ~/.aws/config 
[default]
region = us-east-1
output = json
EOF
