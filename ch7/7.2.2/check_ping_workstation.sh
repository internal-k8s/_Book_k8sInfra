#!/usr/bin/env bash

PODS=(workstation-internet workstation-intranet workstation-privacy)

declare -A POD_IP
for pod in "${PODS[@]}"; do
  POD_IP[$pod]=$(kubectl get pod "$pod" -o jsonpath='{.status.podIP}')
done

echo "Network Probe: ICMP (ping) reachability between workstation pods"
echo "================================================================="
printf "  %-28s %s\n" "Pod" "IP"
echo "-----------------------------------------------------------------"
for pod in "${PODS[@]}"; do
  printf "  %-28s %s\n" "$pod" "${POD_IP[$pod]}"
done
echo "================================================================="
echo ""

for src in "${PODS[@]}"; do
  for dst in "${PODS[@]}"; do
    [ "$src" = "$dst" ] && continue
    if kubectl exec "$src" -- ping -c 1 -W 2 "${POD_IP[$dst]}" &>/dev/null; then
      status="OK  "
    else
      status="FAIL"
    fi
    printf "  %-28s -> %-28s [%s]\n" "$src" "$dst" "$status"
  done
  echo ""
done
