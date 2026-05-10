# Kubernetes 1.35.0 → 1.36.0 ✅

## 변경 파일

| 파일 | 변경 전 | 변경 후 |
|---|---|---|
| `ch3/3.1.3/Vagrantfile` | `k8s_V = '1.35.0-1.1'` | `k8s_V = '1.36.0-1.1'` |
| `ch7/7.1.1/Vagrantfile` | `k8s_V = '1.34.2-1.1'` | `k8s_V = '1.36.0-1.1'` |
| `ch7/7.1.1/opt-w12g/Vagrantfile` | `k8s_V = '1.34.2-1.1'` | `k8s_V = '1.36.0-1.1'` |

## 테스트 결과 (2026-05-08)

### ch3/3.1.3 — k8s 1.36.0 + Calico v3.31.2 + containerd 2.2.3

| # | 테스트 항목 | 결과 |
|---|---|---|
| 1 | Node Status (4/4 Ready) | ✅ PASS |
| 2 | kube-system pods 전체 Running | ✅ PASS |
| 3 | NodePort service nginx 접근 (CP/w1/w2/w3) | ✅ PASS |

### ch7/7.1.1 — k8s 1.36.0 + Cilium v1.17.13 + containerd 2.2.3

| # | 테스트 항목 | 결과 |
|---|---|---|
| 1 | Node Status (4/4 Ready) | ✅ PASS |
| 2 | kube-system pods 전체 Running (Cilium, Hubble, CSI NFS 포함) | ✅ PASS |
| 3 | NodePort service nginx 접근 (CP/w1/w2/w3) | ✅ PASS |
