# 7.3.3 OpenTelemetry의 유연성 — 도구 교체가 쉬운 이유

## 목표
- Collector 뒷단(exporter)을 교체해도 앱 수정 없이 전환 가능함을 실습으로 확인
- 예: Jaeger → Tempo, 유료 → 오픈소스 교체 시나리오
- 실무에서 도구 교체가 빈번한 이유와 OTel 표준의 가치

## 사전 조건
- 7.3.2 완료

## TODO
- [ ] Collector exporter 교체 설정 예제
- [ ] 교체 전후 동일한 모니터링 결과 확인 스크립트
