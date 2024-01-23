#!/usr/bin/env bash

# check input $1 
if [ $# -eq 0 ]; then
  echo "usage: verify_s3_name.sh <s3_name>"; exit 0
fi

# make & remove s3 
aws s3 mb s3://$1
aws s3 rb s3://$1

