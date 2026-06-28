#!/usr/bin/env bash
# 7.5.2 - 대화형 단일 sLLM 질의: 모델 선택(fzf) → 프롬프트 선택/입력(fzf) → 결과 출력
set -uo pipefail

echo "================================================"
echo " sLLM 질의 대화형 콘솔"
echo "------------------------------------------------"
echo " 배포된 sLLM 하나를 골라 질문을 던지고,"
echo " 그 모델의 응답을 그대로 확인합니다."
echo " (여러 모델을 함께 종합하려면 MoA 콘솔을 사용하세요)"
echo "================================================"

# fzf 가 없으면 조용히 설치 (클러스터 노드 = 고정 Ubuntu/apt).
if ! command -v fzf >/dev/null 2>&1; then
  sudo apt-get update -qq >/dev/null 2>&1
  sudo apt-get install -y -qq fzf >/dev/null 2>&1
  command -v fzf >/dev/null 2>&1 || { echo "fzf 설치 실패 - 수동 설치 후 다시 실행하세요."; exit 1; }
fi

# 모델 카탈로그: "표시명|서비스|모델태그" - 워커 노드 순(w1 -> w2 -> w3)으로 정렬.
# 같은 노드를 기본/opt 모델이 공유하며, 배포된 쪽만 자동 필터됨.
CATALOG='qwen3.5-0.8b|ollama-qwen35-0-8b|qwen3.5:0.8b
qwen3.5-4b|ollama-qwen35-4b|qwen3.5:4b
gemma3-270m|ollama-gemma3-270m|gemma3:270m
gemma3-4b|ollama-gemma3-4b|gemma3:4b
llama3.2-1b|ollama-llama32-1b|llama3.2:1b
qwen3.5-2b|ollama-qwen35-2b|qwen3.5:2b'

# 현재 '배포된' 모델만 추림 (서비스 존재 여부로 판단)
DEPLOYED="$(
  while IFS='|' read -r name svc tag; do
    [ -z "$name" ] && continue
    kubectl get svc "$svc" >/dev/null 2>&1 && printf '%s|%s|%s\n' "$name" "$svc" "$tag"
  done <<EOF
$CATALOG
EOF
)"
[ -z "$DEPLOYED" ] && { echo "배포된 ollama 모델 서비스가 없습니다 - 먼저 모델 배포: ./install_sllm_models.sh"; exit 1; }

# 프롬프트 템플릿 (마지막은 직접 입력)
PROMPTS='What is Kubernetes? Answer in 3 sentences.
What are the differences between Docker and Kubernetes? Answer in 2 sentences.
쿠버네티스의 파드(Pod)란 무엇인지 2문장으로 설명해주세요.
Docker와 Kubernetes의 차이를 3문장으로 설명해주세요.
Other (직접 입력)'

# 1) 모델 선택 - 배포된 모델만 fzf 에 표시명(1열)으로, 선택값으로 서비스/태그 역참조
NAME="$(printf '%s\n' "$DEPLOYED" | cut -d'|' -f1 | fzf --height=40% --reverse --prompt='모델 선택> ')"
[ -z "$NAME" ] && { echo "취소됨."; exit 0; }
SVC="$(awk -F'|' -v n="$NAME" '$1==n{print $2; exit}' <<<"$DEPLOYED")"
MODEL="$(awk -F'|' -v n="$NAME" '$1==n{print $3; exit}' <<<"$DEPLOYED")"

# 2) 프롬프트 선택 또는 직접 입력
PROMPT="$(printf '%s\n' "$PROMPTS" | fzf --height=40% --reverse --prompt='프롬프트 선택> ')"
[ -z "$PROMPT" ] && { echo "취소됨."; exit 0; }
case "$PROMPT" in
  'Other (직접 입력)') printf '프롬프트 입력> '; IFS= read -r PROMPT ;;
esac
[ -z "$PROMPT" ] && { echo "프롬프트가 비었습니다."; exit 1; }

# 3) JSON 페이로드 (qwen 은 think=false 로 동등 비교; 프롬프트는 JSON 이스케이프)
THINK=""; case "$MODEL" in qwen*) THINK='"think":false,' ;; esac
CONTENT="$(printf '%s' "$PROMPT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')"
PAYLOAD="{\"model\":\"$MODEL\",${THINK}\"messages\":[{\"role\":\"user\",\"content\":\"$CONTENT\"}],\"stream\":false}"

echo ""
echo "모델: $MODEL"
echo "프롬프트: $PROMPT"
echo ""

# 4) ClusterIP 서비스에 질의 - 일회용 curl 파드로 호출 후 자동 정리
echo "답변:"
kubectl run "sllm-query-$$" --rm -i --restart=Never --quiet --image=curlimages/curl --command -- \
  curl -s "http://$SVC:11434/api/chat" -d "$PAYLOAD" -w '\n' \
  | sed 's/.*"content":"//;s/"\},"done.*//' | sed 's/\\n/\n/g'
