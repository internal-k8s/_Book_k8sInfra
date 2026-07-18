# kustomize v5.4.1 → v5.8.1 ✅

## 변경 이유

`ch5/5.2.2`는 csi-driver-nfs 전환에 맞춰 이번에 새로 작성되는 실습(구 nfs-subdir-external-provisioner 기반 실습 대체)이라, 기존 원고가 `v5.4.1` 출력을 전제로 이미 쓰여 있지 않음 — ch4~ch6 "버전 변경 최소화" 원칙(`misc.md` 참고)의 전제(이미 구버전 기준으로 쓰인 원고를 보호)가 적용되지 않는 케이스.

## 확인한 내용

- **릴리스 에셋 이름·URL 패턴 동일**: `kustomize_v5.8.1_${OS}_${ARCH}.tar.gz` 형식 그대로라 `install_kustomize.sh`의 다운로드 URL 조합 로직 변경 불필요
- **실습에서 쓰는 3개 명령 breaking change 없음**: `kustomize create --resources`, `kustomize edit set image`, `kustomize build` — v5.0 이후 안정적으로 유지되는 핵심 기능. v5.8.0의 회귀 이슈([kustomize#6027](https://github.com/kubernetes-sigs/kustomize/issues/6027))는 child kustomization의 namespace 전파 관련이라, 5.2.2가 쓰는 단일 kustomization.yaml 구조엔 해당 없음
- **저장소 내 다른 참조 없음**: `ch5` 전체에서 kustomize 버전 문자열은 `install_kustomize.sh` 1곳뿐

## 변경 파일

| 파일 | 변경 전 | 변경 후 |
|---|---|---|
| `ch5/5.2.2/install_kustomize.sh` | `VERSION=v5.4.1` | `VERSION=v5.8.1` |

## 참고

`kubectl apply -k`/`kubectl kustomize`로 대체하는 방안도 검토했으나 채택하지 않음 — `kubectl`에는 `kustomize edit` 계열(= `create --resources`, `edit set image`) 명령이 없어 5.2.2 실습의 핵심 교육 포인트(이미지 태그 변경 한 번으로 컨트롤러/노드 두 곳이 동시에 패치됨)를 재현할 수 없음. standalone `kustomize` 바이너리를 계속 사용.

5.2.2 실습 흐름 자체(리소스 목록, 네임스페이스 미생성 등)는 `csi-driver-nfs.md` 문서의 "ch5/5.2.2 kustomize 실습 재설계 필요" 절 참고.
