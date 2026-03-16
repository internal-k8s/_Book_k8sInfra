# 7.4.2 Argo Rollouts — 블루그린(Blue-Green) 배포

## 목표
- Argo Rollouts 설치 및 블루그린 배포 전략 실습
- Active/Preview 서비스를 통한 무중단 전환 확인
- 기존 Deployment 롤링 업데이트와의 차이점 비교

## 사전 조건
- 7.4.1 ArgoCD 설치 완료

## 실습 파일
- `install_argo_rollouts.sh` — Argo Rollouts 컨트롤러 설치 + 블루그린 배포
- `bluegreen-rollout.yaml` — 블루그린 Rollout + Active/Preview Services
- `explore_bluegreen.sh` — 블루그린 배포 실습 가이드
- `cleanup_7.4.2_tasks.sh` — 리소스 정리

## 실습 순서
1. `install_argo_rollouts.sh`로 컨트롤러 설치 + 블루그린 배포
2. 이미지 변경으로 배포 트리거 → Preview에서 새 버전 확인
3. `kubectl argo rollouts promote`로 전환
4. `explore_bluegreen.sh`로 전체 흐름 확인
