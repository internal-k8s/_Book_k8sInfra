#!/usr/bin/env bash

if [ $# -eq 0 ]; then
  echo "usage: copy_docker_2_containerd.sh <node-name>"; exit 0
fi

DOCKER_NAMESPACE="moby"
KUBERNETES_NAMESPACE="k8s.io"
TEMP_DOCKER_FILE_PATH=/tmp/docker-multistage-img.tar

echo "[1/4] docker에서 빌드한 이미지를 tar 파일로 내보냅니다."
apt-get install sshpass -y
docker save multistage-img -o $TEMP_DOCKER_FILE_PATH

echo "[2/4] 내보낸 docker-multistage-img.tar 파일을 $1 노드에 전달합니다."
sshpass -p vagrant scp -o StrictHostKeyChecking=no -q $TEMP_DOCKER_FILE_PATH root@$1:$TEMP_DOCKER_FILE_PATH

echo "[3/4] $1 노드에 전달된 docker-multistage-img.tar를 쿠버네티스 네임스페이스($KUBERNETES_NAMESPACE)에 해당 이미지를 넣습니다."
sshpass -p vagrant ssh root@$1 ctr --namespace $KUBERNETES_NAMESPACE image import --base-name multistage-img $TEMP_DOCKER_FILE_PATH

echo -e "[4/4] 작업이 완료되었습니다.\n다시 'kubectl get pods' 명령을 통해 파드 상태를 확인해 주세요."
