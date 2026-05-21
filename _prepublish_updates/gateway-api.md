# Gateway API (NGINX Gateway Fabric)

## 변경 배경

nginx ingress controller(`kubernetes/ingress-nginx`)가 2026년 3월 deprecated 선언됨.
책 출판 시점(2026년 말)에 deprecated 컨텐츠가 되지 않도록 Kubernetes Gateway API 구현체로 교체.

## 변경 내용

### ch3/3.3.3

| 항목 | 이전 | 이후 |
|---|---|---|
| 컨트롤러 | nginx ingress controller v1.8.0 | NGINX Gateway Fabric v2.6.1 |
| Gateway API CRDs | — | v1.5.1 (standard channel) |
| 라우팅 리소스 | `Ingress` | `Gateway` + `HTTPRoute` |

#### 삭제 파일

| 파일 | 내용 |
|---|---|
| `ch3/3.3.3/ingress_ctrl_nodeport.yaml` | nginx ingress controller (NodePort) 배포 매니페스트 |
| `ch3/3.3.3/ingress-multipath.yaml` | Ingress 멀티패스 라우팅 리소스 |

#### 추가 파일

| 파일 | 내용 |
|---|---|
| `ch3/3.3.3/nginx_gw_fabric_deploy.yaml` | NGINX Gateway Fabric v2.6.1 배포 매니페스트 (LoadBalancer, MetalLB 사용) |
| `ch3/3.3.3/gateway.yaml` | GatewayClass + Gateway + HTTPRoute (/, /hn, /ip 경로) |
| `ch3/3.3.3/nginx_gw_fabric_installer.sh` | Gateway API CRDs + NGINX Gateway Fabric 설치 스크립트 |

## 참고

- 강의 레포 `_Lecture_k8s_learning.kit/ch4/4.9/`에 동일 구현 존재 (v2.2.1 기준)
- 책 ch3/3.3.3은 v2.6.1 + Gateway API v1.5.1로 최신 버전 적용
- ch3/3.3.2에서 MetalLB가 배포되므로 LoadBalancer 타입 사용 가능 (NodePort 불필요)

## 테스트 현황

| 환경 | 상태 | 완료일 |
|---|---|---|
| ch3 (Calico + MetalLB) | ✅ PASS | 2026-05-21 |

### 테스트 결과 (2026-05-21)

- k8s v1.36.0 + containerd 2.2.3 + Calico + MetalLB v0.15.3
- Gateway IP: 192.168.1.11 (MetalLB 할당)
- `curl http://192.168.1.11/`   → nginx 기본 페이지 ✅
- `curl http://192.168.1.11/hn` → hostname 응답 ✅
- `curl http://192.168.1.11/ip` → IP 응답 ✅
