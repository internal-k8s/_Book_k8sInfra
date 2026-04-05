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

## ⚠️ Harbor v2.10.0 arm64 미지원 — 공저자 확인 필요

### 현상

ch4/4.4.2 Harbor 설치 시 arm64 환경에서 다음 오류 발생:

```
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8)
exec /usr/bin/python3: exec format error
```

### 원인

- Harbor v2.10.0의 모든 컴포넌트 이미지(`prepare`, `harbor-core`, `harbor-db` 등)가 **linux/amd64 단일 아키텍처**만 지원
- Docker Hub 확인 결과 arm64 이미지 없음
- `ch4/4.4.2/2.harbor/2-1.get_harbor.sh`에 arch 감지 로직 없음
- QEMU 에뮬레이션도 동작하지 않음 (`exec format error`)

### 공식 arm64 지원 시점

- Harbor GitHub PR #22311 (Full Multi-Architecture Enablement) — v2.16 예정 기능으로 밀림 (2026년 기준 미병합)
- v2.10.x ~ v2.15.x 전 버전 amd64 전용

### 영향

- 책이 arm64 환경(Apple Silicon Mac + VirtualBox)도 지원하도록 설계된 경우 ch4/4.4.2 Harbor 챕터는 동작하지 않음
- x86_64 환경에서는 정상 동작

### 공저자 논의 필요

- arm64 독자에 대한 Harbor 챕터 대응 방안 결정 필요
- 선택지: ① arm64 미지원 명시 (책에 note 추가) ② Harbor 버전 업그레이드 시점에 재검토

---

## 구 yaml 파일 삭제

| 삭제 파일 | 이유 |
|---|---|
| `ch5/5.2.2/FROM_3.4.3/nfs-subdir-external-provisioner-v4.0.0.yaml` | csi-driver-nfs 전환으로 더 이상 사용하지 않음 |

(ch5/5.2.3/FROM_3.4.3/에는 이미 존재하지 않았음)

### docx 영향

직접적인 내용 변경 없음. 불필요 파일 정리.
