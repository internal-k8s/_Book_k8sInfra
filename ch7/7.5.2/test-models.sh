#!/bin/bash
# 7.5.2 — sLLM의 한계 확인하기
# 3개 모델에 동일한 질문을 던져 품질을 비교합니다.

SERVICES=("ollama-gemma3-270m" "ollama-qwen35-0-8b" "ollama-llama32-1b")
MODELS=("gemma3:270m" "qwen3.5:0.8b" "llama3.2:1b")
NAMES=("Gemma3-270M" "Qwen3.5-0.8B" "Llama3.2-1B")

echo "============================================"
echo " 7.5.2 sLLM 품질 비교 테스트"
echo "============================================"
echo ""

# 테스트 1: 영어 — What is Kubernetes?
echo "########################################"
echo "# Test 1: What is Kubernetes?"
echo "########################################"
echo ""
for i in 0 1 2; do
  echo ">> ${NAMES[$i]}:"
  curl -s "http://${SERVICES[$i]}:11434/api/chat" \
    -d "{\"model\":\"${MODELS[$i]}\",\"messages\":[{\"role\":\"user\",\"content\":\"What is Kubernetes? Answer in 3 sentences.\"}],\"stream\":false}" \
    | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['message']['content'])" 2>/dev/null \
    || echo "(응답 파싱 실패)"
  echo ""
done

# 테스트 2: 한국어 — 파드(Pod) 설명
echo "########################################"
echo "# Test 2: 파드(Pod)란? (한국어)"
echo "########################################"
echo ""
for i in 0 1 2; do
  echo ">> ${NAMES[$i]}:"
  curl -s "http://${SERVICES[$i]}:11434/api/chat" \
    -d "{\"model\":\"${MODELS[$i]}\",\"messages\":[{\"role\":\"user\",\"content\":\"쿠버네티스의 파드(Pod)란 무엇인지 2문장으로 설명해주세요.\"}],\"stream\":false}" \
    | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['message']['content'])" 2>/dev/null \
    || echo "(응답 파싱 실패)"
  echo ""
done

# 테스트 3: Docker vs Kubernetes
echo "########################################"
echo "# Test 3: Docker vs Kubernetes 차이"
echo "########################################"
echo ""
for i in 0 1 2; do
  echo ">> ${NAMES[$i]}:"
  curl -s "http://${SERVICES[$i]}:11434/api/chat" \
    -d "{\"model\":\"${MODELS[$i]}\",\"messages\":[{\"role\":\"user\",\"content\":\"Docker와 Kubernetes의 차이점을 3문장으로 설명해주세요.\"}],\"stream\":false}" \
    | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['message']['content'])" 2>/dev/null \
    || echo "(응답 파싱 실패)"
  echo ""
done

echo "============================================"
echo " 테스트 완료"
echo "============================================"
echo ""
echo "각 모델의 강점과 약점을 비교해보세요:"
echo "  - 할루시네이션(잘못된 사실)이 있는가?"
echo "  - 한국어 답변이 자연스러운가?"
echo "  - 지시(문장 수)를 잘 따르는가?"
echo ""
echo ">> 결론: 작은 모델 하나만으로는 신뢰할 수 없습니다."
echo ">> 7.5.3에서 여러 모델의 협업(MoA)으로 이를 극복합니다."
