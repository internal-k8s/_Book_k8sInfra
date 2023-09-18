#!/usr/bin/env bash

cat <<EOF > /etc/vbox/networks.conf
* 10.0.0.0/8 192.168.0.0/16
* 2001::/64
EOF
