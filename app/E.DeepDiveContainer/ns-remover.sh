#!/usr/bin/env bash
ip netns delete ns-nginx
ip link delete br-nginx
ip link delete h-int
apt-get remove bridge-utils -y
