# 개발 도구 버전 업데이트 (VirtualBox / Vagrant / Tabby)

## 변경 배경

책 출판 시점(2026년 말) 기준 최신 버전으로 업데이트.
VirtualBox 7.2.8 + Vagrant 2.4.9 조합에서 host-only 네트워크 동작 검증 포함.

## 변경 내용

| 도구 | 이전 | 이후 | 위치 |
|---|---|---|---|
| VirtualBox | v7.1.10 | **v7.2.8** | `ch2/2.1.1/arm64/virtualbox-v7.2.8/` |
| Vagrant | v2.4.7 | **v2.4.9** | `ch2/2.1.1/arm64/vagrant-v2.4.9/` |
| Tabby | v1.0.196 | **v1.0.234** | `ch2/2.3.1/tabby-v1.0.234/` |

## 주요 변경 사항 (VirtualBox 7.1 → 7.2)

- `choiceVBoxKEXTs`, `choiceOSXFuseCore` pkg choice 제거 (arm64에서 KEXT 불필요)
- `depends_on macos: ">= :catalina"` → `depends_on :macos`
- `on_arm / on_intel` 블록으로 desc 분리

## .cmd 파일 업데이트

| 파일 | 변경 내용 |
|---|---|
| `ch2/2.1.1/arm64/.cmd` | VirtualBox winget 추가, Vagrant winget+brew 추가 |
| `ch2/2.3.1/.cmd` | 신규 생성 (Tabby winget+brew) |

## 테스트 결과 (2026-05-21)

### networks.conf 불필요 확인
- macOS + VirtualBox 7.2.8에서 `/etc/vbox/networks.conf` **없이** `192.168.1.x` host-only 네트워크 정상 동작
- `ch2/2.1.1/host-only-allowed-ranges.sh`는 macOS에서 불필요 (Linux 전용으로 명시 필요)

### ch2/2.2.3 (멀티 VM + host-only + ping)
- VirtualBox 7.2.8 + Vagrant 2.4.9로 cp + w1/w2/w3 기동 ✅
- cp → w1/w2/w3 ping 0% packet loss ✅

### ch3/3.1.3 (k8s 클러스터)
- 4노드 모두 Ready ✅
- ch3/3.3.3 Gateway API (NGINX Gateway Fabric v2.6.1) 라우팅 테스트 ✅

### Vagrant 2.4.7 → 2.4.9 필수
- Vagrant 2.4.7은 VirtualBox 7.2를 지원하지 않음 (지원 목록: 7.1까지)
- VirtualBox 7.2.8 사용 시 Vagrant 2.4.9 이상 필수
