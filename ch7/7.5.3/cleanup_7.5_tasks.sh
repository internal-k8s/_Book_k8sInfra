#!/usr/bin/env bash
shopt -s nullglob

echo "🧹 [7.5] 소형 LLM(sLLM) 실습 리소스 정리"

CH7="$HOME/_Book_k8sInfra/ch7"

# 7.5.2 기본 sLLM 모델(젬마 / 라마 / 큐원) 디플로이먼트 및 서비스 삭제
for yaml_file in "$CH7"/7.5.2/models/base/*-ollama.yaml; do
  kubectl delete -f "$yaml_file" 2>/dev/null
done

# opt-w12g 상위 모델(gemma4:e2b-it-qat / llama3.2:3b / qwen3.5:4b)을 배포했다면 함께 삭제
for yaml_file in "$CH7"/7.5.2/models/opt-w12g/*-ollama.yaml; do
  kubectl delete -f "$yaml_file" 2>/dev/null
done

# 7.5.3 정제(aggregator) 전용 모델(w4-k8s의 ollama-agg-*)을 배포했다면 함께 삭제
for yaml_file in "$CH7"/7.5.3/models/*-ollama.yaml; do
  kubectl delete -f "$yaml_file" 2>/dev/null
done
# w4-k8s 노드(VM) 제거는 게스트에서 호스트로 명령을 보낼 수 없어 호스트에서 별도로 실행한다
if kubectl get node w4-k8s >/dev/null 2>&1; then
  echo "w4-k8s 노드(VM) 제거는 호스트 터미널에서 bash ch7/7.5.3/del_aggregator_model.sh 를 실행하세요."
fi

echo "✅ 7.5 cleanup done."
