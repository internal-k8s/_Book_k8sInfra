# _Book_k8sInfra 버전 업데이트 계획

> 최종 업데이트: 2026-03-29
> 비교 기준: [SSF valina 배포 구성](https://github.com/sysnet4admin/SSF) (최신)

---

## 버전 현황 비교

| 컴포넌트 | Book ch3 | Book ch7 | SSF | 최신 Stable |
|---|---|---|---|---|
| **Ubuntu (box)** | 22.04 | 22.04 | 24.04 | **24.04** |
| **Kubernetes** | 1.35.0 | 1.34.2 | 1.35.1 | 1.35.x |
| **containerd** | 1.7.24 | 1.7.24 | 2.2.1 | **2.2.2** |
| **Calico** | v3.30.1 | - | v3.31.2 | **v3.31.4** |
| **Cilium** | - | v1.17.4 | - | LTS: **v1.17.13** |
| **MetalLB** | v0.13.10 | Cilium L2 | v0.15.3 | **v0.15.3** |
| **NFS Provisioner** | nfs-subdir v4.0.0 | nfs-subdir v4.0.0 | CSI NFS v4.12.1 | **CSI NFS v4.13.1** |
| **Helm** | v3.15.0 | (ch5 공유) | v4.0.4 | **v4.1.3** |
| **Docker** | 24.0.6 (ch4) | - | 24.0.6 | **29.3.1** |

---

## 업데이트 항목별 영향도 분석

### 종합 요약

| 컴포넌트 | 실습 영향도 | 수정 범위 | 우선순위 |
|---|---|---|---|
| Ubuntu 22.04 → 24.04 (box) | **높음** | ch3/ch7 Vagrantfile box 교체 + 전 컴포넌트 재검증 | **높음** |
| containerd 1.7 → 2.2 | 중간 | ch3, ch7 Vagrantfile + k8s_pkg_cfg.sh (4개) | **높음** |
| Calico v3.30.1 → v3.31.4 | 낮음 | ch3 controlplane_node.sh (1개) | **높음** |
| MetalLB v0.13.10 → v0.15.3 | 낮음 | ch3 YAML + init_infra.sh (2~3개) | 낮음 |
| NFS → CSI Driver NFS | **높음** | ch3/ch5/ch7 전반 (6개 이상) | **높음** |
| Helm v3 → v4 | 중간~높음 | ch5 + 모든 helm 스크립트 (8개 이상) | 중간 |
| Docker 24 → 29 | 낮음 | ch4 install_docker.sh (1개) | 낮음 |

---

## 1. containerd 1.7.x → 2.2.x

### 변경 필요성
- containerd 1.7.x는 LTS이지만 유지보수 모드, SSF는 이미 2.2.1 사용 중
- K8s 최신 버전과의 장기 호환성 확보

### 영향도: 중간

**핵심 검증 사항**: containerd 2.x에서 config_version=3 포맷으로 변경됨
- SystemdCgroup 경로 변경: `plugins."io.containerd.grpc.v1.cri"` → `plugins."io.containerd.cri.v1.runtime"`
- 현재 `containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/'` 패턴은 2.x에서도 동작 가능하나 **반드시 실제 테스트 필요**
- config_version=2 → 3 마이그레이션 시 경고 메시지 출력될 수 있음

### 수정 필요 파일
| 파일 | 변경 내용 |
|---|---|
| `ch3/3.1.3/Vagrantfile` | `ctrd_V` 값 변경: `1.7.24-1` → `2.2.x-1~ubuntu.22.04~jammy` |
| `ch7/7.1.1/Vagrantfile` | 동일 |
| `ch3/3.1.3/k8s_pkg_cfg.sh` | **변경 불필요** — SSF가 동일 sed 패턴으로 containerd 2.2.1 운영 중 |
| `ch7/7.1.1/k8s_pkg_cfg.sh` | 동일 |

### 주의사항
- `k8s_pkg_cfg.sh`의 sed 패턴은 SSF 환경에서 이미 검증됨 (코드 완전 동일)

---

## 2. Calico 업그레이드 (인증서/토큰 패치 포함)

### 참고
- [CALICO_UPGRADE.md](https://github.com/sysnet4admin/IaC/blob/main/k8s/CNI/CALICO_UPGRADE.md)
- [IaC CNI 저장소](https://github.com/sysnet4admin/IaC/tree/main/k8s/CNI)

### 변경 필요성
Vagrant 환경에서 호스트 suspend/resume 시 SA 토큰 만료 문제:
- Projected SA 토큰: 3,607초(~1시간) 후 만료 → calico-node API 인증 실패
- CNI 토큰: 24시간 후 만료 → 새 Pod 배포 완전 중단

**해결책**: IaC 저장소의 패치된 YAML 사용 (정적 Secret 토큰으로 교체)
**책 기술 방식**: 상세 설명 불필요 — URL 교체만으로 해결되므로 독자 실습에 투명하게 적용

### 영향도: 낮음
- ch3 `controlplane_node.sh` URL 1줄만 변경
- ch7은 Cilium 사용이므로 무관

### 수정 필요 파일
| 파일 | 변경 내용 |
|---|---|
| `ch3/3.1.3/controlplane_node.sh` | `calico-quay-v3.30.1.yaml` → `calico-quay-v3.31.4.yaml` (IaC 저장소 URL) |

### 주의사항
- IaC 저장소에 `calico-quay-v3.31.4.yaml` 파일 생성 필요 (현재 v3.31.2까지 존재)
- 새 버전 YAML에 CALICO_UPGRADE.md의 6단계 토큰 패치 재적용 필요

---

## 3. MetalLB v0.13.10 → v0.15.3

### 변경 필요성
- v0.13.x 업데이트 중단, v0.15.3이 최신 안정 버전 (SSF 기준과 동일)

### 영향도: 낮음
**API 호환성 확인**: L2 모드 + `IPAddressPool` + `L2Advertisement` (모두 `metallb.io/v1beta1`)는 v0.15.x에서 **그대로 호환**
- `metallb-l2-iprange.yaml` 수정 불필요
- BGP 관련 API만 v1beta2로 변경되었으나 현재 실습에서 BGP 미사용

### 수정 필요 파일
| 파일 | 변경 내용 |
|---|---|
| `ch3/3.3.2/metallb-native-v0.13.10.yaml` | v0.15.3 매니페스트로 교체 (파일명 변경) |
| `ch3/.init_infra.sh` | YAML 파일명 참조 업데이트 |
| `ch3/3.3.2/metallb-l2-iprange.yaml` | **변경 불필요** |

---

## 4. NFS Provisioner → CSI Driver NFS v4.13.1

### 변경 필요성
- `nfs-subdir-external-provisioner`는 유지보수 모드, 거의 업데이트 없음
- `csi-driver-nfs`가 kubernetes-sigs 공식 후속 프로젝트, 활발하게 유지보수 중

### 영향도: 높음 (가장 광범위한 수정)

**핵심 전략: StorageClass 이름 `managed-nfs-storage` 유지**
→ PVC 사용 실습 파일들(`persistentvolumeclaim-dynamic.yaml`, Prometheus values 등) 수정 면제

StorageClass 변경사항:
```yaml
# 기존 (nfs-subdir-external-provisioner)
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner

# 변경 후 (CSI Driver NFS)
provisioner: nfs.csi.k8s.io
parameters:
  server: <NFS_SERVER_IP>
  share: /nfs_shared
```

### StorageClass 이름 의존 파일 (수정 불필요)
- `ch3/3.4.3/persistentvolumeclaim-dynamic.yaml` — `managed-nfs-storage`
- `ch3/3.5.2/secretKeyRef.yaml` — `managed-nfs-storage`
- `ch5/5.3.1/install_jenkins_by_helm.sh` — `--set persistence.storageClass=managed-nfs-storage`
- `ch7/7.2.3/prometheus-operator-values.yaml` — `managed-nfs-storage`
- `app/D.Operator/.../elasticsearch.yaml` — `managed-nfs-storage`

### 수정 필요 파일
| 파일 | 변경 내용 |
|---|---|
| `ch3/3.4.3/nfs-subdir-external-provisioner-v4.0.0.yaml` | CSI Driver NFS 매니페스트로 교체 |
| `ch3/3.4.3/storageclass.yaml` | provisioner를 `nfs.csi.k8s.io`로, parameters 구조 변경 |
| `ch3/.init_infra.sh` | 설치 명령 변경 |
| `ch7/7.1.1/extra_k8s_pkgs.sh` | nfs-subdir → CSI Driver NFS 설치로 교체 |
| `ch5/5.2.3/install_nfs-provisioner+sc_v4.0.2_by_helm.sh` | Helm chart 이름 및 values 변경 |
| `ch5/5.2.3/install_nfs-provisioner+sc_notag_by_helm.sh` | 동일 |

---

## 5. Helm v3.15.0 → v4.1.3

### 변경 필요성
- Helm 4 GA 출시 (2025년 11월), SSF는 이미 v4.0.4 사용 중

### 영향도: 중간~높음

**기본 명령어 호환**: `helm install`, `helm upgrade --install`, `helm uninstall`, `helm repo add` 대부분 호환 가능

**검증 필요 부분**:
- `--set` 복잡한 escaping 구문 — `ch5/5.3.1/install_jenkins_by_helm.sh`의 `"kubernetes\.io/hostname"` 패턴
- `edu` 레포(`https://k8s-edu.github.io/Bkv2_main/helm-charts/`) OCI 전환 여부
- install_helm.sh 다운로드 URL 패턴이 v4에서도 동일한지

### Helm 사용 위치 (전수 검증 필요)
| 위치 | 용도 |
|---|---|
| `ch5/5.2.3/` | NFS provisioner 설치 |
| `ch5/5.3.1/` | Jenkins 설치 (복잡한 --set 사용) |
| `ch7/7.1.1/extra_k8s_pkgs.sh` | Helm 설치 + repo add |
| `ch7/7.2.3/` | Prometheus Stack |
| `ch7/7.3.3/` | Tempo |
| `ch7/7.1.3/`, `ch7/7.2.3/`, `ch7/7.5.1/` | cleanup 스크립트 |

### 수정 필요 파일
| 파일 | 변경 내용 |
|---|---|
| `ch5/5.2.3/install_helm.sh` | `DESIRED_VERSION`을 `v4.1.3`으로 변경 |
| 위 Helm 사용 스크립트 전체 | --set escaping, repo URL 호환성 검증 후 필요시 수정 |

---

## 6. Docker 24.0.6 → 29.x

### 변경 필요성
- Docker 24.x 보안 패치 중단, 29.x가 최신 (containerd 2.2.2 번들)

### 영향도: 낮음

**호환성 양호**:
- Dockerfile 기본 문법 (`FROM`, `COPY`, `RUN`, `WORKDIR`, `ENTRYPOINT`, 멀티스테이지) 완전 하위 호환
- `docker compose` V2 하위 명령: 이미 사용 중, 문제 없음
- `docker save` / `docker load` / `ctr import` 체인: 동일하게 동작

### 수정 필요 파일
| 파일 | 변경 내용 |
|---|---|
| `ch4/4.2.1/install_docker.sh` | `docker_V`, `buildx_V`, `compose_V` 버전 문자열 변경 |
| `ch5/5.3.4/install_docker_on_all_nodes.sh` | install_docker.sh 재사용 → 자동 반영 |

### 리스크 검증 필요
- Ubuntu 22.04(Jammy) APT 저장소에서 Docker 29.x 패키지 버전 문자열 확인
- Harbor v2.10.0 + Docker 29.x 호환성 검증 (Harbor 자체 `docker-compose.yml` 사용)

---

## Cilium v1.17.4 → v1.17.13 (ch7)

### 변경 필요성
- 동일 마이너 내 패치 업데이트, 보안 수정 포함
- IaC 저장소에 `cilium-v1.17.4-w-hubble.yaml` 존재 → v1.17.13 버전 새 YAML 필요

### 영향도: 낮음
- ch7/7.1.1 `controlplane_node.sh` URL 변경 및 Helm values 검증

---

## Ubuntu 24.04 Vagrant Box 빌드

**상세 계획**: [IaC/bento/BUILD_PLAN_24.04.md](https://github.com/sysnet4admin/IaC/blob/main/bento/BUILD_PLAN_24.04.md)

- Canonical이 24.04부터 공식 Vagrant Box 배포 중단 → bento 기반 커스텀 빌드 필수
- GitHub Actions로 x86_64/arm64 듀얼 아키텍처 빌드 자동화
- HCP Service Principal 토큰으로 Vagrant Cloud 자동 업로드
- 24.04 전환 시 주의: kube-proxy 커널 이슈, AppArmor 강화, Calico 인터페이스 문제

---

## 진행 상태

### Vagrant Box
- [ ] Ubuntu 24.04 Box 빌드 (IaC 저장소 — [상세 계획](https://github.com/sysnet4admin/IaC/blob/main/bento/BUILD_PLAN_24.04.md))

### 컴포넌트 업데이트
- [ ] containerd 2.2.x 전환 (ch3/3.1.3, ch7/7.1.1)
- [ ] Calico v3.31.4 업그레이드 (IaC YAML 신규 생성 + 패치 적용 선행 필요)
- [ ] MetalLB v0.15.3 업그레이드 (ch3)
- [ ] CSI Driver NFS v4.13.1 전환 (ch3, ch5, ch7)
- [ ] Helm v4.1.3 전환 (ch5 + 전체 helm 스크립트 검증)
- [ ] Cilium v1.17.13 업그레이드 (ch7)
- [ ] Docker 29.x 업그레이드 (ch4) — Harbor 호환성 검증 선행 필요
