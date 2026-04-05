# Cilium v1.17.4 → v1.17.13 ✅

## 변경 이유

### 1. 패치 누적 및 안정성 향상

v1.17.4 → v1.17.13 사이 10개 패치 릴리즈 누적. breaking change 없음.

**주요 버그픽스:**

| 버전 | 내용 |
|---|---|
| v1.17.5 | 서비스 삭제 시 삭제된 백엔드로의 연결이 종료되지 않는 문제 수정 |
| v1.17.10 | CiliumEndpoint 조기 GC 방지 (최소 5분 유지) — VM 환경 안정성 향상 |
| v1.17.10 | LBIPAM 충돌 풀 메트릭 수정 |

**보안 패치:**
- Go stdlib CVE 패치 다수 포함
- CVE-2025-64715 (toGroups CiliumNetworkPolicy egress, moderate) — 책 환경에서 AWS toGroups 미사용이므로 직접 영향 없음

### 2. 설치 방식

ch7에서 Cilium은 IaC GitHub raw URL에서 yaml을 직접 적용:

```bash
CNI_ADDR="https://raw.githubusercontent.com/sysnet4admin/IaC/main/k8s/CNI"
kubectl apply -f $CNI_ADDR/cilium-v1.17.4-w-hubble.yaml
```

IaC 저장소에 `cilium-v1.17.13-w-hubble.yaml`이 이미 존재 → 이 저장소 변경은 파일명 1줄만 수정.

### 3. ch7 시나리오 영향 검토

| 시나리오 | 내용 | 영향 |
|---|---|---|
| ch7/7.2.2 Hubble UI | `configure_cilium_connectvity_env.sh` — hubble-ui svc LoadBalancer 패치 | ✅ 없음 (K8s 레벨 작업) |
| ch7/7.2.2 CiliumNetworkPolicy | ICMP allow 정책 | ✅ 없음 (CRD 스키마 변경 없음) |
| ch7/7.1.1 L2 announcement | `cilium-l2mode.yaml`, `cilium-iprange.yaml` (IaC extra-pkgs) | ✅ 없음 (별도 yaml, 버전 독립) |
| ch7/7.2.3 Prometheus Operator | `kubeProxy.enabled: false` | ✅ 없음 (Cilium 버전 무관) |

패치 릴리즈 범위(1.17.x)이므로 모든 시나리오에서 breaking change 없음 확인.

---

## 변경 파일

| 파일 | 변경 전 | 변경 후 |
|---|---|---|
| `ch7/7.1.1/controlplane_node.sh` | `cilium-v1.17.4-w-hubble.yaml` | `cilium-v1.17.13-w-hubble.yaml` |

> IaC 저장소(`sysnet4admin/IaC`)의 `k8s/CNI/cilium-v1.17.13-w-hubble.yaml`은 이미 존재. IaC 변경 불필요.

---

## 테스트 결과

**환경**: ch7/7.1 (4-node cluster) + ch7/7.2.2 (Hubble UI, CiliumNetworkPolicy)

| # | 항목 | 결과 |
|---|---|---|
| 1 | Cilium 버전 확인 (`cilium version`) | ✅ v1.17.13 |
| 2 | 노드 4/4 Ready | ✅ |
| 3 | Cilium + Hubble 파드 Running | ✅ |
| 4 | ClusterIP 서비스 통신 | ✅ |
| 5 | NodePort 서비스 통신 | ✅ |
| 6 | LoadBalancer (192.168.1.11) L2 Announcement | ✅ |
| 7 | DaemonSet 4/4 정상 | ✅ |
| 8 | CoreDNS 조회 | ✅ |
| 9 | PVC 동적 프로비저닝 | ✅ |
| 10 | Hubble UI LoadBalancer (192.168.1.12) | ✅ |
| 11 | CiliumNetworkPolicy ICMP allow/deny | ✅ |

**결과**: PASS 11/11 — ch7 전 시나리오 이상 없음
