#!/usr/bin/env bash
# 7.5.3 - 대화형 MoA: 배포된 모델 전체에 질의 -> 선택한 aggregator 가 종합 -> 결과 출력
set -uo pipefail

echo "================================================"
echo " MoA(Mixture of Agents) 대화형 콘솔"
echo "------------------------------------------------"
echo " 배포된 여러 sLLM에 같은 질문을 던진 뒤,"
echo " 선택한 aggregator 가 그 답변들을 하나로 종합합니다."
echo " 개별 응답 -> 종합(MoA) 응답을 단계별로 비교하세요."
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

# 1) 현재 '배포된' 모델만 추림 (서비스 존재 여부로 판단)
DEPLOYED="$(
  while IFS='|' read -r name svc tag; do
    [ -z "$name" ] && continue
    kubectl get svc "$svc" >/dev/null 2>&1 && printf '%s|%s|%s\n' "$name" "$svc" "$tag"
  done <<EOF
$CATALOG
EOF
)"
[ -z "$DEPLOYED" ] && { echo "배포된 ollama 모델 서비스가 없습니다 - 먼저 모델을 배포하세요."; exit 1; }

# 2) aggregator 선택 (배포된 모델 중 fzf 로)
AGG_NAME="$(printf '%s\n' "$DEPLOYED" | cut -d'|' -f1 | fzf --height=40% --reverse --prompt='aggregator 선택> ')"
[ -z "$AGG_NAME" ] && { echo "취소됨."; exit 0; }
AGG_SVC="$(awk -F'|' -v n="$AGG_NAME" '$1==n{print $2; exit}' <<<"$DEPLOYED")"
AGG_MODEL="$(awk -F'|' -v n="$AGG_NAME" '$1==n{print $3; exit}' <<<"$DEPLOYED")"

# 3) 질문 선택 (프리셋) 또는 직접 입력
PROMPTS='What is Kubernetes? Answer in 3 sentences.
What are the differences between Docker and Kubernetes? Answer in 2 sentences.
쿠버네티스의 파드(Pod)란 무엇인지 2문장으로 설명해주세요.
Docker와 Kubernetes의 차이를 3문장으로 설명해주세요.
Other (직접 입력)'
QUESTION="$(printf '%s\n' "$PROMPTS" | fzf --height=40% --reverse --prompt='질문 선택> ')"
[ -z "$QUESTION" ] && { echo "취소됨."; exit 0; }
case "$QUESTION" in
  'Other (직접 입력)') printf '질문 입력> '; IFS= read -r QUESTION ;;
esac
[ -z "$QUESTION" ] && { echo "질문이 비었습니다."; exit 1; }

echo ""
echo "프롬프트: $QUESTION"
echo "aggregator: $AGG_MODEL"

# --- 공용 헬퍼 ---
# JSON 문자열 이스케이프 (역슬래시/따옴표/개행 처리)
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' '; }

# 단일 모델 질의: $1 서비스  $2 모델태그  $3 원문 프롬프트 (ClusterIP -> 일회용 curl 파드)
ask_one() {
  local think="" content payload
  case "$2" in qwen*) think='"think":false,' ;; esac
  content="$(json_escape "$3")"
  payload="{\"model\":\"$2\",${think}\"messages\":[{\"role\":\"user\",\"content\":\"$content\"}],\"stream\":false}"
  kubectl run "moa-$$-$RANDOM" --rm -i --restart=Never --quiet --image=curlimages/curl --command -- \
    curl -s "http://$1:11434/api/chat" -d "$payload" -w '\n' </dev/null \
    | sed 's/.*"content":"//;s/"\},"done.*//' | sed 's/\\n/ /g'
}

# 4) 단계 1 - 배포된 모든 모델에 동일 질문
echo ""
echo "================= 단계 1: 개별 모델 응답 ================="
ANSWERS=""
while IFS='|' read -r name svc tag; do
  [ -z "$name" ] && continue
  echo ""
  echo "모델: $name"
  echo "답변:"
  ans="$(ask_one "$svc" "$tag" "$QUESTION Answer in 3 sentences.")"
  echo "$ans"
  ANSWERS="${ANSWERS}Answer ($name): ${ans} "
done <<EOF
$DEPLOYED
EOF

# 5) 단계 2 - aggregator 가 종합
echo ""
echo "========== 단계 2: MoA 종합 (aggregator: $AGG_MODEL) =========="
AGG_PROMPT="You are an expert aggregator. Several AI models answered the question: ${QUESTION} ${ANSWERS}Synthesize the best parts of all answers into one clear, accurate answer in 3 sentences. Remove any incorrect information."
echo ""
echo "답변:"
ask_one "$AGG_SVC" "$AGG_MODEL" "$AGG_PROMPT"
