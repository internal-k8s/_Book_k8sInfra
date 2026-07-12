# 기타 변경 사항

컴포넌트 버전 업데이트가 아닌 **저장소 구조 정리 / 파일 교정 / 스크립트 수정** 류의 변경을 기록합니다.

---

## FROM_3.4.3/ 디렉토리 → 심볼릭 링크 전환

### 변경 내용

| 파일 | 변경 전 | 변경 후 |
|---|---|---|
| `ch5/5.2.2/FROM_3.4.3/` | 일반 디렉토리 (ch3/3.4.3 복사본) | `../../ch3/3.4.3` 심볼릭 링크 |
| `ch5/5.2.3/FROM_3.4.3/` | 일반 디렉토리 (ch3/3.4.3 복사본) | `../../ch3/3.4.3` 심볼릭 링크 |

### 이유

`FROM_3.4.3/`의 목적은 "ch3/3.4.3과 항상 동일"이므로 단일 소스를 바라보는 심볼릭 링크가 적합.
복사본 구조에서는 ch3/3.4.3 변경 시 ch5/5.2.2, ch5/5.2.3 두 곳을 수동으로 동기화해야 해서 누락 위험이 있었음.

### 동작 조건

- Vagrantfile에서 `synced_folder` disabled → VM은 Linux에서 git clone으로 저장소 수신
- Linux git은 심볼릭 링크를 그대로 생성하므로 정상 동작

### docx 영향

직접적인 내용 변경 없음. 동작 방식만 변경.

---

## Harbor arm64 지원 및 버전 업그레이드

→ [harbor.md](harbor.md) 참고

---

## 강의 레포 containerd 버전 문자열 업데이트

Ubuntu 24.04 전환에 따라 5개 강의 레포의 ch2/2.3, ch2/2.4 Vagrantfile의 `ctrd_V` 수정.

| 레포 | 이전 | 이후 |
|---|---|---|
| _Lecture_k8s_learning.kit | `2.2.1-1~ubuntu.22.04~jammy` | `2.2.2-1~ubuntu.24.04~noble` |
| _Lecture_k8s_starter.kit | `2.2.1-1~ubuntu.22.04~jammy` | `2.2.2-1~ubuntu.24.04~noble` |
| _Lecture_cicd_learning.kit | `2.2.1-1~ubuntu.22.04~jammy` | `2.2.2-1~ubuntu.24.04~noble` |
| _Lecture_prom_learning.kit | `2.2.2-1~ubuntu.22.04~jammy` | `2.2.2-1~ubuntu.24.04~noble` |
| _Lecture_graf_learning.kit | `2.2.2-1~ubuntu.22.04~jammy` | `2.2.2-1~ubuntu.24.04~noble` |

변경 파일: 각 레포 `ch2/2.3/Vagrantfile`, `ch2/2.3/Manual-Setup/Vagrantfile`, `ch2/2.4/Vagrantfile`

---

## 구 yaml 파일 삭제

| 삭제 파일 | 이유 |
|---|---|
| `ch5/5.2.2/FROM_3.4.3/nfs-subdir-external-provisioner-v4.0.0.yaml` | csi-driver-nfs 전환으로 더 이상 사용하지 않음 |

(ch5/5.2.3/FROM_3.4.3/에는 이미 존재하지 않았음)

### docx 영향

직접적인 내용 변경 없음. 불필요 파일 정리.

---

## 부록(app/) 재편 (2026-05)

기존 6개 부록(A/B/D/E/F — C는 결번)을 **3개 체계(A/B/C)** 로 정리.
일부 항목은 ch7 본문으로 흡수, 일부는 폐기, 일부는 위치 이동.

### 변경 매핑

| 이전 (부록) | 이후 | 처리 |
|---|---|---|
| `app/A.console-k8s` | `app/A.console-k8s` | 유지 (k8s 1.36 + containerd 2.2.3로 버전 통일) |
| `app/B.Dashboard` | — | **ch7/7.1.3 Headlamp**가 대체 → 디렉토리 폐기 |
| `app/D.Operator/1.cilium` | `ch7/7.2.2/cilium-networkpolicy` | 이미 ch7로 흡수 완료 |
| `app/D.Operator/2.elasticsearch` | — | **폐기** (사유: 아래 참조) |
| `app/D.Operator/0.vagrant` | — | ch7/7.1.1 클러스터로 대체 → 폐기 |
| `app/E.DeepDiveContainer` | `app/C.DeepDiveContainer` | 위치 이동만 (내용 동일) |
| `app/F.kubespray_kOps/kubespray` | `app/B.kubespray` | 상위로 승격 |
| `app/F.kubespray_kOps/kOps` | — | **실습 폐기, 텍스트 설명만** (사유: 아래 참조) |

### 최종 구조 (2026-05-25 B/C 스왑 반영)

```
app/
├── A.console-k8s/        쿠버네티스 콘솔 노드
├── B.DeepDiveContainer/  컨테이너 PID 1, runC 직접 사용
└── C.kubespray/          멀티 컨트롤 플레인 (kubespray)
```

> 위 표(변경 매핑)의 `app/E.DeepDiveContainer → app/C.DeepDiveContainer`,
> `app/F.kubespray_kOps/kubespray → app/B.kubespray`는 2026-05 재편 **1차** 결과입니다.
> 이후 커밋 `78f65c6`("app: swap B(kubespray)→C and C(DeepDiveContainer)→B for
> better learning flow", 2026-05-25)에서 학습 흐름상 순서를 다시 바꿔
> DeepDiveContainer가 B, kubespray가 C로 최종 확정됐습니다. 아래 "순서"도 이에 맞게 갱신.

### 순서

`A(콘솔) → B(컨테이너 깊이) → C(kubespray)` — 환경 확장 → 컨테이너 내부 심화 → 다른 클러스터 구성.

### D.Operator/2.elasticsearch 폐기 사유

- ch7 워커 노드 자원(3.5GB × 3) 한계로 elasticsearch operator + prometheus operator 동시 운용 불가
- 책 전략: 오퍼레이터 패턴 학습은 ch7/7.2.3 Prometheus Operator로만 진행
- 성주와 통화 확정 (2026-05-19)
- `UPDATE_PLAN.md`에 남아 있던 elasticsearch.yaml 참조도 함께 정리

### kOps 실습 폐기 사유

- **1판에는 kOps 챕터 없음**
- 2판을 준비하던 2024년에 부록 신설 검토 후 실습 원고까지 작성
- 2026-05 재검토 결과 **실습 폐기, 텍스트 설명으로 대체** 결정
- 근거:
  - 관리형 K8s(EKS/GKE/AKS) 시장 점유율 합산 60% 이상 (2026 Northflank 보고서 기준)
  - kOps는 활성 프로젝트지만 사용처가 협소 (AWS IaC + EKS 비사용 환경)
  - AWS 비용·계정·IAM 의존성으로 책 부록에 적합하지 않음
- kubespray는 온프레미스·베어메탈·규제 환경 용도로 가치가 있어 부록 B로 유지

### 버전 통일 결과

| 부록 | k8s | containerd | 비고 |
|---|---|---|---|
| A.console-k8s | **1.36.0-1.1** | **2.2.3-1~ubuntu.24.04~noble** | ch7과 동일 |
| B.DeepDiveContainer | (Vagrantfile 없음) | — | ch7 클러스터 위에서 진행 |
| C.kubespray | 1.35.x (kubespray default) | 2.x (kubespray default) | kubespray release-2.31 pin — k8s 1.36 지원 시 v2.32+로 후속 갱신 예정 |

### `k8s_con_pack.sh` (부록 A) 추가 수정

- 기존 `apt.kubernetes.io/kubernetes-xenial` 저장소 → `pkgs.k8s.io/core:/stable:/v$2/deb/` 로 교체
- 이유: `apt.kubernetes.io` 저장소는 **2024-03에 폐기됨**. 1.36 이상 설치 불가

### docx 영향

**큼.** 부록 본문 전체 재작성 필요:

- 절 번호 D.x / E.x / F.x → A.x / B.x / C.x로 통일
- 본문 k8s 버전 출력 결과 (예: `v1.27.4` → `v1.36.0`, kubespray 본문은 `v1.27.9` → `v1.35.x`)
- 경로 `app/E.DeepDiveContainer/` → `app/B.DeepDiveContainer/`, `app/F.kubespray_kOps/...` → `app/C.kubespray/` (2026-05-25 B/C 스왑 반영)
- 새 appC 끝부분에 **"왜 kOps와 다른 도구들을 다루지 않는가"** 텍스트 섹션 신설 (1판/2판 이력 + 시장 조사 근거 포함)
- 새 appB 도입부에 **docker 설치 안내 한 줄** 추가 (아래 참조)
- PID/컨테이너 ID 직접 명시 → 7장 IP 처리와 동일한 "예: " 패턴 적용
- 마크다운 변환 잔재(`\<절\>`, `\<중\>`, `[xxx]{.mark}`, 중첩 번호 등) 정리

### appB docker 의존성 처리

새 appB(컨테이너 깊이)는 `docker run`, `docker exec`, `docker inspect`, `docker export`를 사용하지만, ch7 클러스터(7.1.1 fresh `vagrant up`) 환경에는 **도커가 설치되어 있지 않음**. 도커 설치는 ch4(`ch4/4.2.1/install_docker.sh`)에서 이뤄지며 ch5/ch6의 `.init_infra.sh`도 동일 스크립트를 재사용함.

**적용 방침**: 부록 B 본문 1단계 앞에 다음 안내 문구 + 명령 1줄 삽입.

```
이번 부록은 도커가 필요합니다. ch7 환경(또는 부록 A 이후)에서 진행한다면
시작 전에 cp-k8s에서 다음 명령으로 도커를 설치합니다.

  root@cp-k8s:~# bash ~/_Book_k8sInfra/ch4/4.2.1/install_docker.sh

(4장을 이미 진행하여 도커가 설치된 환경이라면 이 단계를 건너뜁니다.)
```

이 패턴은 ch5/ch6 `.init_infra.sh:15`와 동일 — 코드 중복 없음, install_docker.sh 버전 갱신이 자동으로 부록 B에도 반영됨.

### 추가: ns-remove.sh 파일명 정정

- `app/B.DeepDiveContainer/`에 실제 존재하는 파일명: `ns-remover.sh`
- 1판 시점 본문 표기: `ns-remove.sh` (오타)
- **MD 본문 재작성 시 `ns-remover.sh`로 통일**

### 부록 C 호스트 자원 안내

부록 C(kubespray)는 9개 VM 구성으로 **약 11.6GB 메모리**를 요구합니다.

| 구분 | 메모리 | 비고 |
|---|---|---|
| CP × 3 | 1640MB × 3 = 4.9GB | kubespray preflight `minimal_master_memory_mb: 1500` 통과용 마진 |
| Worker × 6 | 1152MB × 6 = 6.9GB | kubespray preflight `minimal_node_memory_mb: 1024` 통과용 마진 |
| 합계 | **11.6GB** | — |

**메모리를 더 줄일 수 없는 이유**: kubespray release-2.31의 `roles/kubernetes/preinstall/tasks/0040-verify-settings.yml`에 강제 assert가 있어 위 최저값 미달 시 `ansible-playbook cluster.yml` 실행이 즉시 실패합니다. 우회(`ignore_assert_errors=true`)는 OOM 리스크 큼.

**MD 본문 재작성 시 추가할 안내**:

```
부록 C를 진행하기 전에 7장의 가상 머신은 vagrant halt로 종료하길 권장합니다.
호스트 메모리 24GB(예: MacBook M2 24GB) 환경에서는 7장(약 13GB)과 부록 C
(약 11.6GB)의 동시 운용이 어렵습니다.

  $ cd ~/_Book_k8sInfra/ch7/7.1.1
  $ vagrant halt
  $ cd ~/_Book_k8sInfra/app/C.kubespray
  $ vagrant up
```

호스트 메모리가 32GB 이상이면 동시 운용도 가능하지만, 본 부록은 단독 운영을 기준으로 합니다.

---

## 파일명 규칙: `.sh`는 `_`, `.yaml`은 `-` (2026-07-05)

### 규칙

| 확장자 | 구분자 | 예 |
|---|---|---|
| `*.sh` | 언더스코어(`_`) | `install_helm.sh`, `k8s_pkg_cfg.sh` |
| `*.yaml` | 하이픈(`-`) | `rollout-nginx.yaml`, `nginx-gw-fabric-deploy.yaml` |

### 적용 범위

- **부록(`app/`)은 예외** — 기존 명명 방식을 그대로 유지, 이번 정리 대상에서 제외
- **정렬 목적의 앞자리 번호**(`1-1.create_certs.sh`, `2-1.get_harbor.sh` 등)의 하이픈은 규칙 대상이 아님 — 순서 표기이지 단어 구분자가 아니므로 유지
- 이미 언더스코어와 하이픈이 섞여 쓰이고 있으나 문맥상 고유명사/합성어에 가까운 경우(`nfs-provisioner`, `grafana-stack`)는 이번 일괄 변경에서 제외

### 이번에 변경한 파일

| 이전 | 이후 |
|---|---|
| `ch3/3.3.1/curl-get.sh` | `ch3/3.3.1/curl_get.sh` |
| `ch3/3.3.2/curl-get.sh` | `ch3/3.3.2/curl_get.sh` |
| `ch3/3.4.2/nfs-exporter.sh` | `ch3/3.4.2/nfs_exporter.sh` |
| `ch3/3.6.2/curl-cpu.sh` | `ch3/3.6.2/curl_cpu.sh` |
| `ch3/3.6.2/curl-memory.sh` | `ch3/3.6.2/curl_memory.sh` |
| `ch4/4.3.2/build-in-host.sh` | `ch4/4.3.2/build_in_host.sh` |
| `ch7/7.1.3/add-viewer-context.sh` | `ch7/7.1.3/add_viewer_context.sh` |

파일명 변경과 함께, `nfs_exporter.sh`(ch3/3.4.2, ch3/3.4.3 양쪽) 내부의 `usage: nfs-exporter.sh <name>` 안내 문구도 `usage: nfs_exporter.sh <name>`로 함께 수정.

### docx 영향

**있음.** 위 7개 파일이 언급되는 모든 본문 명령·경로 예시(`bash ~/_Book_k8sInfra/...`, `vagrant provision` 대상 스크립트명 등)를 새 파일명으로 갱신 필요. 특히 `curl-get.sh`, `nfs-exporter.sh`, `curl-cpu.sh`, `curl-memory.sh`, `build-in-host.sh`, `add-viewer-context.sh`가 등장하는 절을 확인할 것.

---

## 부록 A: grap_kubeconfig.sh → grab_kubeconfig.sh 오타 정정 (2026-07-05)

- `app/A.console-k8s/grap_kubeconfig.sh`는 "grab(가져오다) kubeconfig"의 오타로 확인 — `grap`은 존재하지 않는 단어
- 부록은 파일명 규칙(`_`/`-`) 정리 대상에서는 예외로 뒀으나, 이건 규칙 문제가 아니라 순수 오타라 별도로 수정
- `app/A.console-k8s/grap_kubeconfig.sh` → `app/A.console-k8s/grab_kubeconfig.sh`로 변경, `Vagrantfile`의 `file`/`shell` 프로비저닝 참조도 함께 수정
- ns-remove.sh(위 항목)와 동일한 유형의 오타 정정

### 주석 표현 정정 (같은 파일, 2026-07-05)

파일명 오타와 별개로, 실제 동작과 다른 주석 2곳도 함께 수정:

| 위치 | 이전 | 이후 | 사유 |
|---|---|---|---|
| `grab_kubeconfig.sh:3` | `# create .kube_config directory` | `# create .kube directory` | 실제 생성 디렉터리는 `~/.kube`, `.kube_config`가 아님 |
| `grab_kubeconfig.sh:9,14` | `Book-k8sInfra` (하이픈) | `_Book_k8sInfra` (언더스코어) | 실제 저장소/생성 스크립트명과 표기 통일 |

### docx 영향

부록 A 본문에서 `grap_kubeconfig.sh`를 언급하는 부분이 있다면 `grab_kubeconfig.sh`로 갱신 필요.

### 동일 오타, 다른 저장소에서도 발견 및 수정 (2026-07-05)

GitHub 코드 검색으로 같은 오타(`grap_kubeconfig`)를 쓰는 다른 저장소를 확인, 소유/쓰기 권한이 있는 2곳을 동일하게 수정:

| 저장소 | 경로 | 상태(수정 전) | 조치 |
|---|---|---|---|
| `sysnet4admin/IaC` | `k8s/clusters/consoles/k8s-console/` | Vagrantfile 참조가 주석 처리되어 비활성 | 파일명 + `.kube_config dir` 주석 수정, push 완료 (`c9a7ea3..21b1d5a`) |
| `sysnet4admin/_Lecture_k8s_learning.kit` | `A/A.021/1.Console-k8s/` | Vagrantfile에서 활성 참조 (실제 강의 수강생에게 영향) | 동일 수정, push 완료 (`876c55b..e05cfad`) |

타인이 포크한 저장소(`Eunryong/_Lecture_k8s_learning.kit`, `jonsoku-dev/k8s_learning`, `jamin12/programing_practice` 등)에도 같은 오타가 있으나, 소유 저장소가 아니라 수정하지 않음.

---

## ch7: opt-w12g 경로 완전 제거 (2026-07-12)

### 배경

7.5 절(sLLM 실습)에 호스트 메모리 여유가 있는 독자를 위한 확장 경로가 두 개 공존하고 있었다.

| 경로 | 방식 | 요구 호스트 메모리 |
|---|---|---|
| `opt-w12g` (구) | 기존 워커(w1~w3) 전부를 12GB로 키워 각자 더 큰 모델 실행 | 약 48GB (cp+w1~w3 4대 × 12GB) |
| `w4-k8s` (7.5.3, 신) | 기존 클러스터(13GB)에 정제(aggregator) 전용 워커 1대(16GB)만 추가 | 약 29~32GB |

두 경로가 책 본문(리뷰 기준)에서 서로 참조 없이 따로 안내되어 모순처럼 읽혔고,
`ch7/7.5.3/cleanup_7.5_tasks.sh`도 opt-w12g 모델을 여전히 정리 대상에 포함하고 있어
코드 차원에서도 "둘 다 살아있는 옵션"처럼 보이는 상태였다.

### 결정

**opt-w12g 완전 제거.** 7.5.3에서 이미 w4-k8s(정제 전용 워커 1대 추가) 방식으로
재설계됐으므로, 별도로 워커 전체를 12GB로 키우는 경로는 유지하지 않는다.

### 삭제한 파일

| 파일 | 내용 |
|---|---|
| `ch7/7.1.1/opt-w12g/Vagrantfile` | cp+w1~w3 전부 12288MB로 키운 대체 클러스터 정의 |
| `ch7/7.5.2/install_sllm_models_for_w12g.sh` | opt-w12g 워커에 큰 모델 배포하는 스크립트 |
| `ch7/7.5.2/models/opt-w12g/*.yaml` (3개) | gemma4:e2b, llama3.2:3b, qwen3.5:4b 배포 매니페스트 |

### 수정한 파일

| 파일 | 변경 내용 |
|---|---|
| `ch7/7.5.3/cleanup_7.5_tasks.sh` | opt-w12g 모델 정리 블록(4줄) 삭제 |

### 함께 발견해 수정한 별개 버그

같은 파일(`cleanup_7.5_tasks.sh`)에서, w4-k8s 노드 제거 안내 문구가 존재하지 않는
`remove_aggregator_model.sh`를 가리키고 있었음 — 실제 파일명은 `del_aggregator_model.sh`.
opt-w12g와 무관한 별개의 죽은 참조라 함께 수정.

### 남겨둔 것 (건드리지 않음)

- `_prepublish_updates/containerd.md`, `kubernetes.md`, `ubuntu.md`의 `ch7/7.1.1/opt-w12g/Vagrantfile`
  언급 — 해당 시점 버전 업그레이드 이력을 기록한 것이라, 다른 이력 문서와 동일하게 과거 기록으로 보존

### ch7/docs 설계 노트 처리 (2026-07-12)

`ch7/docs/7.5-design-notes.md`, `7.5-ollama-image-build-prompt.md`, `7.5-performance-test-results.md`는
실제 기능 코드가 아니라 당시 성능 테스트/설계 탐색 기록(트러블슈팅, 메모리 실측치)이라 삭제하지 않고
내용은 그대로 보존. 대신 세 파일 모두 맨 위에 "opt-w12g는 제거되었고 w4-k8s로 대체됨" 안내 문구를
추가해, 최신 구현과 혼동하지 않도록 함.

### docx 영향

7.5.2/7.5.3 본문에서 "호스트 메모리 48GB 이상이면 opt-w12g로" 안내하는 부분을 전부 제거하고,
w4-k8s(정제 전용 워커 추가, 약 32GB 권장) 경로로 통일 필요. 상세 반영 지점은 리뷰 노트의
213행/1830행/1920행 참고.

---

## ch7/7.5.3: w4 노드 추가 방식을 호스트 전용 vagrant 명령으로 재설계 (2026-07-12)

### 문제

기존 `add_aggregator_model.sh`는 호스트에서 실행해야 하는 스크립트였으나 (vagrant up 포함),
원고에는 게스트(cp-k8s) 안에서 실행하는 것처럼 `root@cp-k8s:...#` 프롬프트로 표기돼 있었음.
게스트 안에는 vagrant/virtualbox가 없어 원고대로 실행하면 실패. 게다가 Windows에서 호스트가
bash 스크립트를 실행하려면 Git Bash/WSL이 필요한데, 책 전체 어디에도 이런 전제가 없었음
(PowerShell 네이티브 실행 전제와 충돌).

### 근본 원인

`add_aggregator_model.sh`가 "vagrant up으로 VM 기동" + "ssh 프록시로 kubectl 실행"을 한
스크립트에 몰아넣은 구조였음. 하지만:
- `ch7/7.1.1/controlplane_node.sh`의 조인 토큰은 `--token-ttl 0`(만료 없음) — w4가 나중에
  합류해도 w1~w3와 동일한 `worker_nodes.sh`로 조인 가능, 특별한 로직 불필요
- `ch7/7.5.3/w4-k8s`(현 `add-node4`)는 `ch7/7.1.1`과 별개의 Vagrant 프로젝트라, 특정 머신만
  지정해서 `vagrant up w4-k8s-1.36.1`을 실행하면 cp/w1~w3는 전혀 건드리지 않고 이름 충돌도 없음
  — 순수 네이티브 vagrant 명령으로 충분, bash 래퍼가 애초에 불필요했음
- kubectl은 K8s API 레벨에서 동작해 어느 vagrant 디렉터리로 VM을 띄웠는지와 무관 — w4가
  조인되면 cp-k8s 안에서 평소처럼 바로 보임

### 참고한 선례

`sysnet4admin/_Lecture_k8s_learning.kit`의 `ch3/3.8/add-node4-v1.35/2.3-add-node4/` —
클러스터에 4번째 노드를 추가하는 용도의 디렉터리를 `add-node4`로 명명하고, Vagrantfile +
조인용 셸 스크립트만 두는 패턴. SeongJuMoon님의 `_Lecture_prom_learning.kit`도 동일 계열 구조.

### 변경 내용

| 항목 | 이전 | 이후 |
|---|---|---|
| 디렉터리 | `ch7/7.5.3/w4-k8s/` | `ch7/7.5.3/add-node4/` |
| VM 기동 | `add_aggregator_model.sh`(호스트, bash, vagrant+ssh프록시 포함) | 호스트에서 `vagrant up w4-k8s-1.36.1` 직접 실행 (플랫폼 공통, bash 불필요) |
| 모델 배포 | 위 스크립트가 ssh 프록시로 원격 실행 | `ch7/7.5.3/install_aggregator_model.sh` — cp-k8s 게스트 안에서 실행하는 순수 kubectl 스크립트 (`ch7/7.5.2/install_sllm_models.sh`와 동일 패턴, 파일명 접두사 `install_`도 ch7 관례에 맞춰 통일) |
| 제거(teardown) | `del_aggregator_model.sh`(호스트, bash) | 삭제 — 책 마지막 절이라 정리를 필수 단계로 다루지 않기로 함. 저자가 개인적으로 정리할 땐 `add-node4/`에서 `vagrant destroy -f w4-k8s-1.36.1` 한 줄이면 충분 |

### 함께 정리

- `ch7/7.5.3/cleanup_7.5_tasks.sh`에서 (이미 삭제된) `del_aggregator_model.sh`를 안내하던
  죽은 참조 블록 제거. 모델 Deployment/Service 삭제 로직은 유지.

### docx 영향

7.5.3 3번 단계(정제 모델 교체) 전면 재작성 필요 — 상세 반영 지점은 별도로 정리해 전달.
