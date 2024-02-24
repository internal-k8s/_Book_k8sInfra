#!/usr/bin/env bash
curl -LO https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz
tar -xvf harbor-online-installer-v2.10.0.tgz
mv harbor/* .
rm -f harbor-online-installer-v2.10.0.tgz
rm -rf harbor
