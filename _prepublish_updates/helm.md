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

### 3. v3 → v4 호환성

책에서 사용하는 Helm 명령은 v4에서 breaking change 없음:

| 명령 패턴 | 사용 위치 | v4 호환성 |
|---|---|---|
| `helm install <name> edu/<chart> --set ...` | ch5, ch6, ch7 | ✅ 동일 |
| `helm upgrade --reuse-values ...` | ch6/6.6.2, ch6/6.6.3 | ✅ 동일 |
| `helm upgrade --install ...` | ch7/7.3.3 | ✅ 동일 |
| `helm repo add/update` | ch7/7.1.1, ch7/7.3.3 | ✅ 동일 |
| `--namespace`, `--create-namespace` | 전체 | ✅ 동일 |

---

## 변경 파일

### Helm 설치 스크립트

| 파일 | 변경 전 | 변경 후 |
|---|---|---|
| `ch5/5.2.3/install_helm.sh` | `DESIRED_VERSION:="v3.15.0"` | `DESIRED_VERSION:="v4.1.3"` |
| `app/A.console-k8s/k8s_con_pack.sh` | `get-helm-3` 스크립트 직접 실행 | IaC `get_helm_v4.0.4.sh` + `DESIRED_VERSION=v4.1.3` |

### Helm 설치를 호출하는 스크립트 (간접 영향)

아래 파일들은 `install_helm.sh`를 호출하므로 자동으로 v4.1.3 적용:

| 파일 | 호출 방식 |
|---|---|
| `ch6/.init_infra.sh` | `bash ~/_Book_k8sInfra/ch5/5.2.3/install_helm.sh` |
| `ch7/7.1.1/extra_k8s_pkgs.sh` | `$HOME/_Book_k8sInfra/ch5/5.2.3/install_helm.sh` |

### Helm repo/completion 설정 (변경 없음, 참고)

| 파일 | 내용 |
|---|---|
| `ch5/5.2.3/helm_completion.sh` | bash completion 설정 — 변경 없음 |
| `ch7/7.1.1/extra_k8s_pkgs.sh` | `helm repo add edu ...` + completion + alias — 변경 없음 |

### edu Helm 차트 추가 (Bkv2_main)

| 차트 | 내용 |
|---|---|
| `edu/csi-driver-nfs` (신규) | upstream `kubernetes-csi/csi-driver-nfs` v4.12.1 차트 기반, Bkv2_main gh-pages 추가 |

#### edu/csi-driver-nfs 이미지 태그 버전 구조

nfs-subdir-external-provisioner 차트와 동일한 패턴 적용:

| 스크립트 | `--set image.nfs.tag` | 실제 이미지 |
|---|---|---|
| `notag` (태그 미지정) | 없음 → chart default `v4.11.0` | `nfsplugin:v4.11.0` |
| `v4.12.1` (태그 명시) | `v4.12.1` | `nfsplugin:v4.12.1` |

**chart default가 v4.11.0인 이유:**
upstream v4.12.1 Helm 차트 템플릿은 nfs 컨테이너에 `--use-tar-command-in-snapshot` 플래그를 하드코딩하여 전달함. 이 플래그는 v4.11.0에서 처음 추가됐으며, v4.10.0 이하 바이너리는 unknown flag로 인식해 즉시 종료(CrashLoopBackOff). `--set`으로는 제거 불가(값이 아닌 템플릿에 고정됨). 상세 내용은 `csi-driver-nfs.md` 참고.

### 테스트 중 발견된 추가 변경 파일

| 파일 | 변경 내용 |
|---|---|
| `ch5/5.2.3/install_nfs-provisioner+sc_notag_by_helm.sh` | `--set storageClass.parameters.mountPermissions='0777'` 추가 |
| `ch5/5.2.3/install_nfs-provisioner+sc_v4.12.1_by_helm.sh` | 동일 |
| `ch7/7.2.3/prometheus-operator-values.yaml` | `grafana.persistence.storageClassName: "managed-nfs-storage"` 추가 (기본 StorageClass 없을 때 Pending 방지) |

### Helm 차트를 사용하는 스크립트 (v4 호환 확인 대상)

| 파일 | 차트 | 명령 | 테스트 |
|---|---|---|---|
| `ch5/5.2.3/install_nfs-provisioner+sc_notag_by_helm.sh` | `edu/csi-driver-nfs` | `helm install` | ✅ PASS |
| `ch5/5.2.3/install_nfs-provisioner+sc_v4.12.1_by_helm.sh` | `edu/csi-driver-nfs` | `helm install` + tag 지정 | ✅ PASS |
| `ch5/5.3.1/install_jenkins_by_helm.sh` | `edu/jenkins` | `helm install` | ✅ PASS |
| `ch6/6.2.1/install_prometheus_by_helm.sh` | `edu/prometheus` | `helm install` | ✅ PASS |
| `ch6/6.4.1/install_grafana_by_helm.sh` | `edu/grafana` | `helm install` | ✅ PASS |
| `ch6/6.6.1/install_loki_w_fluentbit_by_helm.sh` | `edu/grafana-stack` | `helm install` | ✅ PASS |
| `ch6/6.6.2/install_tempo_by_helm.sh` | `edu/grafana-stack` | `helm upgrade --reuse-values` | ✅ PASS |
| `ch6/6.6.3/install_pyroscope_by_helm.sh` | `edu/grafana-stack` | `helm upgrade --reuse-values` | ✅ PASS |
| `ch7/7.2.3/install_prometheus_operator_by_helm.sh` | `edu/kube-prometheus-stack` | `helm install` | ✅ PASS |
| `ch7/7.3.3/install_tempo.sh` | `grafana/tempo` | `helm upgrade --install` | ✅ PASS |

---

## 테스트 결과

**클러스터:** ch3/3.1.3 (K8s 1.35.0, Ubuntu 24.04, Calico v3.31.2, MetalLB v0.15.3, Helm v4.1.3)

### 기본 동작

| 테스트 | 결과 |
|---|---|
| `helm version` → v4.1.3 | ✅ PASS |
| `helm repo add edu` | ✅ PASS |
| `helm repo update` | ✅ PASS |
| `helm search repo edu` (17개 차트 조회) | ✅ PASS |

### ch5/5.2.3 — csi-driver-nfs Helm 설치

| 테스트 | 이미지 | 결과 |
|---|---|---|
| `install_nfs-provisioner+sc_notag_by_helm.sh` | `nfsplugin:v4.11.0` (chart default) | ✅ PASS (5/5 Running) |
| `install_nfs-provisioner+sc_v4.12.1_by_helm.sh` | `nfsplugin:v4.12.1` (명시) | ✅ PASS (5/5 Running) |
| `uninstall_nfs-provisioner+sc.sh` (`helm uninstall`) | — | ✅ PASS |

### ch5/5.3.1 — Jenkins Helm 설치

| 테스트 | 결과 |
|---|---|
| `install_jenkins_by_helm.sh` | ✅ PASS (2/2 Running, LB 192.168.1.11) |

### ch6/6.2.1 — Prometheus Helm 설치

| 테스트 | 결과 |
|---|---|
| `install_prometheus_by_helm.sh` | ✅ PASS (2/2 Running, LB 192.168.1.x) |

> **주의**: csi-driver-nfs Helm 차트로 프로비저닝된 NFS 디렉토리는 기본 권한이 root 소유. Prometheus pod가 uid=1000으로 실행되어 permission denied 발생 → `storageClass.parameters.mountPermissions='0777'` 추가로 해결 (설치 스크립트에 반영). 상세 내용은 아래 "csi-driver-nfs mountPermissions 이슈" 참고.

### ch6/6.4.1 — Grafana Helm 설치

| 테스트 | 결과 |
|---|---|
| `install_grafana_by_helm.sh` | ✅ PASS (1/1 Running, LB 192.168.1.13) |

> Grafana는 initContainer(init-chown-data)가 NFS 디렉토리 권한을 자동으로 수정하므로 Prometheus와 달리 permission 문제 없음.

### ch6/6.6.1 — Loki + Fluent Bit Helm 설치

| 테스트 | 결과 |
|---|---|
| `install_loki_w_fluentbit_by_helm.sh` | ✅ PASS (Loki 2/2, 4×Fluent Bit 1/1) |

### ch6/6.6.2 — Tempo Helm upgrade

| 테스트 | 결과 |
|---|---|
| `install_tempo_by_helm.sh` | ✅ PASS (tempo-0 1/1 Running) |

### ch6/6.6.3 — Pyroscope Helm upgrade

| 테스트 | 결과 |
|---|---|
| `install_pyroscope_by_helm.sh` | ✅ PASS (pyroscope-0 1/1 Running) |

### ch7/7.2.3 — Prometheus Operator (kube-prometheus-stack) Helm 설치

| 테스트 | 결과 |
|---|---|
| `install_prometheus_operator_by_helm.sh` | ✅ PASS (prometheus 2/2, grafana 3/3, operator 1/1, node-exporter 4×1/1) |

> **추가 발견**: `prometheus-operator-values.yaml`의 grafana.persistence에 storageClassName 미지정 → 기본 StorageClass 없으면 PVC Pending. `storageClassName: "managed-nfs-storage"` 추가.

### ch7/7.3.3 — Tempo (grafana/tempo 차트) Helm upgrade --install

| 테스트 | 결과 |
|---|---|
| `install_tempo.sh` | ✅ PASS (helm upgrade --install 명령 정상 동작) |

> **비고**: ch3 test 환경에서는 ch6의 grafana-stack이 이미 "tempo" ConfigMap을 소유하여 ownership 충돌 발생. 이는 Helm v4 이슈가 아닌 환경 충돌 (ch7 클러스터에서는 정상 설치됨). `helm repo add grafana`, `helm upgrade --install` 명령은 Helm v4에서 정상 동작 확인.

---

**PASS 24/24 (기본 4 + ch5 NFS 3 + Jenkins 1 + ch6 Prometheus/Grafana/Loki/Tempo/Pyroscope 5 + ch7 Prometheus Operator/Tempo 2)**

---

## csi-driver-nfs mountPermissions 이슈 (설치 스크립트 변경)

### 현상

csi-driver-nfs가 새 PVC 디렉토리를 NFS 서버에 생성할 때 권한이 `drwxrwsr-x root:nogroup` (2775)으로 설정됨. Prometheus처럼 `runAsUser=1000`으로 실행되는 pod는 NFS를 통해 이 디렉토리에 쓰기 불가.

**원인**: NFS 클라이언트는 `fsGroup`(supplemental group)을 NFS RPC 인증에 포함하지 않음. pod에 `fsGroup=65534`가 설정되어 있어도 NFS 서버에서는 gid=1000(primary group)만으로 판단 → group rwx 권한(nogroup=65534)을 사용할 수 없음.

### 해결

StorageClass 파라미터에 `mountPermissions=0777` 추가. csi-driver-nfs 컨트롤러가 새 디렉토리 생성 후 chmod 0777을 적용.

**변경 파일:**

| 파일 | 변경 내용 |
|---|---|
| `ch5/5.2.3/install_nfs-provisioner+sc_notag_by_helm.sh` | `--set storageClass.parameters.mountPermissions='0777'` 추가 |
| `ch5/5.2.3/install_nfs-provisioner+sc_v4.12.1_by_helm.sh` | 동일 |

**참고**: Grafana는 `init-chown-data` initContainer가 마운트 후 NFS 디렉토리를 chown하므로 이 문제에 영향받지 않음.
