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
| parameters | `pathPattern`, `onDelete` | `server`, `share`, `mountPermissions: "0777"` |
| mountOptions | 없음 | `nfsvers=4.1` |
| reclaimPolicy | 없음 (기본값) | `Delete` 명시 |

`mountPermissions: "0777"`은 PV permission denied 방지를 위해 필수 (하단 "kubectl apply 경로 PV permission denied" 섹션 참고). **이 파라미터는 원고에서 반드시 설명해야 함** — 하단 🚨 원고 반영 필수 사항 참고.

StorageClass 이름 `managed-nfs-storage`는 유지 → 기존 PVC 참조 코드 변경 불필요.

---

## 변경 파일

| 파일 | 내용 |
|---|---|
| `ch3/3.4.3/csi-driver-nfs-v4.12.1.yaml` | 신규 추가 (CSIDriver + RBAC + controller + node DaemonSet) |
| `ch3/3.4.3/storageclass.yaml` | provisioner → `nfs.csi.k8s.io`, server/share 파라미터, nfsvers=4.1, `mountPermissions: "0777"` (2026-07-12 추가 — permission denied 수정) |
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

## kubectl apply 경로 PV permission denied (2026-07-12 조사 → 수정 완료 ✅)

### 증상

csi-driver-nfs 전환 이후, kubectl apply 경로(`ch3/3.4.3/storageclass.yaml`)로 만든 StorageClass에서 프로비저닝된 PV에 비루트 pod가 쓰기를 시도하면 permission denied(EACCES) 발생. 기존 nfs-subdir-external-provisioner에서는 없던 문제.

### 발현 기전

**기존 (nfs-subdir-external-provisioner)** — upstream `provisioner.go`의 `Provision()`:

```go
if err := os.MkdirAll(fullPath, mode); err != nil { ... }
err := os.Chmod(fullPath, mode)   // mode 기본값 0o777, 무조건 실행
```

`MkdirAll`의 mode는 umask(022)에 깎이므로 이를 무력화하려고 **명시적 `Chmod`를 항상 호출**. 모든 PVC 디렉토리가 예외 없이 777로 생성되어 어떤 uid의 컨테이너든 쓰기 가능했음. "기존에 문제가 없던" 이유가 이 하드코딩된 777.

**신규 (csi-driver-nfs v4.12.1)** — `controllerserver.go`의 `CreateVolume()`:

```go
if err = os.MkdirAll(internalVolumePath, 0777); err != nil { ... }
if mountPermissions > 0 {          // ← 조건부!
    os.Chmod(internalVolumePath, os.FileMode(mountPermissions))
}
```

`mountPermissions` 우선순위: StorageClass `parameters.mountPermissions` → 드라이버 플래그 `--mount-permissions` → 기본값 **0**. 현재 `csi-driver-nfs-v4.12.1.yaml`의 args에도, `ch3/3.4.3/storageclass.yaml`의 parameters에도 없으므로 0 → chmod 미실행. 결과적으로 `MkdirAll(0777)`이 umask 022에 깎인 **0755**(부모 디렉토리에 setgid가 걸린 환경에선 2775)로 남고, export가 `no_root_squash`라 controller가 root로 쓰므로 소유자는 root — 비루트 pod는 쓰기 불가.

**fsGroup이 구제하지 못하는 이유**: 구 provisioner가 만들던 PV는 in-tree `nfs:` 볼륨 소스여서 kubelet이 fsGroup 소유권 변경을 아예 적용하지 않았고(그래서 777에 전적으로 의존하는 설계), 신규 CSI 쪽은 CSIDriver `fsGroupPolicy: File`이라 fsGroup을 지정한 pod는 kubelet이 recursive chown을 해주지만, `runAsUser`만 지정하고 fsGroup은 안 쓰는 차트가 많아 차트별로 동작이 들쭉날쭉함. 일관된 해결책은 `mountPermissions`뿐.

**기존 테스트에서 안 잡힌 이유**: ch3/3.4.3 검증(테스트 10 "PVC (CSI NFS)")은 root로 도는 pod라 통과. uid=1000 검증(Prometheus)은 Helm 경로(ch5/5.2.3)에서만 수행되어 `mountPermissions=0777`이 Helm 스크립트에만 반영됨.

### 영향 범위

kubectl 경로 StorageClass(`ch3/ch4/ch5/ch6 .init_infra.sh`, `ch7/7.1.1/extra_k8s_pkgs.sh`, `app/D.Operator`)를 쓰는 비루트 워크로드 전부:

| 워크로드 | uid | 위치 |
|---|---|---|
| Jenkins | 1000 | `ch5/5.3.1` |
| Prometheus | 65534 | `ch6/6.2.1`, `ch7/7.2.3` |
| Grafana | 472 | `ch6/6.4.1` |
| Loki | 10001 | `ch6/6.6.1` |
| Tempo | — | `ch6/6.6.2`, `ch7/7.3.3` |
| Pyroscope | — | `ch6/6.6.3` |

### 조치 내역 (2026-07-12 적용 완료)

1. ✅ `ch3/3.4.3/storageclass.yaml` parameters에 `mountPermissions: "0777"` 추가 — `FROM_3.4.3` 심볼릭 링크로 ch5 쪽 자동 반영.
2. 대안으로 검토했던 드라이버 args `--mount-permissions` 수정(`csi-driver-nfs-v4.12.1.yaml`)은 **채택하지 않음**: SC 파라미터가 우선 적용되어 중복 설정이 되고, upstream 매니페스트 드리프트가 늘어나며, 독자에게 보이지 않는 설정이기 때문. `nfs_exporter.sh` chmod도 해결책 아님(부모 디렉토리 권한은 하위 PVC 디렉토리에 전파 안 됨).
3. 기존 클러스터 주의: StorageClass parameters는 불변이므로 **SC 삭제 후 재생성** 필요. 파라미터는 신규 프로비저닝 PV에만 적용되므로 **이미 생성된 PV 디렉토리는 NFS 서버에서 수동 `chmod 777`** 필요.

### 🚨 원고 반영 필수 사항 — ch3 (절대 누락 금지)

> **이 항목의 유일한 기록은 이 문서임.** 원고 작업 공간은 이 리포가 아니므로, ch3 원고 작업 시 이 문서를 반드시 다시 열어 아래 내용을 반영할 것. 반영 완료 전까지 이 섹션을 삭제하지 말 것.

csi-driver-nfs로 변경되는 ch3 원고(3.4.3 StorageClass 부분)에 아래 설명을 **반드시** 추가:

1. **`mountPermissions: "0777"` 파라미터가 왜 필요한지**: csi-driver-nfs는 이 값이 없으면 PVC 디렉토리 권한을 조정하지 않아(기본값 0 = chmod 생략) root 소유 0755 디렉토리가 만들어지고, 비루트로 실행되는 pod(Jenkins, Prometheus, Grafana 등 이후 장 실습 전부)가 쓰기 불가 → permission denied.
2. **구판과의 대비**: 기존 nfs-subdir-external-provisioner는 디렉토리를 항상 777로 생성(코드에 하드코딩)했기 때문에 이런 설정이 필요 없었음 — 구판 독자가 "전에는 없던 설정"이라고 혼동하지 않도록 명시.
3. **fsGroup 한계**: NFS 볼륨에서는 pod의 `fsGroup` 설정만으로 권한 문제를 일관되게 해결할 수 없음(차트별 fsGroup 유무 편차) — `mountPermissions`가 표준적인 해법임을 명시.
4. **수동 chmod 안내 삭제 검토 (공저자 확인)**: 원고에 `chmod 777 /nfs_shared/...` 수동 실행 안내가 있다면 삭제 — `mountPermissions`가 자동 처리하므로 불필요하고 혼동 유발.

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

### Helm 기반 배포 (ch5/5.2.3, 파일명은 아래 "파일명/네임스페이스 정리" 이후 기준)

| 테스트 (당시 파일명) | 이미지 | 결과 |
|---|---|---|
| `install_nfs-provisioner+sc_notag_by_helm.sh` | `nfsplugin:v4.11.0` (chart default) | ✅ PASS (5/5 Running) |
| `install_nfs-provisioner+sc_v4.12.1_by_helm.sh` | `nfsplugin:v4.12.1` (명시) | ✅ PASS (5/5 Running) |
| `uninstall_nfs-provisioner+sc.sh` (`helm uninstall`) | — | ✅ PASS |
| Prometheus PVC (uid=1000) — `mountPermissions=0777` 적용 후 | — | ✅ PASS |

**PASS 14/14**

---

## 파일명/네임스페이스 정리: nfs-provisioner → csi-driver-nfs (2026-07-18)

### 배경

ch5/5.2.2, 5.2.3의 파일명과 헬름 릴리스 네임스페이스가 옛 도구 이름(`nfs-provisioner`,
`nfs-subdir-external-provisioner` 시절 명명)을 그대로 쓰고 있었음. 실제로는 이미 CSI Driver NFS로
전환됐는데 이름만 안 바뀐 상태 — `ch5/5.2.2/uninstall_nfs-provisioner+sc.sh`는 내용상 이미
`csi-driver-nfs-v4.12.1.yaml`을 가리키고 있었음 (파일명만 불일치).

### 변경 내용

| 이전 | 이후 |
|---|---|
| `ch5/5.2.2/uninstall_nfs-provisioner+sc.sh` | `ch5/5.2.2/uninstall_csi-driver-nfs+sc.sh` |
| `ch5/5.2.3/install_nfs-provisioner+sc_notag_by_helm.sh` | `ch5/5.2.3/install_csi-driver-nfs+sc_notag_by_helm.sh` |
| `ch5/5.2.3/install_nfs-provisioner+sc_v4.12.1_by_helm.sh` | `ch5/5.2.3/install_csi-driver-nfs+sc_v4.12.1_by_helm.sh` |
| `ch5/5.2.3/uninstall_nfs-provisioner+sc.sh` | `ch5/5.2.3/uninstall_csi-driver-nfs+sc.sh` |
| 헬름 릴리스 네임스페이스 `nfs-provisioner` | ~~`csi-driver-nfs`~~ → **`kube-system`으로 최종 변경** (아래 "네임스페이스 재검토" 참고) |

### 네임스페이스 재검토: 전용 네임스페이스 → `kube-system` (2026-07-18, 최종 결정)

> 아래 "네임스페이스를 없애지 않고 이름만 바꾼 이유"(같은 날 앞서 내린 결정)를 **다시 뒤집음.**
> 최종 결론은 **`kube-system`**. 직전 절은 히스토리로 보존.

**뒤집은 이유**: 직전 결정의 근거였던 원고(2025-05-25) 362번 문단은 **구 도구
(nfs-subdir-external-provisioner) 시절** 것이라, 그 시절엔 3.4.3(kubectl)도 전용 네임스페이스
(`nfs-provisioner`)를 써서 전체가 일관됐음. 그런데 csi-driver-nfs 전환 이후 3.4.3과 5.2.2는
업스트림 yaml이 `namespace: kube-system`을 하드코딩하고 있어 **우리 선택과 무관하게** 이미
`kube-system`에 배포됨. 이 상태에서 5.2.3(Helm)만 전용 네임스페이스를 고집하면, "같은 CSI
드라이버를 3가지 방법(kubectl/kustomize/Helm)으로 설치"하는 흐름의 결과 위치가 갈라져 —
구 원고 문단이 막으려던 "일관성 없음" 문제를 오히려 새로 만드는 셈.

**근거**:
1. **업스트림 공식 설치 예시가 `--namespace kube-system`을 씀** (`kubernetes-csi/csi-driver-nfs`
   charts/README — `helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system`)
   — 실무 관례와도 일치
2. **"전용 네임스페이스라 충돌을 피한다"는 이점이 애초에 없었음** — CSIDriver/ClusterRole/
   ClusterRoleBinding/StorageClass는 전부 클러스터 스코프라 네임스페이스와 무관하게 5.2.2 잔재가
   남아있으면 5.2.3 설치가 `already exists`로 실패함. 즉 5.2.2 삭제(11번 단계)는 어느 네임스페이스를
   택하든 필수 — 네임스페이스 분리로 얻는 게 없었음
3. **"헬름 릴리스는 네임스페이스에 종속된다"는 교육 포인트는 전용 네임스페이스 없이도 가르칠 수 있음**
   — `-n kube-system`을 명시하면서 "이게 3.4.3/5.2.2가 실제로 쓰는 바로 그 네임스페이스"라고
   짚어주는 편이 인위적으로 만든 네임스페이스보다 설득력 있음
4. `--create-namespace` 옵션 자체를 가르치고 싶다면 Helm 설명에서 개념만 언급하면 충분 — 굳이
   CSI 드라이버로 시연할 필요 없음

**최종 변경**: 헬름 릴리스 네임스페이스를 `csi-driver-nfs`가 아니라 **`kube-system`**으로 설치
(`--create-namespace` 불필요 — `kube-system`은 항상 존재). 릴리스 이름(`csi-nfs-release`)은 유지.

**적용 파일**:

| 파일 | 변경 |
|---|---|
| `ch5/5.2.3/install_csi-driver-nfs+sc_v4.12.1_by_helm.sh` | `--namespace csi-driver-nfs --create-namespace` → `--namespace kube-system` |
| `ch5/5.2.3/install_csi-driver-nfs+sc_notag_by_helm.sh` | 동일 |
| `ch5/5.2.3/uninstall_csi-driver-nfs+sc.sh` | `helm uninstall csi-nfs-release -n csi-driver-nfs` → `-n kube-system` |

### docx 영향

**있음.** 5.2.3 원고에서 "전용 네임스페이스 생성" 관련 설명(구 362번 문단 계열)을 `kube-system`
배포로 재작성 필요 — "헬름 릴리스도 네임스페이스에 종속된다"는 설명 자체는 유지하되, 대상
네임스페이스를 `kube-system`으로 바꾸고 "3.4.3/5.2.2와 동일한 위치에 배포된다"는 점을 강조.

### (히스토리) 네임스페이스를 없애지 않고 이름만 바꾼 이유 — 2026-07-18 앞선 결정, 위에서 뒤집힘

원고(2025-05-25 버전) 362번 문단에서 이 네임스페이스를 "헬름 릴리스도 네임스페이스에 종속된다"는 걸
가르치는 의도된 장치로 쓰고 있음이 확인됨 — ch3처럼 `kube-system`에 바로 설치하지 않고 별도
네임스페이스를 쓰는 게 우연이 아니라 교육 목적. 따라서 네임스페이스 자체는 유지하고 이름만 정리.

### ch5/5.2.2 kustomize 실습 재설계 필요 (원고 작업, 코드는 변경 없음)

옛 원고는 `nfs-subdir-external-provisioner:v4.0.0` → `v4.0.1`로 이미지 태그를 바꾸는 걸
kustomize 실습 예제로 썼음. 이 대상이 없어졌으므로 새 예제 필요:

- 대상 파일: `csi-driver-nfs-v4.12.1.yaml`, `storageclass.yaml` (둘 다 `FROM_3.4.3` 심볼릭 링크로
  이미 `ch5/5.2.2/`, `ch5/5.2.3/`에서 접근 가능 — 새 파일 추가 불필요)
- 목표 버전: `nfsplugin:v4.12.1` → **`v4.13.0`** (upstream 실존 확인, 2026-02-02 릴리스)
- **참고**: 이 이미지는 컨트롤러 Deployment와 노드 DaemonSet **두 곳**에 나옴 — 옛 예제(단일 위치)보다
  오히려 "kustomize가 일치하는 모든 위치를 한 번에 패치한다"를 보여주기 좋은 소재
- `kustomize create --resources csi-driver-nfs-v4.12.1.yaml,storageclass.yaml` →
  `kustomize edit set image registry.k8s.io/sig-storage/nfsplugin:v4.12.1=registry.k8s.io/sig-storage/nfsplugin:v4.13.0`
  흐름으로 원고 재작성 필요 (공저자 작업)
