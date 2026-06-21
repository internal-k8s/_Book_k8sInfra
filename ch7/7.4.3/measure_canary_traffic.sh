#!/usr/bin/env bash

DUR="${1:-30}"
BOOK="$HOME/_Book_k8sInfra/ch7/7.4.3"

# Deploy load generators if none are running.
if [ -z "$(kubectl get pods -l app=web-client -o name 2>/dev/null)" ]; then
  echo "Deploy web-client load generators."
  kubectl apply -f "$BOOK/po-web-clients.yaml"
  kubectl wait --for=condition=Ready pod -l app=web-client --timeout=120s
fi

CIL="$(kubectl get pod -n kube-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')"
RELAY="$(kubectl get svc -n kube-system hubble-relay -o jsonpath='{.spec.clusterIP}')"
CANARY_HASH="$(kubectl get rollout ro-canary -o jsonpath='{.status.currentPodHash}')"
STABLE_HASH="$(kubectl get rollout ro-canary -o jsonpath='{.status.stableRS}')"

# Last setWeight at or before step index $1.
step_weight() {
  local cur="$1" i=0 w="" v
  while [ "$i" -le "$cur" ]; do
    v="$(kubectl get rollout ro-canary -o jsonpath="{.spec.strategy.canary.steps[$i].setWeight}" 2>/dev/null)"
    [ -n "$v" ] && w="$v"
    i=$((i+1))
  done
  echo "$w"
}

# Count to-endpoint SYN only (one per connection) via live follow, grouped by ReplicaSet.
measure() {
  kubectl exec -n kube-system "$CIL" -c cilium-agent -- \
    timeout "$DUR" hubble observe -f --server "$RELAY":80 \
      --to-label app=ro-canary --to-port 3000 --tcp-flags SYN -o compact 2>/dev/null \
    | grep 'to-endpoint' \
    | grep -oE 'ro-canary-[a-z0-9]+-[a-z0-9]+' \
    | sed -E 's/ro-canary-([a-z0-9]+)-[a-z0-9]+/\1/' \
    | sort | uniq -c \
    | awk -v c="$CANARY_HASH" -v s="$STABLE_HASH" '
        {cnt[$2]=$1; tot+=$1}
        END{
          cc=cnt[c]+0; ss=cnt[s]+0;
          printf "  canary=%d  stable=%d  total=%d\n", cc, ss, tot;
          if(tot>0) printf "  measured canary traffic ratio = %.1f%%\n", 100.0*cc/tot;
        }'
}

if [ "$CANARY_HASH" = "$STABLE_HASH" ]; then
  echo "No canary in progress. Trigger one with:"
  echo "  k argo rollouts set image ro-canary dashboard=sysnet4admin/dashboard:canary-v2"
  exit 0
fi

echo "canary replicaset=$CANARY_HASH  stable replicaset=$STABLE_HASH"

measured=" "
while true; do
  PHASE="$(kubectl get rollout ro-canary -o jsonpath='{.status.phase}')"
  STEP="$(kubectl get rollout ro-canary -o jsonpath='{.status.currentStepIndex}')"

  case "$PHASE" in
    Healthy|Degraded)
      echo "Rollout $PHASE. Done."
      break
      ;;
    Paused)
      case "$measured" in
        *" $STEP "*) ;;
        *)
          W="$(step_weight "$STEP")"
          PAUSE_DUR="$(kubectl get rollout ro-canary -o jsonpath="{.spec.strategy.canary.steps[$STEP].pause.duration}" 2>/dev/null)"
          echo ""
          echo "setWeight ${W:-?}% (paused) - measuring ${DUR}s..."
          measure
          measured="$measured$STEP "
          # Indefinite pause waits for a manual promote; duration pause advances on its own.
          if [ -z "$PAUSE_DUR" ]; then
            echo "  promote to next step with:"
            echo "    k argo rollouts promote ro-canary"
          fi
          ;;
      esac
      ;;
  esac
  sleep 3
done
