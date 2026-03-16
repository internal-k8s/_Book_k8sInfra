# 7.3.3 OpenTelemetry의 유연성 — 도구 교체가 쉬운 이유

## 목표
- Collector 뒷단(exporter)을 교체해도 앱 수정 없이 전환 가능함을 실습으로 확인
- Jaeger → Tempo 교체 시나리오
- 실무에서 도구 교체가 빈번한 이유와 OTel 표준의 가치

## 사전 조건
- 7.3.2 완료 (OTel Collector + HotROD 동작 중)

## 실습 파일
- `tempo-values.yaml` — Tempo Helm 설정
- `install_tempo.sh` — Tempo 설치 스크립트
- `otel-collector-to-tempo.yaml` — Collector exporter를 Tempo로 교체한 ConfigMap
- `switch_and_verify.sh` — 백엔드 교체 + 검증 스크립트

## 실습 순서
1. `install_tempo.sh`로 Tempo 설치
2. `switch_and_verify.sh`로 Collector 백엔드를 Jaeger → Tempo로 교체
3. HotROD UI에서 트래픽 발생
4. Grafana에서 Tempo 데이터소스 추가 → 트레이스 확인

## 핵심
```
변경 전: HotROD → Collector → Jaeger
변경 후: HotROD → Collector → Tempo
                                ↑ Collector 설정만 변경
                                ↑ 앱(HotROD)은 수정 없음
```
