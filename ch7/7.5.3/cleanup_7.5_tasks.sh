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

echo "✅ 7.5 cleanup done."
