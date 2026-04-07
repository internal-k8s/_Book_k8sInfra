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
