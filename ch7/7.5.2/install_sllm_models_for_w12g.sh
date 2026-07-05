#!/usr/bin/env bash
shopt -s nullglob

# Deploy the opt-w12g sLLM models (12GB workers) from models/opt-w12g/.
MODEL_DIR="$HOME/_Book_k8sInfra/ch7/7.5.2/models/opt-w12g"

echo "Deploy sLLM models (opt-w12g)."
for yaml_file in "$MODEL_DIR"/*-ollama.yaml; do
  kubectl apply -f "$yaml_file"
done

echo "Wait for sLLM models to be ready..."
for yaml_file in "$MODEL_DIR"/*-ollama.yaml; do
  deploy_name=$(awk '/^kind: Deployment/{found=1} found && /^  name:/{print $2; exit}' "$yaml_file")
  [ -n "$deploy_name" ] && kubectl rollout status deployment/"$deploy_name" --timeout=600s
done
