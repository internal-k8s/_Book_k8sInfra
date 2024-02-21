#!/usr/bin/env bash

if [ $# -eq 0 ]; then
  echo "usage: copy_docker_2_docker.sh <node-name>"; exit 0
fi

DOCKER_NAMESPACE="moby"
KUBERNETES_NAMESPACE="k8s.io"
TEMP_DOCKER_FILE_PATH=/tmp/docker-multistage-img.tar

echo "[1/4] 필요한 패키지를 설치하고, cp-k8s에서 빌드한 도커 이미지(multistage-img)를 tar 파일로 내보냅니다."
apt-get install sshpass -y
sshpass -p vagrant scp -o StrictHostKeyChecking=no -q  ~/_Book_k8sInfra/ch4/4.2.1/install_docker.sh root@$1:/tmp
sshpass -p vagrant ssh root@$1 bash /tmp/install_docker.sh
docker save multistage-img -o $TEMP_DOCKER_FILE_PATH

echo "[2/4] 내보낸 docker-multistage-img.tar 파일을 $1 노드에 전달합니다."
sshpass -p vagrant scp -o StrictHostKeyChecking=no -q $TEMP_DOCKER_FILE_PATH root@$1:$TEMP_DOCKER_FILE_PATH

echo "[3/4] $1 노드에 전달된 docker-multistage-img.tar를 도커 네임스페이스($DOCKER_NAMESPACE)에 해당 이미지를 넣습니다."
sshpass -p vagrant ssh root@$1 docker load -i $TEMP_DOCKER_FILE_PATH

echo -e "[4/4] 작업이 완료되었습니다.\n다시 'kubectl get pods' 명령을 통해 파드 상태를 확인해 주세요."
