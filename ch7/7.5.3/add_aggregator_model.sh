#!/usr/bin/env bash
# 7.5.3 - 정제(aggregator) 전용 워커 w4-k8s(4코어/16GB) 추가 + 정제 모델 배포
#   호스트 터미널에서 실행한다(가상 머신 생성을 포함하므로 cp-k8s가 아님).
#   호스트에 kubectl/kubeconfig 는 필요 없다 — 모든 kubectl 은 cp-k8s 로 ssh 프록시해 실행한다.
#   [동작 1] w4-k8s 노드 기동·조인  [동작 2] 정제 모델(구운 이미지) 배포 — 두 동작 모두 멱등이라 재실행해도 안전하다.
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

# 호스트 가용 메모리 점검 (macOS. 부족할 때만 경고)
FREE_MB="$(vm_stat 2>/dev/null | awk '/Pages (free|inactive|speculative)/{gsub("\\.","",$NF); s+=$NF} END{print int(s*16384/1048576)}')"
if [ -n "$FREE_MB" ] && [ "$FREE_MB" -lt 18000 ]; then
  echo "경고: 호스트 가용 메모리가 약 ${FREE_MB}MB로 w4-k8s(16GB) 기동에 빠듯합니다. 무거운 앱을 종료하고 진행을 권장합니다."
fi

# cp-k8s 연결 확인 (클러스터가 떠 있어야 w4 조인이 가능하다)
cp_kubectl get nodes >/dev/null 2>&1 || { echo "cp-k8s 에 연결할 수 없습니다. 7.1.1 클러스터 기동 상태를 확인하세요."; exit 1; }

# [동작 1] w4-k8s 노드 기동·조인
echo "Vagrant up w4-k8s worker node."
if cp_kubectl get node w4-k8s >/dev/null 2>&1; then
  echo "w4-k8s already joined."
  (cd "$VAG_W4_DIR" && vagrant up "$W4_MACHINE" >/dev/null 2>&1)   # 꺼져 있으면 기동만
else
  (cd "$VAG_W4_DIR" && vagrant up "$W4_MACHINE") || { echo "vagrant up 실패."; exit 1; }
fi
# 조인 직후 노드 오브젝트 등록까지 시차가 있어 먼저 등록을 기다린다
for i in $(seq 1 30); do
  cp_kubectl get node w4-k8s >/dev/null 2>&1 && break
  sleep 10
done
cp_kubectl wait --for=condition=Ready node/w4-k8s --timeout=900s || { echo "w4-k8s가 Ready 상태가 되지 않았습니다."; exit 1; }

# [동작 2] 정제 모델 배포 (구운 이미지 sysnet4admin/ollama-gemma4:12b-it-qat)
#   YAML 은 cp-k8s 에 클론된 리포지터리 경로를 사용한다 (호스트 models/ 와 파일명 기준 동일)
echo "Deploy aggregator model on w4-k8s."
for yaml_file in "$MODEL_DIR"/*-ollama.yaml; do
  cp_kubectl apply -f "$CP_MODEL_DIR/$(basename "$yaml_file")"
done

echo "Wait for aggregator model to be ready..."
for yaml_file in "$MODEL_DIR"/*-ollama.yaml; do
  deploy_name=$(awk '/^kind: Deployment/{found=1} found && /^  name:/{print $2; exit}' "$yaml_file")
  [ -n "$deploy_name" ] && cp_kubectl rollout status deployment/"$deploy_name" --timeout=1200s
done
