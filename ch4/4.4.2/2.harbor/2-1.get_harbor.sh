#!/usr/bin/env bash

echo "Download harbor-online-installer-v.2.10.0..."
curl -LO https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz
tar -xvf harbor-online-installer-v2.10.0.tgz
mv harbor/* .

echo "Remove garbage files..."
rm -f harbor-online-installer-v2.10.0.tgz
rm -rf harbor

echo "Add sequence number for prepare & install"
mv prepare 2-3.prepare 
mv install 2-4.install

