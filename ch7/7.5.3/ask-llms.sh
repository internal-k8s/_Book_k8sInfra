#!/usr/bin/env bash
# 7.5.3 - 대화형 MoA: 배포된 모델 전체에 질의 -> 선택한 aggregator 가 종합 -> 결과 출력
set -uo pipefail

# fzf 가 없으면 조용히 설치 (클러스터 노드 = 고정 Ubuntu/apt).
if ! command -v fzf >/dev/null 2>&1; then
  sudo apt-get update -qq >/dev/null 2>&1
  sudo apt-get install -y -qq fzf >/dev/null 2>&1
  command -v fzf >/dev/null 2>&1 || { echo "fzf 설치 실패 - 수동 설치 후 다시 실행하세요."; exit 1; }
fi

# 모델 카탈로그: "표시명|서비스|모델태그" (12GB 워커용 상위 모델도 포함, 배포 여부로 자동 필터)
CATALOG='gemma3-270m|ollama-gemma3-270m|gemma3:270m
qwen3.5-0.8b|ollama-qwen35-0-8b|qwen3.5:0.8b
llama3.2-1b|ollama-llama32-1b|llama3.2:1b
gemma3-4b|ollama-gemma3-4b|gemma3:4b'

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

echo "배포된 모델:"
printf '%s\n' "$DEPLOYED" | cut -d'|' -f1 | sed 's/^/  - /'

# 2) aggregator 선택 (배포된 모델 중 fzf 로)
AGG_NAME="$(printf '%s\n' "$DEPLOYED" | cut -d'|' -f1 | fzf --height=40% --reverse --prompt='aggregator 선택> ')"
[ -z "$AGG_NAME" ] && { echo "취소됨."; exit 0; }
AGG_SVC="$(awk -F'|' -v n="$AGG_NAME" '$1==n{print $2; exit}' <<<"$DEPLOYED")"
AGG_MODEL="$(awk -F'|' -v n="$AGG_NAME" '$1==n{print $3; exit}' <<<"$DEPLOYED")"

# 3) 질문 선택 (프리셋) 또는 직접 입력
PROMPTS='What is Kubernetes and why is it important?
Docker와 Kubernetes의 차이점을 설명해주세요.
쿠버네티스의 파드(Pod)란 무엇인지 2문장으로 설명해주세요.
Other (직접 입력)'
QUESTION="$(printf '%s\n' "$PROMPTS" | fzf --height=40% --reverse --prompt='질문 선택> ')"
[ -z "$QUESTION" ] && { echo "취소됨."; exit 0; }
case "$QUESTION" in
  'Other (직접 입력)') printf '질문 입력> '; IFS= read -r QUESTION ;;
esac
[ -z "$QUESTION" ] && { echo "질문이 비었습니다."; exit 1; }

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

# 4) Step 1 - 배포된 모든 모델에 동일 질문
echo ""
echo "================= Step 1: 개별 모델 응답 ================="
ANSWERS=""
while IFS='|' read -r name svc tag; do
  [ -z "$name" ] && continue
  echo ""
  echo ">> $name:"
  ans="$(ask_one "$svc" "$tag" "$QUESTION Answer in 3 sentences.")"
  echo "$ans"
  ANSWERS="${ANSWERS}Answer ($name): ${ans} "
done <<EOF
$DEPLOYED
EOF

# 5) Step 2 - aggregator 가 종합
echo ""
echo "========== Step 2: MoA 종합 (aggregator: $AGG_MODEL) =========="
AGG_PROMPT="You are an expert aggregator. Several AI models answered the question: ${QUESTION} ${ANSWERS}Synthesize the best parts of all answers into one clear, accurate answer in 3 sentences. Remove any incorrect information."
echo ""
echo ">> MoA 최종 답변:"
ask_one "$AGG_SVC" "$AGG_MODEL" "$AGG_PROMPT"
