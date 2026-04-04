# CSI Driver NFS v4.0.0 → v4.13.1 ✅

> 실제 적용 버전: **v4.12.1** (IaC 기준 latest stable)

## 전환 이유

### 1. nfs-subdir-external-provisioner 프로젝트 상태

| 항목 | nfs-subdir-external-provisioner | csi-driver-nfs |
|---|---|---|
| 최신 릴리즈 | v4.0.2 (2023년) | v4.12.1 (2025년) |
| 유지 관리 | 사실상 중단 | 활발히 개발 중 |
| CSI 표준 준수 | ❌ 비표준 (자체 구현) | ✅ Kubernetes CSI 표준 |
| 소속 | kubernetes-sigs | kubernetes-csi (공식) |

### 2. CSI 표준 준수

- **CSI (Container Storage Interface)**: Kubernetes가 공식 채택한 스토리지 인터페이스 표준
- nfs-subdir-external-provisioner는 CSI 이전 방식의 자체 provisioner로 구현됨
- csi-driver-nfs는 CSI 드라이버로 kubelet의 CSI 플러그인 경로(`/var/lib/kubelet/plugins/csi-nfsplugin`)를 통해 동작
- `CSIDriver` 오브젝트로 클러스터에 드라이버 등록 → `kubectl get csidriver`로 확인 가능

### 3. 아키텍처 개선

| 구성요소 | nfs-subdir-external-provisioner | csi-driver-nfs |
|---|---|---|
| Controller | Deployment (1개) | Deployment (provisioner + resizer + snapshotter) |
| Node agent | 없음 | **DaemonSet** (각 노드에서 NFS 마운트 처리) |
| 볼륨 resize | ❌ | ✅ |
| 볼륨 snapshot | ❌ | ✅ |

### 4. StorageClass 변경

| 항목 | 이전 | 이후 |
|---|---|---|
| provisioner | `k8s-sigs.io/nfs-subdir-external-provisioner` | `nfs.csi.k8s.io` |
| parameters | `pathPattern`, `onDelete` | `server`, `share` |
| mountOptions | 없음 | `nfsvers=4.1` |
| reclaimPolicy | 없음 (기본값) | `Delete` 명시 |

StorageClass 이름 `managed-nfs-storage`는 유지 → 기존 PVC 참조 코드 변경 불필요.

---

## 변경 파일

| 파일 | 내용 |
|---|---|
| `ch3/3.4.3/csi-driver-nfs-v4.12.1.yaml` | 신규 추가 (CSIDriver + RBAC + controller + node DaemonSet) |
| `ch3/3.4.3/storageclass.yaml` | provisioner → `nfs.csi.k8s.io`, server/share 파라미터, nfsvers=4.1 |
| `ch3/.init_infra.sh` | yaml 교체 + 30s CSI readiness wait |
| `ch4/.init_infra.sh` | 동일 |
| `ch5/.init_infra.sh` | 동일 |
| `ch6/.init_infra.sh` | 동일 |
| `ch7/7.1.1/extra_k8s_pkgs.sh` | 동일 |
| `app/D.Operator/0.vagrant/extra_k8s_pkgs.sh` | 동일 |

`ch5/5.2.2/FROM_3.4.3/`, `ch5/5.2.3/FROM_3.4.3/` — `ch3/3.4.3/`의 심볼릭 링크이므로 자동 반영.

---

## 테스트 결과

**클러스터:** ch3/3.1.3 (K8s 1.35.0, Ubuntu 24.04, Calico v3.31.2, MetalLB v0.15.3)

| # | 테스트 | 결과 |
|---|---|---|
| 1 | ClusterIP | ✅ PASS |
| 2 | NodePort | ✅ PASS |
| 3 | LoadBalancer | ✅ PASS |
| 4 | DaemonSet (4 nodes) | ✅ PASS |
| 5 | Job | ✅ PASS |
| 6 | DNS (internal) | ✅ PASS |
| 7 | DNS (external) | ✅ PASS |
| 8 | Cross-node pod distribution | ✅ PASS |
| 9 | Cross-node connectivity | ✅ PASS |
| 10 | PVC (CSI NFS) | ✅ PASS |

**PASS 10/10**
