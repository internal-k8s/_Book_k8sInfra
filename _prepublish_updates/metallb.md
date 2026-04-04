# MetalLB v0.13.10 → v0.15.3 ✅

## 변경 파일

| 파일 | 변경 내용 |
|---|---|
| `ch3/3.3.2/metallb-native-v0.15.3.yaml` | 신규 추가 (IaC `k8s/extra-pkgs/v1.35/`에서 복사) |
| `ch3/.init_infra.sh` | `metallb-native-v0.13.10.yaml` → `v0.15.3.yaml` |
| `ch4/.init_infra.sh` | 동일 |
| `ch5/.init_infra.sh` | 동일 |
| `ch6/.init_infra.sh` | 동일 |

## 테스트 결과 (2026-04-04)

**환경**
- box: `sysnet4admin/Ubuntu-k8s` v1.0.0 (Ubuntu 24.04.4 LTS, arm64)
- Kubernetes: 1.35.0 / MetalLB: v0.15.3

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
