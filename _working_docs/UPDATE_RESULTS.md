# _Book_k8sInfra 컴포넌트 업데이트 결과

> 참고: UPDATE_PLAN.md — 업데이트 계획 및 영향도 분석
> 이 문서는 작업 중 기록용으로 v2 책 본문에 포함되지 않음

---

## 진행 상태

| 컴포넌트 | 상태 | 완료일 |
|---|---|---|
| containerd 1.7.x → 2.2.2 | ✅ 완료 (종합 테스트 PASS 14/14) | 2026-04-04 |
| Calico v3.30.1 → v3.31.4 | ⏳ 대기 | - |
| MetalLB v0.13.10 → v0.15.3 | ⏳ 대기 | - |
| CSI Driver NFS v4.13.1 전환 | ⏳ 대기 | - |
| Helm v3 → v4.1.3 | ⏳ 대기 | - |
| Cilium v1.17.4 → v1.17.13 | ⏳ 대기 | - |
| Docker 24 → 29.x | ⏳ 대기 | - |

---

## 1. containerd 1.7.x → 2.2.2 ✅

### 변경 내용

| 파일 | 변경 전 | 변경 후 |
|---|---|---|
| `ch3/3.1.3/Vagrantfile` | `ctrd_V = '1.7.24-1'` | `ctrd_V = '2.2.2-1~ubuntu.24.04~noble'` |
| `ch7/7.1.1/Vagrantfile` | `ctrd_V = '1.7.24-1'` | `ctrd_V = '2.2.2-1~ubuntu.24.04~noble'` |

**수정하지 않은 파일**: `k8s_pkg_cfg.sh` (ch3, ch7) — SSF와 완전 동일 코드, 변경 불필요

### 버전 문자열 변경 이유

Ubuntu 24.04(Noble)부터 Docker APT 저장소의 패키지 버전 형식이 변경됨:
- Ubuntu 22.04(Jammy): `1.7.24-1` (짧은 형식)
- Ubuntu 24.04(Noble): `2.2.2-1~ubuntu.24.04~noble` (distro suffix 포함)

box가 Ubuntu 24.04(sysnet4admin/Ubuntu-k8s v1.0.0)로 전환되면서 Noble 형식 사용.

### APT 저장소 확인

```
# Ubuntu 24.04 Noble ARM64 기준
containerd.io 2.1.5-1~ubuntu.24.04~noble
containerd.io 2.2.0-2~ubuntu.24.04~noble
containerd.io 2.2.1-1~ubuntu.24.04~noble
containerd.io 2.2.2-1~ubuntu.24.04~noble  ← 선택
```

### 배포 테스트 결과 (ch3/3.1.3 기준, 2026-04-04)

**환경**
- box: `sysnet4admin/Ubuntu-k8s` v1.0.0 (Ubuntu 24.04.4 LTS, arm64)
- Kubernetes: 1.35.0
- containerd: 2.2.2

**노드 상태**
```
NAME     STATUS   ROLES           VERSION   OS                   KERNEL              CRI
cp-k8s   Ready    control-plane   v1.35.0   Ubuntu 24.04.4 LTS   6.8.0-107-generic   containerd://2.2.2
w1-k8s   Ready    <none>          v1.35.0   Ubuntu 24.04.4 LTS   6.8.0-107-generic   containerd://2.2.2
w2-k8s   Ready    <none>          v1.35.0   Ubuntu 24.04.4 LTS   6.8.0-107-generic   containerd://2.2.2
w3-k8s   Ready    <none>          v1.35.0   Ubuntu 24.04.4 LTS   6.8.0-107-generic   containerd://2.2.2
```

**종합 테스트 결과 (2026-04-04)**

테스트 스크립트: `ch3/3.1.3/comprehensive_test.sh`

#### ch3/3.1.3 (k8s 1.35.0 + Calico + MetalLB v0.13.10)

| # | 테스트 항목 | 결과 |
|---|---|---|
| 1 | Node Status (4/4 Ready) | ✅ PASS |
| 2 | kube-system pods 전체 Running | ✅ PASS |
| 3 | ClusterIP service 접근 (10.109.x.x) | ✅ PASS |
| 4 | NodePort service 접근 (w1:3xxxx) | ✅ PASS |
| 5 | LoadBalancer service (MetalLB → 192.168.1.11) | ✅ PASS |
| 6 | DaemonSet (4/4, cp 포함 전 노드) | ✅ PASS |
| 7 | Job 완료 (perl bpi 계산) | ✅ PASS |
| 8 | DNS 내부 (kubernetes.default.svc.cluster.local → 10.96.0.1) | ✅ PASS |
| 9 | DNS 외부 (google.com → Non-authoritative answer) | ✅ PASS |
| 10 | Cross-node 분산 배포 (3개 노드에 각 1개) | ✅ PASS |
| 11 | Cross-node pod-to-pod 통신 | ✅ PASS |
| 12 | PVC Bound (hostPath) | ✅ PASS |
| 13 | Pod with PVC Running | ✅ PASS |

**PASS 14/14, FAIL 0**

#### ch7/7.1.1 (k8s 1.34.2 + Cilium v1.17.4 + L2 모드)

| # | 테스트 항목 | 결과 |
|---|---|---|
| 1 | Node Status (4/4 Ready) | ✅ PASS |
| 2 | kube-system pods 전체 Running (cilium, hubble 포함) | ✅ PASS |
| 3 | ClusterIP service 접근 | ✅ PASS |
| 4 | NodePort service 접근 | ✅ PASS |
| 5 | LoadBalancer service (Cilium L2 → 192.168.1.11) | ✅ PASS |
| 6 | DaemonSet (4/4) | ✅ PASS |
| 7 | Job 완료 | ✅ PASS |
| 8 | DNS 내부 (kubernetes.default.svc.cluster.local → 10.96.0.1) | ✅ PASS |
| 9 | DNS 외부 (google.com) | ✅ PASS |
| 10 | Cross-node 분산 배포 (w1/w2/w3 각 1개) | ✅ PASS |
| 11 | Cross-node pod-to-pod 통신 | ✅ PASS |
| 12 | PVC Bound (hostPath) | ✅ PASS |
| 13 | Pod with PVC Running | ✅ PASS |

**PASS 14/14, FAIL 0**

**특이사항**
- `k8s_pkg_cfg.sh`의 `containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/'` 패턴이 containerd 2.2.2에서도 정상 동작 확인
- containerd 2.x config_version=3 포맷으로 변경됐으나 sed 패턴 동작에 영향 없음
- ch7 Cilium L2 구성: `sleep 540/600` background 타이머로 배포 → vagrant up 완료 후 약 9-10분 대기 필요
