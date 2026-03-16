# 7.3.1 OpenTelemetry란 — 모니터링의 새로운 표준

## 목표
- 6장에서 사용한 OpenTelemetry가 무엇인지 소개
- 로그, 메트릭, 트레이스를 하나의 프레임워크로 통합 처리
- 과거 방식(각 도구별 개별 연동)과의 차이점 설명
- 직접 연결 방식의 한계 → Collector 필요성 제시

## 사전 조건
- 7.2.3 Prometheus + Grafana 설치 완료
- 5장/6장 내용 이해

## 실습 파일
- `jaeger-all-in-one.yaml` — Jaeger 트레이스 백엔드 (OTLP 수신)
- `hotrod-direct.yaml` — HotROD 데모 앱 (Jaeger에 직접 연결)
- `install_jaeger_and_hotrod.sh` — Jaeger + HotROD 배포 스크립트
- `explore_otel_env.sh` — OTel 직접 연결 방식 분석 및 한계 설명

## 실습 순서
1. `install_jaeger_and_hotrod.sh` 실행
2. HotROD UI에서 "Request Ride" 클릭 → 트레이스 생성
3. Jaeger UI에서 트레이스 확인
4. `explore_otel_env.sh`로 직접 연결의 한계 확인
