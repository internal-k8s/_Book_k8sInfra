#!/usr/bin/env bash

NODE_COUNT=3

echo "[Step 1/2] Install docker service on all nodes"
for (( i=1; i<=$NODE_COUNT; i++ ));
  do
  TARGET="192.168.1.10$i"
  echo "  - installing docker on $TARGET"
  sshpass -p vagrant scp -o StrictHostKeyChecking=no -q ~/_Book_k8sInfra/ch4/4.2.1/install_docker.sh root@$TARGET:/tmp
  sshpass -p vagrant ssh root@$TARGET bash /tmp/install_docker.sh > /dev/null 2>&1
  sshpass -p vagrant ssh root@$TARGET chmod 666 /var/run/docker.sock 2>&1
  done

echo "[Step 2/2] Successfully completed"
