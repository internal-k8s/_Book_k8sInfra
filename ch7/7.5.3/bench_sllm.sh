#!/usr/bin/env bash
# 7.5.3 - sLLM 정량 벤치마크(비대화형)
#   배포된 모델 × 고정 질문 × N회 반복 -> 단일/MoA(정제 모델별) 응답을 자동 채점 -> CSV + 요약표
#   대화형 ask_sllm.sh / ask_sllms.sh 와 discovery·질의 방식이 동일하다. fzf 는 필요 없다.
#
# 사용법:  bash 7.5.3/bench_sllm.sh <티어라벨> [반복횟수]
#   예)    bash 7.5.3/bench_sllm.sh base       3   # 기본 워커(3.5G)에 3개 모델을 올린 상태에서
#   예)    bash 7.5.3/bench_sllm.sh opt-w12g   3   # opt-w12g 3개 모델을 올린 상태에서
#   두 티어의 CSV 를 각각 뽑은 뒤 합치면 본문의 12행 비교표가 채워진다.
set -uo pipefail

TIER="${1:-base}"                          # 결과 라벨 (base | opt-w12g). 채점에는 영향 없고 CSV 태그로만 쓰인다.
RUNS="${2:-3}"                             # 질문·구성당 반복 횟수 (확률론적 모델이므로 >=3 권장)
CSV="bench_results_${TIER}.csv"            # 채점 원장 (append)
RAW="bench_answers_${TIER}.txt"            # 원문 답변 로그 (사실정확도 수동/심판 채점용)

# 고정 질문 세트: lang|기대문장수|프롬프트  (ask_*.sh 의 프리셋과 동일)
QSET='en|3|What is Kubernetes? Answer in 3 sentences.
en|2|What are the differences between Docker and Kubernetes? Answer in 2 sentences.
ko|2|쿠버네티스의 파드(Pod)란 무엇인지 2문장으로 설명해주세요.
ko|3|Docker와 Kubernetes의 차이를 3문장으로 설명해주세요.'

# --- 배포된 모델 자동 발견 (ask_sllms.sh 와 동일) ---
SVCS="$(kubectl get svc -o name 2>/dev/null | sed 's#.*/##' | grep '^ollama-' | tr '\n' ' ')"
[ -z "$SVCS" ] && { echo "배포된 ollama 모델 서비스가 없습니다. 먼저 install_sllm_models.sh 로 모델을 배포하세요."; exit 1; }
DEPLOYED="$(kubectl run "disc-$$-$RANDOM" --rm -i --restart=Never --quiet --image=curlimages/curl --command -- \
  sh -c 'sleep 2; for s in '"$SVCS"'; do t=$(curl -s --max-time 15 "http://$s:11434/api/tags" | grep -o "\"name\":\"[^\"]*\"" | head -1 | sed "s/.*:\"//;s/\"//"); [ -n "$t" ] && printf "%s|%s|%s\n" "$t" "$s" "$t"; done' </dev/null 2>/dev/null)"
[ -z "$DEPLOYED" ] && { echo "ollama 서비스에서 모델 정보를 읽지 못했습니다. 잠시 후 다시 실행하세요."; exit 1; }

# 발견된 모델을 배열로
declare -a NAMES SVCA TAGS
while IFS='|' read -r name svc tag; do
  [ -z "$name" ] && continue
  NAMES+=("$name"); SVCA+=("$svc"); TAGS+=("$tag")
done <<EOF
$DEPLOYED
EOF

echo "벤치마크 대상 (${TIER}): ${NAMES[*]}"
echo "반복 횟수: ${RUNS}  |  질문 4종(영2·한2)  |  구성 = 단일 ${#NAMES[@]} + MoA(정제) ${#NAMES[@]}"
echo ""

# --- 공용 헬퍼 (ask_sllms.sh 와 동일 규약: 출력 1행=응답시간(초), 2행~=답변) ---
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' '; }
ask_one() {   # $1 서비스  $2 모델태그  $3 질문
  local think="" content payload raw durns
  case "$2" in qwen*|gemma4*) think='"think":false,' ;; esac   # 추론 모델은 think=false 로 추론 노출 방지
  content="$(json_escape "$3")"
  payload="{\"model\":\"$2\",${think}\"messages\":[{\"role\":\"user\",\"content\":\"$content\"}],\"stream\":false}"
  raw="$(kubectl run "bench-$$-$RANDOM" --rm -i --restart=Never --quiet --image=curlimages/curl --command -- \
    curl -s "http://$1:11434/api/chat" -d "$payload" </dev/null 2>/dev/null)"
  durns="$(printf '%s' "$raw" | grep -o '"total_duration":[0-9]*' | head -1 | sed 's/.*://')"
  awk -v n="${durns:-0}" 'BEGIN{printf "%.1f\n", n/1e9}'
  printf '%s' "$raw" | sed 's/.*"content":"//;s/"\},"done.*//' | sed 's/\\n/\n/g'
}

# --- 자동 채점 (한 줄 CSV 를 stdout 으로) ---
#   지시이행: 종결 부호(.!?) 개수 == 기대 문장수 -> 1/0  (휴리스틱)
#   언어순도: 한글 답변에서 라틴 문자 비율 (낮을수록 좋음).  영어 문항은 참고용.
#   추론노출: <think> 잔존 여부 1/0
score_row() {  # $1 config  $2 mode  $3 aggregator  $4 lang  $5 expected  $6 run  $7 dur  $8 answer
  local cfg="$1" mode="$2" agg="$3" lang="$4" exp="$5" run="$6" dur="$7" ans="$8"
  local nsent ascii hangul ratio fmt leak
  nsent=$(printf '%s' "$ans" | grep -o '[.!?。]' | wc -l | tr -d ' ')
  ascii=$(printf '%s' "$ans" | grep -o '[A-Za-z]' | wc -l | tr -d ' ')
  hangul=$(printf '%s' "$ans" | grep -oP '[\x{AC00}-\x{D7A3}]' 2>/dev/null | wc -l | tr -d ' ')
  ratio=$(awk -v a="${ascii:-0}" -v h="${hangul:-0}" 'BEGIN{t=a+h; printf "%.3f", (t>0? a/t:0)}')
  fmt=$([ "$nsent" = "$exp" ] && echo 1 || echo 0)
  leak=$(printf '%s' "$ans" | grep -qi '<think' && echo 1 || echo 0)
  echo "${TIER},${cfg},${mode},${agg},${lang},${exp},${run},${nsent},${fmt},${ascii},${hangul},${ratio},${leak},${dur}"
}

# --- CSV 헤더 (없을 때만) ---
[ -f "$CSV" ] || echo "tier,config,mode,aggregator,lang,expected,run,n_sent,format_ok,ascii,hangul,ascii_ratio,think_leak,dur_s" > "$CSV"

# --- 본 루프: 질문 × 반복 ---
while IFS='|' read -r lang exp prompt; do
  [ -z "$lang" ] && continue
  for run in $(seq 1 "$RUNS"); do
    echo "[${lang}/문장${exp}] run ${run}/${RUNS}: ${prompt}"
    declare -a BASE_ANS
    ANSWERS=""
    # 1) 단일: 배포된 모든 모델에 동일 질문 (이 응답이 곧 MoA 1단계 입력이 된다)
    for i in "${!NAMES[@]}"; do
      out="$(ask_one "${SVCA[$i]}" "${TAGS[$i]}" "$prompt")"
      dur="$(printf '%s\n' "$out" | head -1)"
      ans="$(printf '%s\n' "$out" | tail -n +2)"
      BASE_ANS[$i]="$ans"
      ANSWERS="${ANSWERS}Answer (${NAMES[$i]}): ${ans} "
      score_row "${NAMES[$i]}" "single" "-" "$lang" "$exp" "$run" "$dur" "$ans" >> "$CSV"
      printf '### [single] %s | %s | run%s\n%s\n\n' "${NAMES[$i]}" "$lang" "$run" "$ans" >> "$RAW"
    done
    # 2) MoA: 배포된 각 모델을 '정제 모델'로 세워 1단계 답변을 종합
    for i in "${!NAMES[@]}"; do
      AGG="You are an expert aggregator. Several AI models answered the question: ${prompt} ${ANSWERS}Synthesize the best parts of all answers into one clear, accurate answer, following the length and language requested in the question. Remove any incorrect information."
      out="$(ask_one "${SVCA[$i]}" "${TAGS[$i]}" "$AGG")"
      dur="$(printf '%s\n' "$out" | head -1)"
      ans="$(printf '%s\n' "$out" | tail -n +2)"
      score_row "MoA" "moa" "${NAMES[$i]}" "$lang" "$exp" "$run" "$dur" "$ans" >> "$CSV"
      printf '### [moa/agg=%s] %s | run%s\n%s\n\n' "${NAMES[$i]}" "$lang" "$run" "$ans" >> "$RAW"
    done
    unset BASE_ANS
  done
done <<EOF
$QSET
EOF

# --- 요약표: 구성 × 언어별 집계 (지시이행률·평균 라틴비율·추론노출률·평균응답시간) ---
echo ""
echo "================= 요약 (${TIER}, N=${RUNS}) ================="
echo "config,mode,aggregator,lang | 지시이행률% 평균라틴비율 추론노출% 평균응답s (n)"
awk -F, 'NR>1 {
  k=$2"|"$3"|"$4"|"$5;
  fmt[k]+=$9; rat[k]+=$12; leak[k]+=$13; dur[k]+=$14; cnt[k]++
}
END{
  for (k in cnt) printf "%-38s | %6.0f %11.3f %8.0f %9.1f (%d)\n",
    k, 100*fmt[k]/cnt[k], rat[k]/cnt[k], 100*leak[k]/cnt[k], dur[k]/cnt[k], cnt[k]
}' "$CSV" | sort

echo ""
echo "원장 CSV : $CSV"
echo "원문 로그 : $RAW   (사실정확도는 이 로그를 근거로 채점)"
