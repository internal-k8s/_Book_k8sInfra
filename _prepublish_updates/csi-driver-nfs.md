# CSI Driver NFS v4.0.0 → v4.12.1 ✅

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
| `ch5/5.2.3/install_nfs-provisioner+sc_notag_by_helm.sh` | `edu/nfs-subdir-external-provisioner` → `edu/csi-driver-nfs` + StorageClass 파라미터 변경 + `mountPermissions='0777'` 추가 |
| `ch5/5.2.3/install_nfs-provisioner+sc_v4.0.2_by_helm.sh` → `install_nfs-provisioner+sc_v4.12.1_by_helm.sh` | 파일명 변경 (v4.0.2→v4.12.1) + `edu/csi-driver-nfs` 전환 + `image.nfs.tag='v4.12.1'` 명시 + `mountPermissions='0777'` 추가 |
| `ch5/5.2.3/uninstall_nfs-provisioner+sc.sh` | `kubectl delete` (nfs-subdir yaml) → `helm uninstall csi-nfs-release -n nfs-provisioner` |
| `ch5/5.2.2/uninstall_nfs-provisioner+sc.sh` | `nfs-subdir-external-provisioner-v4.0.0.yaml` → `csi-driver-nfs-v4.12.1.yaml` |
| `ch5/5.2.3/README.md` | 예시 명령 `edu/nfs-subdir-external-provisioner` → `edu/csi-driver-nfs` |

`ch5/5.2.2/FROM_3.4.3/`, `ch5/5.2.3/FROM_3.4.3/` — `ch3/3.4.3/` 심볼릭 링크로 전환됨 (misc.md 참고). 자동 반영.

### ch5/5.2.3 Helm 설치 명령 변경 상세

**이전** (`edu/nfs-subdir-external-provisioner`):
```bash
helm install nfs-prvs-release edu/nfs-subdir-external-provisioner \
--set nfs.server='192.168.1.10' \
--set nfs.path='/nfs_shared/dynamic-vol' \
--set storageClass.name='managed-nfs-storage' \
--set storageClass.pathPattern='${.PVC.namespace}-${.PVC.name}' \
--set storageClass.provisionerName='k8s-sigs.io/nfs-subdir-external-provisioner' \
--set fullnameOverride="nfs-client-provisioner" \
--set storageClass.onDelete='delete'
```

**이후** (`edu/csi-driver-nfs`):
```bash
helm install csi-nfs-release edu/csi-driver-nfs \
--set storageClass.create=true \
--set storageClass.name='managed-nfs-storage' \
--set storageClass.parameters.server='192.168.1.10' \
--set storageClass.parameters.share='/nfs_shared/dynamic-vol' \
--set storageClass.parameters.mountPermissions='0777' \
--set storageClass.reclaimPolicy=Delete \
--set storageClass.volumeBindingMode=Immediate \
--set 'storageClass.mountOptions[0]=nfsvers=4.1'
```

**`mountPermissions=0777` 추가 이유**: csi-driver-nfs가 PVC 디렉토리 생성 시 NFS 서버에서 chmod 0777 적용. 미설정 시 root:nogroup 2775 권한으로 생성되어 uid=1000으로 실행되는 pod(Prometheus 등)가 쓰기 불가. NFS 클라이언트는 fsGroup(supplemental group)을 RPC 인증에 포함하지 않으므로, pod에 fsGroup=65534가 설정되어 있어도 NFS 서버에서 group 권한을 사용할 수 없음.

> **📌 책 본문 검토 필요 (공저자 확인)**: NFS 관련 실습에서 `chmod 777 /nfs_shared/...` 수동 실행을 독자에게 안내하는 내용이 있다면 삭제 검토. csi-driver-nfs Helm 설치 시 `mountPermissions=0777` 파라미터가 PVC 디렉토리 권한을 자동 처리하므로, 수동 chmod 안내는 불필요하거나 혼동을 줄 수 있음.

**주요 차이점:**
| 항목 | nfs-subdir-external-provisioner | csi-driver-nfs |
|---|---|---|
| release 이름 | `nfs-prvs-release` | `csi-nfs-release` |
| NFS 서버 설정 | `nfs.server`, `nfs.path` | `storageClass.parameters.server`, `.share` |
| StorageClass | 차트가 자동 생성 | `storageClass.create=true` 필요 |
| provisioner | `k8s-sigs.io/nfs-subdir-external-provisioner` | `nfs.csi.k8s.io` (차트 기본값) |
| 마운트 옵션 | 없음 | `nfsvers=4.1` |
| 디렉토리 권한 | root:root 755 (provisioner 기본) | `mountPermissions=0777` 명시 필요 (미설정 시 root:nogroup 2775 → uid=1000 pod 쓰기 불가) |

**Helm 차트 제공:** `edu` 리포에 upstream `kubernetes-csi/csi-driver-nfs` v4.12.1 차트를 기반으로 추가 (Bkv2_main gh-pages).

### edu 차트 커스터마이징

nfs-subdir-external-provisioner 차트의 notag/tag 패턴을 동일하게 적용:

| 항목 | upstream 기본값 | edu 차트 설정값 |
|---|---|---|
| `image.nfs.tag` | `v4.12.1` | `v4.11.0` |
| templates | 원본 동일 | 원본 동일 |

| 스크립트 | 이미지 | 동작 |
|---|---|---|
| `notag` (태그 미지정) | `v4.11.0` (chart default) | ✅ PASS |
| `v4.12.1` (태그 명시) | `v4.12.1` | ✅ PASS |

### chart default를 v4.11.0으로 설정한 이유 (상세)

#### 배경: Helm 차트 vs kubectl apply yaml의 차이

책과 SSF, IaC에서 kubectl apply로 배포하는 `csi-driver-nfs-v4.12.1.yaml`의 nfs 컨테이너 args:

```yaml
args:
  - "-v=5"
  - "--nodeid=$(NODE_ID)"
  - "--endpoint=$(CSI_ENDPOINT)"
```

upstream v4.12.1 Helm 차트 템플릿의 nfs 컨테이너 args:

```yaml
args:
  - "--v=5"
  - "--nodeid=$(NODE_ID)"
  - "--endpoint=$(CSI_ENDPOINT)"
  - "--drivername=nfs.csi.k8s.io"
  - "--mount-permissions=0"
  - "--working-mount-dir=/tmp"
  - "--default-ondelete-policy=delete"       ← kubectl yaml에 없음
  - "--use-tar-command-in-snapshot=false"    ← kubectl yaml에 없음
```

Helm 차트 템플릿에 두 플래그가 하드코딩되어 있어 `helm install --set`으로 제거할 수 없음.

#### 각 플래그 설명

**`--default-ondelete-policy`**
- PV가 삭제될 때 NFS 서버의 실제 디렉토리를 어떻게 처리할지 결정
- `delete`: 디렉토리 삭제 / `retain`: 디렉토리 유지 / `archive`: `archived_`로 이름 변경
- 미지정 시 기본값: `""` (빈 문자열, retain과 동일 — 디렉토리 유지)
- StorageClass의 `reclaimPolicy: Delete`(PV 오브젝트 삭제)와는 별개 — 이 플래그 없이는 PV가 사라져도 NFS 서버에 데이터 디렉토리가 남음

**`--use-tar-command-in-snapshot`**
- 스냅샷 생성 시 tar 명령을 사용할지 여부
- `false`가 기본값이므로 실질적 동작 차이 없음
- 책에서 스냅샷 기능을 실습하지 않으므로 무관

#### 버전별 플래그 지원 현황 (실제 바이너리 확인)

| 버전 범위 | `--default-ondelete-policy` | `--use-tar-command-in-snapshot` | chart 호환 |
|---|---|---|---|
| v3.x, v4.0.0 | ❌ | ❌ | ❌ CrashLoopBackOff |
| v4.1.0 ~ v4.10.0 | ✅ | ❌ | ❌ CrashLoopBackOff |
| **v4.11.0 이상** | ✅ | ✅ | ✅ 정상 동작 |

**Go flag 패키지 특성:** 알 수 없는 플래그를 받으면 help 출력 후 즉시 종료 → CrashLoopBackOff로 나타남.

v4.11.0이 현재 v4.12.1 Helm 차트와 호환되는 실질적인 최솟값.

---

## 테스트 결과

**클러스터:** ch3/3.1.3 (K8s 1.35.0, Ubuntu 24.04, Calico v3.31.2, MetalLB v0.15.3)

### kubectl apply 기반 배포 (ch3/3.4.3)

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

### Helm 기반 배포 (ch5/5.2.3)

| 테스트 | 이미지 | 결과 |
|---|---|---|
| `install_nfs-provisioner+sc_notag_by_helm.sh` | `nfsplugin:v4.11.0` (chart default) | ✅ PASS (5/5 Running) |
| `install_nfs-provisioner+sc_v4.12.1_by_helm.sh` | `nfsplugin:v4.12.1` (명시) | ✅ PASS (5/5 Running) |
| `uninstall_nfs-provisioner+sc.sh` (`helm uninstall`) | — | ✅ PASS |
| Prometheus PVC (uid=1000) — `mountPermissions=0777` 적용 후 | — | ✅ PASS |

**PASS 14/14**
