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

### 최종 구조

```
app/
├── A.console-k8s/        쿠버네티스 콘솔 노드
├── B.kubespray/          멀티 컨트롤 플레인 (kubespray)
└── C.DeepDiveContainer/  컨테이너 PID 1, runC 직접 사용
```

### 순서

`A(콘솔) → B(kubespray) → C(컨테이너 깊이)` — 환경 확장 → 다른 클러스터 구성 → 컨테이너 내부 심화.

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
| B.kubespray | 1.35.x (kubespray default) | 2.x (kubespray default) | kubespray release-2.31 pin — k8s 1.36 지원 시 v2.32+로 후속 갱신 예정 |
| C.DeepDiveContainer | (Vagrantfile 없음) | — | ch7 클러스터 위에서 진행 |

### `k8s_con_pack.sh` (부록 A) 추가 수정

- 기존 `apt.kubernetes.io/kubernetes-xenial` 저장소 → `pkgs.k8s.io/core:/stable:/v$2/deb/` 로 교체
- 이유: `apt.kubernetes.io` 저장소는 **2024-03에 폐기됨**. 1.36 이상 설치 불가

### docx 영향

**큼.** 부록 본문 전체 재작성 필요:

- 절 번호 D.x / E.x / F.x → A.x / B.x / C.x로 통일
- 본문 k8s 버전 출력 결과 (예: `v1.27.4` → `v1.36.0`, kubespray 본문은 `v1.27.9` → `v1.35.x`)
- 경로 `app/E.DeepDiveContainer/` → `app/C.DeepDiveContainer/`, `app/F.kubespray_kOps/...` → `app/B.kubespray/`
- 새 appB 끝부분에 **"왜 kOps와 다른 도구들을 다루지 않는가"** 텍스트 섹션 신설 (1판/2판 이력 + 시장 조사 근거 포함)
- 새 appC 도입부에 **docker 설치 안내 한 줄** 추가 (아래 참조)
- PID/컨테이너 ID 직접 명시 → 7장 IP 처리와 동일한 "예: " 패턴 적용
- 마크다운 변환 잔재(`\<절\>`, `\<중\>`, `[xxx]{.mark}`, 중첩 번호 등) 정리

### appC docker 의존성 처리

새 appC(컨테이너 깊이)는 `docker run`, `docker exec`, `docker inspect`, `docker export`를 사용하지만, ch7 클러스터(7.1.1 fresh `vagrant up`) 환경에는 **도커가 설치되어 있지 않음**. 도커 설치는 ch4(`ch4/4.2.1/install_docker.sh`)에서 이뤄지며 ch5/ch6의 `.init_infra.sh`도 동일 스크립트를 재사용함.

**적용 방침**: 부록 C 본문 1단계 앞에 다음 안내 문구 + 명령 1줄 삽입.

```
이번 부록은 도커가 필요합니다. ch7 환경(또는 부록 A 이후)에서 진행한다면
시작 전에 cp-k8s에서 다음 명령으로 도커를 설치합니다.

  root@cp-k8s:~# bash ~/_Book_k8sInfra/ch4/4.2.1/install_docker.sh

(4장을 이미 진행하여 도커가 설치된 환경이라면 이 단계를 건너뜁니다.)
```

이 패턴은 ch5/ch6 `.init_infra.sh:15`와 동일 — 코드 중복 없음, install_docker.sh 버전 갱신이 자동으로 부록 C에도 반영됨.

### 추가: ns-remove.sh 파일명 정정

- `app/C.DeepDiveContainer/`에 실제 존재하는 파일명: `ns-remover.sh`
- 1판 시점 본문 표기: `ns-remove.sh` (오타)
- **MD 본문 재작성 시 `ns-remover.sh`로 통일**
