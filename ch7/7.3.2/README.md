# 7.3.2 OpenTelemetry Collector를 통한 파이프라인 구축

## 목표
- 6장의 앱→수집서버 직접 연결 방식을 Collector 방식으로 변경
- Collector를 통한 파이프라인 구축 및 동일한 모니터링 결과 확인
- Collector의 필터/변환(processor) 기능 소개

## 사전 조건
- 7.3.1 완료 (Jaeger + HotROD 동작 중)

## 실습 파일
- `otel-collector.yaml` — OTel Collector ConfigMap + Deployment + Service
- `hotrod-with-collector.yaml` — HotROD 앱 (Collector 경유로 변경)
- `install_otel_collector.sh` — Collector 배포 + HotROD 전환 스크립트
- `explore_collector.sh` — Collector 파이프라인 구성 확인

## 실습 순서
1. `install_otel_collector.sh` 실행
2. HotROD UI에서 트래픽 발생
3. Jaeger UI에서 트레이스 확인 (동일한 결과)
4. `explore_collector.sh`로 파이프라인 구조 확인

## 파이프라인 구조
```
HotROD (앱) → OTel Collector → Jaeger
               ├── receivers:  [otlp]
               ├── processors: [batch, attributes]
               └── exporters:  [otlp/jaeger, debug]
```
