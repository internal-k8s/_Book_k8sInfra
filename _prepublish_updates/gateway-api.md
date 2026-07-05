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

## LoadBalancer vs NodePort 노출 방식 결정 (2026-07-05)

### 배경

기존 Ingress는 온프레미스/클라우드 여부에 따라 노출 방식이 갈렸다 (온프레미스는 NodePort, 클라우드는 LoadBalancer).
Gateway API로 전환하면서 같은 구분을 그대로 가져가야 할지, 아니면 MetalLB(3.3.2에서 이미 설치)를 활용해
LoadBalancer로 통일할지 검토.

### 리서치 결과

- Kubernetes 공식 Gateway API 문서, gateway-api.sigs.k8s.io 모두 LoadBalancer vs NodePort에 대한
  명시적 권고 없음 — "구현체(implementation)마다 다르다"는 입장
- NGINX Gateway Fabric 공식 문서(`NginxProxy` 리소스)는 **기본값이 LoadBalancer**이며, NodePort는
  수동 설정으로 바꾸는 대안으로만 소개 — 환경별 권장 사항은 제공하지 않음
- 실제 사례([nginx/nginx-gateway-fabric#4384](https://github.com/nginx/nginx-gateway-fabric/issues/4384),
  베어메탈+MetalLB 환경): 서비스 타입을 `ClusterIP`로 두면 외부 IP가 할당되지 않고 실패함
  → **MetalLB는 LoadBalancer 타입 서비스에만 반응해 ARP로 IP를 광고**하는 구조라, MetalLB를 쓰는 이상
  LoadBalancer 타입이 사실상 필수
- 베어메탈 마이그레이션 실전 사례([Medium: MetalLB + Ingress Nginx migration to Gateway API](https://medium.com/@techpaul/metallb-ingress-nginx-migration-to-nginx-fabric-gateway-api-f57ff1fcfa20))도
  NodePort는 논외로 취급하고 LoadBalancer+MetalLB 조합만 다룸

### 결론

"클라우드=LoadBalancer, 온프레미스=NodePort"라는 예전 Ingress식 구분은, 실제로는 "LoadBalancer 컨트롤러가
있는가 없는가"의 구분이었지 "온프레미스인가 아닌가"의 구분이 아니었다. MetalLB는 정확히 그 온프레미스용
LoadBalancer 컨트롤러 역할을 한다. 이 책은 이미 `ch3/3.3.2`에서 MetalLB를 설치해 그 공백을 메워뒀기 때문에,
`ch3/3.3.3`에서는 예전 Ingress 시절 온프레미스가 처했던 제약(LB 컨트롤러 부재)이 더 이상 적용되지 않는다.

**결정: LoadBalancer + MetalLB 유지.** NodePort로 되돌리는 것은 "MetalLB가 없다고 가정"하는 것과 같아,
3.3.2에서 이미 설치한 도구를 3.3.3에서 활용하지 않는 모순이 생긴다.

### 참고 자료

- [Gateway API | Kubernetes](https://kubernetes.io/docs/concepts/services-networking/gateway/)
- [Deploy a Gateway for data plane instances | NGINX Documentation](https://docs.nginx.com/nginx-gateway-fabric/install/deploy-data-plane/)
- [nginx/nginx-gateway-fabric#4384 — No ip address for my gateway (Bare metal cluster)](https://github.com/nginx/nginx-gateway-fabric/issues/4384)
- [MetalLB + Ingress Nginx migration to Nginx Fabric Gateway API (Medium)](https://medium.com/@techpaul/metallb-ingress-nginx-migration-to-nginx-fabric-gateway-api-f57ff1fcfa20)
- [Understanding Kubernetes Gateway API: A Modern Approach to Traffic Management (CNCF)](https://www.cncf.io/blog/2025/05/02/understanding-kubernetes-gateway-api-a-modern-approach-to-traffic-management/)

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
