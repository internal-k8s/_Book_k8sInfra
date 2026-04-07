# Calico v3.30.1 → v3.31.2 ✅

패치 적용 방법 및 버전별 상태: [CALICO_PATCH_AND_STATUS.md](https://github.com/sysnet4admin/IaC/blob/main/k8s/CNI/CALICO_PATCH_AND_STATUS.md)

## 변경 파일

| 파일 | 변경 전 | 변경 후 |
|---|---|---|
| `ch3/3.1.3/controlplane_node.sh` | `calico-quay-v3.30.1.yaml` | `calico-quay-v3.31.2.yaml` |

## 테스트 결과 (2026-04-04)

**환경**
- box: `sysnet4admin/Ubuntu-k8s` v1.0.0 (Ubuntu 24.04.4 LTS, arm64)
- Kubernetes: 1.35.0 / Calico: v3.31.2 (패치 적용)

| # | 테스트 항목 | 결과 |
|---|---|---|
| 1 | Node Status (4/4 Ready) | ✅ PASS |
| 2 | kube-system pods 전체 Running | ✅ PASS |
| 3 | ClusterIP service 접근 | ✅ PASS |
| 4 | NodePort service 접근 | ✅ PASS |
| 5 | LoadBalancer service (MetalLB → 192.168.1.11) | ✅ PASS |
| 6 | DaemonSet (4/4, cp 포함 전 노드) | ✅ PASS |
| 7 | Job 완료 | ✅ PASS |
| 8 | DNS 내부 (kubernetes.default.svc.cluster.local) | ✅ PASS |
| 9 | DNS 외부 (google.com) | ✅ PASS |
| 10 | Cross-node 분산 배포 (w1/w2/w3 각 1개) | ✅ PASS |
| 11 | Cross-node pod-to-pod 통신 | ✅ PASS |
| 12 | PVC Bound (hostPath) | ✅ PASS |
| 13 | Pod with PVC Running | ✅ PASS |

**PASS 14/14, FAIL 0**

## 테스트 결과 (2026-04-07) — x86_64

**환경**
- box: `sysnet4admin/Ubuntu-k8s` v1.0.0 (Ubuntu 24.04.4 LTS, x86_64)
- Kubernetes: 1.35.0 / Calico: v3.31.2 / MetalLB: v0.15.3

| # | 테스트 항목 | 결과 |
|---|---|---|
| 1 | Node Status (4/4 Ready) | ✅ PASS |
| 2 | kube-system pods 전체 Running | ✅ PASS |
| 3 | ClusterIP service 접근 | ✅ PASS |
| 4 | NodePort service 접근 | ✅ PASS |
| 5 | LoadBalancer service (MetalLB → 192.168.1.11) | ✅ PASS |
| 6 | DaemonSet (4/4, cp 포함 전 노드) | ✅ PASS |
| 7 | Job 완료 (perl bpi 계산) | ✅ PASS |
| 8 | DNS 내부 (kubernetes.default.svc.cluster.local → 10.96.0.1) | ✅ PASS |
| 9 | DNS 외부 (google.com) | ✅ PASS |
| 10 | Cross-node 분산 배포 (w1/w2/w3 각 1개) | ✅ PASS |
| 11 | Cross-node pod-to-pod 통신 | ✅ PASS |
| 12 | PVC Bound (hostPath) | ✅ PASS |
| 13 | Pod with PVC Running | ✅ PASS |

**PASS 13/13, FAIL 0**
