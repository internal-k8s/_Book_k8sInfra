#!/usr/bin/env bash
shopt -s nullglob

BASE_DIR="$HOME/_Book_k8sInfra/ch7/7.5.2"

if [ -n "$1" ]; then
  MODEL_DIR="$BASE_DIR/$1"
  if [ ! -d "$MODEL_DIR" ]; then
    echo "Directory not found: $MODEL_DIR"
    exit 1
  fi
  echo "Deploy sLLM models from $1."
else
  MODEL_DIR="$BASE_DIR"
  echo "Deploy sLLM models."
fi

# Deploy only model manifests (skip compare-*.yaml that shares this directory).
for yaml_file in "$MODEL_DIR"/*-ollama.yaml "$MODEL_DIR"/*-vllm.yaml; do
  kubectl apply -f "$yaml_file"
done

echo "Wait for sLLM models to be ready..."
for yaml_file in "$MODEL_DIR"/*-ollama.yaml "$MODEL_DIR"/*-vllm.yaml; do
  deploy_name=$(awk '/^kind: Deployment/{found=1} found && /^  name:/{print $2; exit}' "$yaml_file")
  [ -n "$deploy_name" ] && kubectl rollout status deployment/"$deploy_name" --timeout=600s
done
