#!/usr/bin/env bash
ip netns delete ns-nginx
ip link delete nginx
ip link delete vhost
apt-get remove bridge-utils -y
