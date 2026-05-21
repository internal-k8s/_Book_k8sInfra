# Vagrant

## 변경 내용

| 항목 | 이전 | 이후 |
|---|---|---|
| 버전 | v2.4.7 | **v2.4.9** |
| 위치 | `ch2/2.1.1/arm64/vagrant-v2.4.7/` | `ch2/2.1.1/arm64/vagrant-v2.4.9/` |

## 업그레이드 필수 이유

Vagrant 2.4.7은 VirtualBox 7.2를 지원하지 않음 (지원 목록: 7.1까지).
VirtualBox v7.2.8 사용 시 Vagrant v2.4.9 이상 필수.

## .cmd 업데이트

| 파일 | 변경 내용 |
|---|---|
| `ch2/2.1.1/arm64/.cmd` | vagrant-v2.4.9 brew + winget 명령 추가 |

## 테스트 결과 (2026-05-21)

| 환경 | 상태 |
|---|---|
| ch2/2.2.3 (멀티 VM + host-only + ping) | ✅ PASS |
| ch3/3.1.3 (k8s 4노드 클러스터) | ✅ PASS |
