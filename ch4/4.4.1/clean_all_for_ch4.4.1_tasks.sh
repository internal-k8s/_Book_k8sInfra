#!/usr/bin/env bash

IMG_NAME="multistage-img"

echo "[1/5] $IMG_NAME 디플로이먼트를 삭제합니다."
kubectl delete deployment $IMG_NAME 

echo "[2/5] w1-k8s의 도커와 컨테이너디가 관리하는 $IMG_NAME 이미지를 삭제합니다."
sshpass -p vagrant ssh root@w1-k8s docker rmi $IMG_NAME
sshpass -p vagrant ssh root@w1-k8s crictl rmi $IMG_NAME

echo "[3/5] w2-k8s의 도커와 컨테이너디가 관리하는 $IMG_NAME 이미지를 삭제합니다."
sshpass -p vagrant ssh root@w2-k8s docker rmi $IMG_NAME
sshpass -p vagrant ssh root@w2-k8s crictl rmi $IMG_NAME

echo "[4/5] w3-k8s의 도커와 컨테이너디가 관리하는 $IMG_NAME 이미지를 삭제합니다."
sshpass -p vagrant ssh root@w3-k8s docker rmi $IMG_NAME
sshpass -p vagrant ssh root@w3-k8s crictl rmi $IMG_NAME

echo -e "[4/5] 작업이 완료되었습니다."
