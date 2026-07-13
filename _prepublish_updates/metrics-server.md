# metrics-server v0.6.4 → v0.8.1 ✅

## 변경 필요성

- ch3의 다른 컴포넌트를 전부 2026년 기준(k8s 1.36, containerd 2.2.3, Calico 3.31.2, Gateway API, CSI Driver NFS)으로 올렸는데 metrics-server만 2023년 0.6.4로 남아 있었음.
- 0.6.4는 k8s 1.36에서 공식 검증 범위 밖. kubelet 인증/메트릭 포맷 변화로 `kubectl top`이나 HPA가 조용히 실패할 수 있음.
- metrics-server 지원 범위: 0.7.x = k8s 1.27+, 0.8.x = k8s 1.31+. 1.36에는 0.8.1(2026년 1월 기준 최신)이 가장 정확히 맞음.
- 0.7.2 대신 0.8.1 선택: 두 버전 stock 매니페스트 차이는 이미지 태그와 Service의 `appProtocol: https` 한 줄뿐. 1.36 정합성과 2026 기준 일관성을 위해 최신으로.

## notls 커스터마이징

이 실습은 교육용이라 kubelet TLS 검증을 건너뛴다(`--kubelet-insecure-tls`). stock 0.8.1 매니페스트와의 차이는 이 플래그 추가 하나뿐.

- APIService의 `insecureSkipTLSVerify: true`는 stock 0.8.1에 이미 포함되어 있어 별도 편집 불필요(0.6.4도 동일했음).
- 포트는 stock 기본값을 그대로 따름(0.6.4의 4443 → 0.8.1의 10250). 파드 네트워크 네임스페이스라 노드 kubelet 10250과 충돌하지 않음.

```yaml
      - args:
        # Manually Add for lab env(SysNet4Admin/k8s)
        # skip tls internal usage purpose
        - --kubelet-insecure-tls
        - --cert-dir=/tmp
        - --secure-port=10250
        ...
        image: registry.k8s.io/metrics-server/metrics-server:v0.8.1
```

## 변경 파일

| 파일 | 변경 내용 |
|---|---|
| `ch3/3.6.1/metrics-server-0.8.1-notls.yaml` | 신규 추가 (stock 0.8.1 + `--kubelet-insecure-tls`) |
| `ch3/3.6.1/metrics-server-0.6.4-notls.yaml` | 삭제 (git rename으로 처리) |

## 테스트 결과 (2026-07-13)

**환경**
- box: `sysnet4admin/Ubuntu-k8s` (Ubuntu 24.04.4 LTS, arm64)
- Kubernetes: 1.36.2 / containerd 2.2.3 / Calico 3.31.2 / metrics-server v0.8.1
- ch3/3.1.3 클러스터(cp-k8s 192.168.1.10)에서 `vagrant up` 후 검증

| # | 테스트 항목 | 결과 |
|---|---|---|
| 1 | deployment rollout (1/1 Running) | ✅ PASS |
| 2 | APIService `v1beta1.metrics.k8s.io` Available=True | ✅ PASS |
| 3 | `kubectl top nodes` (4개 노드 CPU/메모리 출력) | ✅ PASS |
| 4 | `kubectl top pods -n kube-system` | ✅ PASS |
| 5 | HPA metrics 읽기 (TARGETS `cpu: 0%/50%`, `<unknown>` 아님) | ✅ PASS |
| 6 | 파드 로그 (x509/스크레이프 오류 없음) | ✅ PASS |

**PASS 6/6, FAIL 0**

HPA 검증은 metrics-server 기능만 격리하기 위해 arm64에서 확실히 뜨는 nginx에 requests를 설정하고 `kubectl autoscale`로 확인. 3.6.1의 `hpa.yaml`(이미지 `sysnet4admin/hpa-cpu-memory`)는 별도 실습 파일이라 이번 검증 대상에서 제외.
