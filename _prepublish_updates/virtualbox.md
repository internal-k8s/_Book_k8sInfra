# VirtualBox

## 변경 내용

| 항목 | 이전 | 이후 |
|---|---|---|
| 버전 | v7.1.10 | **v7.2.8** |
| 위치 | `ch2/2.1.1/virtualbox-v7.1.10/` | `ch2/2.1.1/virtualbox-v7.2.8/` |

## brew cask .rb 변경 사항 (7.1 → 7.2)

- `choiceVBoxKEXTs`, `choiceOSXFuseCore` pkg choice 제거 (arm64에서 KEXT 불필요)
- `depends_on macos: ">= :catalina"` → `depends_on :macos`
- `on_arm / on_intel` 블록으로 desc 분리

## .cmd 업데이트

| 파일 | 변경 내용 |
|---|---|
| `ch2/2.1.1/.cmd` | virtualbox-v7.2.8 참조 + winget 명령 추가 |

## networks.conf 불필요 확인 (2026-05-21)

- macOS + VirtualBox 7.2.8에서 `/etc/vbox/networks.conf` **없이** `192.168.1.x` host-only 네트워크 정상 동작
- `ch2/2.1.1/host-only-allowed-ranges.sh`는 macOS에서 불필요 → Linux 전용으로 명시 필요
- 검증: ch2/2.2.3 (멀티 VM + ping), ch3/3.1.3 (k8s 4노드) 모두 PASS

## 테스트 결과 (2026-05-21)

| 환경 | 상태 |
|---|---|
| ch2/2.2.3 (멀티 VM + host-only + ping) | ✅ PASS |
| ch3/3.1.3 (k8s 4노드 클러스터) | ✅ PASS |

## host-only-allowed-ranges.sh 제거 (2026-07-04)

### 제거 사유

- macOS는 VirtualBox 7.2.8에서 `networks.conf` 없이도 host-only 네트워크가 정상 동작 (위 검증 완료) → 애초에 이 스크립트가 불필요
- Windows도 이 스크립트와 무관 (Linux 호스트 전용 안내)
- 책 독자층 중 Linux를 호스트 OS로 쓰는 비중이 사실상 없음
- 즉 윈도/macOS만 남기면 이 스크립트는 어느 쪽에도 필요 없어, 본문 안내와 저장소 파일을 모두 정리하는 게 혼란을 줄임

### 처리

- `ch2/2.1.1/host-only-allowed-ranges.sh` 파일 삭제 (본문에서 참조되지 않는 상태로 남겨두면 "이 스크립트 뭐지?" 하는 혼란만 유발)
- docx 본문에서도 관련 안내 문단 삭제 필요 (해당 문단 위치는 별도 확인)
