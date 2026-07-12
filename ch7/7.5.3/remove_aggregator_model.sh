#!/usr/bin/env bash
# 7.5.3 - 정제(aggregator) 전용 워커 w4-k8s 제거 (add_aggregator_model.sh 의 역순)
#   호스트 터미널에서 실행한다(가상 머신 파괴를 포함하므로 cp-k8s가 아님).
#   [동작 1] 정제 모델 삭제  [동작 2] w4-k8s VM 파괴  [동작 3] 노드 오브젝트 삭제 — 모두 멱등이라 재실행해도 안전하다.
#   순서 주의: 노드 오브젝트를 먼저 지우면 살아 있는 kubelet이 곧바로 재등록하므로 VM 파괴가 먼저다.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAG_W4_DIR="$SCRIPT_DIR"                    # w4-k8s Vagrantfile 은 이 디렉터리(7.5.3)에 있다
VAG_CP_DIR="$SCRIPT_DIR/../7.1.1"
CP_MACHINE="cp-k8s-1.36.1"
W4_MACHINE="w4-k8s-1.36.1"
MODEL_DIR="$SCRIPT_DIR/models"
CP_MODEL_DIR="/root/_Book_k8sInfra/ch7/7.5.3/models"   # cp-k8s 에 클론된 실습 리포지터리의 모델 경로

# kubectl 프록시: cp-k8s 에 ssh 로 명령을 쏴서 root(kubeconfig 보유자)로 실행한다
cp_kubectl() { (cd "$VAG_CP_DIR" && vagrant ssh "$CP_MACHINE" -c "sudo -i kubectl $*" </dev/null); }

# cp-k8s 연결 확인 — 클러스터가 이미 내려가 있어도 VM 파괴는 진행한다
CP_UP=1
cp_kubectl get nodes >/dev/null 2>&1 || { CP_UP=0; echo "cp-k8s 에 연결할 수 없어 클러스터 쪽 정리는 건너뛰고 VM 제거만 진행합니다."; }

# [동작 1] 정제 모델 삭제 (cp-k8s 의 cleanup_7.5_tasks.sh 를 이미 실행했다면 지워져 있음 — 멱등)
if [ "$CP_UP" -eq 1 ]; then
  echo "Delete aggregator model."
  for yaml_file in "$MODEL_DIR"/*-ollama.yaml; do
    cp_kubectl delete -f "$CP_MODEL_DIR/$(basename "$yaml_file")" --ignore-not-found
  done
fi

# [동작 2] w4-k8s VM 파괴
echo "Vagrant destroy w4-k8s worker node."
(cd "$VAG_W4_DIR" && vagrant destroy -f "$W4_MACHINE") || { echo "vagrant destroy 실패."; exit 1; }

# [동작 3] 노드 오브젝트 삭제 (VM 이 사라진 뒤라 재등록 없음)
if [ "$CP_UP" -eq 1 ]; then
  echo "Delete w4-k8s node object."
  cp_kubectl delete node w4-k8s --ignore-not-found
fi
