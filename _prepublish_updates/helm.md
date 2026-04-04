# Helm v3 → v4.1.3 ✅

## 전환 이유

### 1. Helm v4 주요 변경

| 항목 | v3 | v4 |
|---|---|---|
| OCI 레지스트리 | 실험적(opt-in) | ✅ 기본 지원 |
| Lua 기반 훅 | ❌ | ✅ 신규 |
| 서명 검증 | 별도 설정 | ✅ 강화 |
| ARM64 지원 | 지원 | ✅ 안정화 |

### 2. 설치 방식 변경

`k8s_con_pack.sh`에서 Helm 공식 `get-helm-3` 스크립트(버전 고정 불안정) 방식을
IaC 호스팅 스크립트로 교체 → SSF와 동일한 방식으로 통일.

---

## 변경 파일

| 파일 | 내용 |
|---|---|
| `ch5/5.2.3/install_helm.sh` | `DESIRED_VERSION` v3.15.0 → v4.1.3 |
| `app/A.console-k8s/k8s_con_pack.sh` | `get-helm-3` 방식 → IaC `get_helm_v4.0.4.sh` + `DESIRED_VERSION=v4.1.3` |

---

## 테스트 결과

**클러스터:** ch3/3.1.3 (K8s 1.35.0, Ubuntu 24.04)

| 테스트 | 결과 |
|---|---|
| `helm version` → v4.1.3 | ✅ PASS |
| `helm repo add edu` | ✅ PASS |
| `helm repo update` | ✅ PASS |
| `helm search repo edu` (16개 차트 조회) | ✅ PASS |

**PASS 4/4**
