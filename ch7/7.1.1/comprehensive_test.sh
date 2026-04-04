#!/usr/bin/env bash
# Comprehensive cluster validation (containerd 2.2.2)
# Works for both ch3 (MetalLB) and ch7 (Cilium L2)
# Run on cp-k8s as root after cluster + LB is ready

PASS=0; FAIL=0

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

wait_pod_running() {
  local label=$1 ns=${2:-default} timeout=${3:-120}
  for i in $(seq 1 $timeout); do
    not_ready=$(kubectl get pods -l "$label" -n $ns --no-headers 2>/dev/null \
      | grep -cv "Running\|Completed") || true
    total=$(kubectl get pods -l "$label" -n $ns --no-headers 2>/dev/null | wc -l)
    [ "$total" -gt 0 ] && [ "$not_ready" -eq 0 ] && return 0
    sleep 1
  done
  return 1
}

wait_lb_ip() {
  local svc=$1 ns=${2:-default} timeout=${3:-120}
  for i in $(seq 1 $timeout); do
    ip=$(kubectl get svc $svc -n $ns -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    [ -n "$ip" ] && echo "$ip" && return 0
    sleep 1
  done
  return 1
}

echo "===== 1. Node Status ====="
kubectl get nodes -o wide
node_ready=$(kubectl get nodes --no-headers | grep -c " Ready ")
[ "$node_ready" -eq 4 ] && pass "All 4 nodes Ready" || fail "Nodes Ready: $node_ready/4"

echo ""
echo "===== 2. System Pods ====="
kubectl get pods -n kube-system -o wide
sys_bad=$(kubectl get pods -n kube-system --no-headers 2>/dev/null \
  | grep -cv "Running\|Completed") || true
[ "$sys_bad" -eq 0 ] && pass "All kube-system pods Running/Completed" \
  || fail "$sys_bad kube-system pods not healthy"

echo ""
echo "===== 3. ClusterIP Service ====="
kubectl create deployment clusterip-test --image=nginx --replicas=2
kubectl expose deployment clusterip-test --port=80 --type=ClusterIP
wait_pod_running "app=clusterip-test" default 60
svc_ip=$(kubectl get svc clusterip-test -o jsonpath='{.spec.clusterIP}')
kubectl run curl-clusterip --image=curlimages/curl --restart=Never --rm -it \
  -- curl -s --connect-timeout 5 http://$svc_ip | grep -q "Welcome to nginx" \
  && pass "ClusterIP reachable ($svc_ip)" || fail "ClusterIP NOT reachable ($svc_ip)"
kubectl delete deployment clusterip-test && kubectl delete svc clusterip-test

echo ""
echo "===== 4. NodePort Service ====="
kubectl create deployment nodeport-test --image=nginx --replicas=1
kubectl expose deployment nodeport-test --port=80 --type=NodePort
wait_pod_running "app=nodeport-test" default 60
node_port=$(kubectl get svc nodeport-test -o jsonpath='{.spec.ports[0].nodePort}')
curl -s --connect-timeout 5 http://192.168.1.101:$node_port | grep -q "Welcome to nginx" \
  && pass "NodePort reachable (w1:$node_port)" || fail "NodePort NOT reachable ($node_port)"
kubectl delete deployment nodeport-test && kubectl delete svc nodeport-test

echo ""
echo "===== 5. LoadBalancer Service ====="
kubectl apply -f ~/_Book_k8sInfra/ch3/3.3.2/ip-LoadBalancer.yaml
wait_pod_running "app=lb-ip" default 60
echo "Waiting for LoadBalancer IP (max 90s)..."
lb_ip=$(wait_lb_ip lb-ip-svc default 90)
if [ -n "$lb_ip" ]; then
  curl -s --connect-timeout 5 http://$lb_ip | grep -q "." \
    && pass "LoadBalancer reachable ($lb_ip)" || fail "LoadBalancer IP assigned ($lb_ip) but NOT reachable"
else
  fail "LoadBalancer IP NOT assigned (timeout)"
fi
kubectl delete -f ~/_Book_k8sInfra/ch3/3.3.2/ip-LoadBalancer.yaml

echo ""
echo "===== 6. DaemonSet ====="
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ds-test
spec:
  selector:
    matchLabels: {app: ds-test}
  template:
    metadata:
      labels: {app: ds-test}
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      containers:
      - name: nginx
        image: nginx
EOF
sleep 15
ds_desired=$(kubectl get ds ds-test -o jsonpath='{.status.desiredNumberScheduled}')
ds_ready=$(kubectl get ds ds-test -o jsonpath='{.status.numberReady}')
[ "$ds_desired" -eq "$ds_ready" ] && pass "DaemonSet $ds_ready/$ds_desired (all nodes incl. cp)" \
  || fail "DaemonSet $ds_ready/$ds_desired not all ready"
kubectl delete ds ds-test

echo ""
echo "===== 7. Job ====="
cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: job-test
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34
        command: ["perl","-Mbignum=bpi","-wle","print bpi(50)"]
      restartPolicy: Never
  backoffLimit: 2
EOF
echo "Waiting for Job completion (max 120s)..."
kubectl wait --for=condition=complete job/job-test --timeout=120s \
  && pass "Job completed" || fail "Job did NOT complete"
kubectl logs job/job-test
kubectl delete job job-test

echo ""
echo "===== 8. DNS Resolution ====="
dns_out=$(kubectl run dns-test --image=busybox:1.36 --restart=Never --rm -it \
  -- sh -c "nslookup kubernetes.default.svc.cluster.local && nslookup google.com" 2>&1) || true
echo "$dns_out"
echo "$dns_out" | grep -q "^Address:" \
  && pass "DNS: kubernetes.default.svc.cluster.local resolved" || fail "DNS: kubernetes.default FAILED"
echo "$dns_out" | grep -q "Non-authoritative answer" \
  && pass "DNS: external (google.com) resolved" || fail "DNS: external resolution FAILED"

echo ""
echo "===== 9. Cross-node pod distribution & connectivity ====="
kubectl create deployment cross-node --image=nginx --replicas=3
wait_pod_running "app=cross-node" default 60
pods=$(kubectl get pods -l app=cross-node -o wide --no-headers)
echo "$pods"
running=$(echo "$pods" | grep -c "Running")
unique_nodes=$(echo "$pods" | awk '{print $7}' | sort -u | wc -l)
[ "$running" -eq 3 ] && pass "3 replicas Running" || fail "Running: $running/3"
[ "$unique_nodes" -ge 2 ] && pass "Pods on $unique_nodes different nodes" \
  || fail "Pods NOT distributed ($unique_nodes node only)"
pod1=$(kubectl get pods -l app=cross-node -o jsonpath='{.items[0].metadata.name}')
pod2_ip=$(kubectl get pods -l app=cross-node -o jsonpath='{.items[1].status.podIP}')
kubectl exec $pod1 -- curl -s --connect-timeout 5 http://$pod2_ip | grep -q "Welcome to nginx" \
  && pass "Cross-node pod-to-pod connectivity OK ($pod2_ip)" \
  || fail "Cross-node pod-to-pod connectivity FAILED"
kubectl delete deployment cross-node

echo ""
echo "===== 10. PersistentVolume (hostPath) ====="
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hostpath-test
spec:
  capacity:
    storage: 100Mi
  accessModes: [ReadWriteOnce]
  hostPath:
    path: /tmp/pv-test
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-test
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 100Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod-test
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: /data
      name: vol
  volumes:
  - name: vol
    persistentVolumeClaim:
      claimName: pvc-test
EOF
sleep 15
pvc_status=$(kubectl get pvc pvc-test -o jsonpath='{.status.phase}')
pod_status=$(kubectl get pod pvc-pod-test -o jsonpath='{.status.phase}')
[ "$pvc_status" = "Bound" ] && pass "PVC Bound" || fail "PVC NOT Bound: $pvc_status"
[ "$pod_status" = "Running" ] && pass "Pod with PVC Running" || fail "Pod with PVC: $pod_status"
kubectl delete pod pvc-pod-test; kubectl delete pvc pvc-test; kubectl delete pv pv-hostpath-test

echo ""
echo "=========================================="
printf "  RESULT:  PASS=%-3s  FAIL=%-3s\n" "$PASS" "$FAIL"
echo "=========================================="
[ "$FAIL" -eq 0 ] && echo "  ALL TESTS PASSED ✓" || echo "  SOME TESTS FAILED ✗"
echo ""
echo "containerd version:"
kubectl get nodes -o wide | grep -o 'containerd://[^ ]*'
