# 멀티 플랫폼(arm64) 이미지 전수 감사 — 2건 수정 ✅ arm64 실기 검증 완료

> **작업 상태 (2026-08-08)**
> - ✅ **이미지 2건 수정·재푸시 완료** — `sysnet4admin/kustomize:5.4.1`, `sysnet4admin/nginx-status:latest`
> - ✅ **원고 수정 0곳** — 두 건 다 같은 태그로 덮어써서 원고·야믈 그대로
> - ✅ **arm64 실기 검증 완료** — ch5/5.4.3 블루그린 파이프라인 9~15번 전 구간,
>   ch6/6.2.3 익스포터 실습 전 구간 통과
> - ⚠️ **남은 것**: 노드 이미지 캐시 삭제(공저자 환경), x86_64 회귀 확인.
>   아래 "반드시 확인해야 할 것" 절 참고

## 배경

ch5/5.4.3 블루그린 실습을 맥(Apple Silicon)에서 돌리면 실패한다는 공저자(문성주) 보고
(2026-08-08). 원인이 kustomize 이미지의 아키텍처 문제로 확인되어, 같은 유형이 더 있는지
책 전체(ch2~ch7)의 이미지와 소스를 전수 감사했다. 미확인 항목은 남기지 않았다.

**감사 범위**: 이미지 44개 manifest, `sysnet4admin/IaC` Dockerfile 44개,
설치 스크립트 12개, `sysnet4admin/*` 이미지 10개 + Harbor arm64 이미지 3개의 컨테이너 내부 ELF.

**결과: 2건 발견, 둘 다 수정 완료.** 나머지는 정상.

---

## 문제 유형이 둘로 갈린다

이 구분이 중요하다. 둘 다 `docker buildx imagetools inspect`의 platform 목록만으로는
안 잡히거나, 잡히더라도 오판하기 쉽다.

| 유형 | 증상 | manifest 확인으로 잡히나 |
|---|---|---|
| **A. manifest 없음** | amd64 단일 이미지. arm64 노드에서 파드가 안 뜸 | 잡힘 (단일 manifest로 보임) |
| **B. 내용물 불일치** | manifest는 멀티인데 arm64 이미지 안에 amd64 바이너리 | **안 잡힘** |

B 유형은 **맥에서 `docker run`으로 테스트해도 안 드러난다.** Docker Desktop의 Rosetta 2가
amd64 바이너리를 대신 실행해 주기 때문이다. 에뮬레이션이 없는 arm64 리눅스 노드의
containerd에서만 `exec format error`로 터진다.

---

## 수정 1 — `sysnet4admin/kustomize:5.4.1` (유형 B)

### 현상

```
arm64 이미지 내부
  /bin/busybox     ELF e_machine=b700  ->  AArch64   (베이스는 arm64)
  /bin/kustomize   ELF e_machine=3e00  ->  x86-64    (바이너리만 amd64)
```

`sysnet4admin/IaC`의 `docker/Dockerfiles/kustomize/Dockerfile`이
`kustomize_v5.4.1_linux_amd64.tar.gz`를 하드코딩하고 있었다. buildx로 두 플랫폼을 빌드했으나
arm64 빌드에서도 amd64 tarball을 받아왔다. 지목된 커밋(`a0f91bd`)만이 아니라 저장소 HEAD도
같은 상태였다.

### 영향

ch5/5.4.3 블루그린 파이프라인이 이 이미지를 젠킨스 에이전트로 쓴다
(`Bkv2_sub_blue-green/Jenkinsfile` 14번 줄). arm64 클러스터에서 `kustomize build`가 실행되지 않아
배포가 진행되지 않는다. x86_64(편집자 LG그램 등)는 영향 없다.

### 조치

`sysnet4admin/IaC` `2585ca7` — `ARG TARGETARCH`로 아키텍처별 에셋을 받도록 수정.
kustomize v5.4.1 릴리스에 `linux_arm64` 에셋이 실재함을 확인했고 `TARGETARCH` 값이
파일명 규칙과 정확히 맞는다.

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t sysnet4admin/kustomize:5.4.1 --push .
```

새 digest `sha256:d526a7f8…`.

### 검증

| 항목 | 결과 |
|---|---|
| 레지스트리 arm64 변형 | `/bin/kustomize` -> AArch64, v5.4.1 |
| 레지스트리 amd64 변형 | `/bin/kustomize` -> x86-64, v5.4.1 |
| arm64 클러스터 파드(w1-k8s, containerd) | 바이너리 AArch64 |
| 파이프라인과 동일한 kustomize 명령 5개 | 전부 통과, `pl-green`/`namespace: default`/`image: …:green` 정상 생성 |

---

## 수정 2 — `sysnet4admin/nginx-status:latest` (유형 A)

### 현상

```
MediaType : application/vnd.docker.distribution.manifest.v2+json   (manifest list 아님)
태그      : latest  2021-01-09  [linux/amd64]
베이스    : nginx 1.18.0 (debian buster)
```

2021-01-09 푸시된 1판 시절 이미지. `IaC` 저장소에 Dockerfile이 없었다.

### 영향

ch6/6.2.3 "익스포터로 메트릭 수집하기" 실습이 사용한다
(`ch6/6.2.3/nginx-status-annot.yaml`, `nginx-status-metrics.yaml` 19번째 줄).
arm64 노드에서 파드가 뜨지 않는다.

### 조치 — 역공학 복원

기존 이미지의 빌드 히스토리를 보니 공식 nginx 위에 `/etc/nginx/conf.d/default.conf`
**한 파일만** 덮어쓴 구조였다(`nginx.conf`는 베이스와 md5 동일). 그 파일을 그대로 추출해
재사용했고, **추출본과 새 파일은 바이트 단위로 동일**하다.

`sysnet4admin/IaC` `2ae8ebc` — `docker/Dockerfiles/nginx-status/` 신규.

```dockerfile
FROM nginx:1.26.0-alpine-slim

LABEL Name=nginx-status Version=1.26.0

RUN apk add --no-cache bash 

COPY default.conf /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]
```

베이스는 IaC의 다른 nginx 계열(`echo-ip`, `echo-hname`, `audit-trail`, `healthz-nginx`,
`tardy-nginx`, `hpa-cpu-memory`)과 같은 `nginx:1.26.0-alpine-slim`으로 올렸다
(`1.18.0` -> `1.26.0`). alpine-slim에도 `--with-http_stub_status_module`이 컴파일돼 있어
동작에 영향 없음을 `nginx -V`로 확인했다.

새 digest `sha256:636c0ac2…`.

### 검증

| 항목 | 결과 |
|---|---|
| manifest | `oci.image.index` — linux/amd64 + linux/arm64 |
| 바이너리 | arm64 -> AArch64, amd64 -> x86-64, 둘 다 nginx/1.26.0 |
| `GET /` | `request_method : GET \| ip_dest: …` (원고 3단계 "html이 수집돼 실패" 재현) |
| `GET /stub_status` | `Active connections: 1 …` 정상 |
| 익스포터 연동 | `nginx_up 1` |
| **arm64 클러스터 6.2.3 실습 전 구간** | 1단계 배포 -> 4단계 사이드카 추가(2/2 Running) -> 5단계 `nginx_up 1` -> 6단계 삭제, 통과 |

---

## 🔴 반드시 확인해야 할 것

### 1. 노드 이미지 캐시 삭제 (가장 중요)

두 건 다 **같은 태그로 덮어썼다.** 파드 스펙에 `imagePullPolicy`가 없고 태그가 `latest`가
아니면 기본값이 `IfNotPresent`다. **이미 옛 이미지를 받아둔 노드는 캐시를 계속 쓴다.**

수정했는데도 그대로 실패하면 십중팔구 이것이다.

```bash
# 쿠버네티스 노드 전부 (cp + 워커)
crictl rmi docker.io/sysnet4admin/kustomize:5.4.1
crictl rmi docker.io/sysnet4admin/nginx-status:latest

# 도커 호스트 / 개발 머신
docker rmi sysnet4admin/kustomize:5.4.1 sysnet4admin/nginx-status:latest
```

문성주 님 맥에도 기존 이미지가 남아 있을 것이므로 함께 전달할 것.
임시로 `line/kubectl-kustomize:1.30.1-5.4.1`로 교체해 두셨다면 원복해도 된다.

### 2. ch5/5.4.3 블루그린 파이프라인 실기 검증 ✅ 통과 (2026-08-08)

젠킨스를 실제로 세워 1차(blue)/2차(green) 빌드를 돌렸고 **원고 9~15번 전 구간이 통과**했다.
파이프라인이 `sysnet4admin/kustomize:5.4.1` 파드를 에이전트로 띄워
`kustomize create/edit/build`를 실행하는 구조이므로, **이 통과가 곧 kustomize 수정이
실제로 동작한다는 증거**다. 수정 전이었다면 `exec format error`로 막혔을 자리다.

상세는 [bluegreen-pipeline.md](bluegreen-pipeline.md)의 "파이프라인 실기 검증" 절 참고.

### 3. ch6/6.2.3 실습은 arm64에서 전 구간 통과 확인함 ✅

다만 프로메테우스 서버를 세우고 웹 UI에서 Target health까지 본 것은 아니다.
익스포터가 `nginx_up 1`을 내보내는 것까지만 확인했다.

### 4. x86_64 환경 회귀 확인 ⏳ 미수행

두 이미지 다 amd64 변형의 바이너리 아키텍처와 버전은 확인했으나,
x86_64 클러스터에서 실습을 다시 돌려보지는 않았다. 편집자(LG그램) 환경에 영향이 없는지
확인이 필요하다. 특히 `nginx-status`는 베이스가 `nginx:1.18.0` -> `1.26.0`으로 올라가
ch6 캡처와 미세하게 달라질 여지가 있다.

### 5. `public.ecr.aws/docker/library/redis:8.2.3-alpine` ✅ 해소

감사 중 manifest 조회가 429 Too Many Requests로 실패해 한동안 미확인으로 남았으나,
arm64로 직접 받아 실행해 확인 완료.

```
Redis server v=8.2.3 ... bits=64
redis-server 바이너리 -> AArch64 (arm64)
```

AWS ECR Public의 레이트 리밋 때문에 플랫폼 나열(`imagetools inspect`)은 계속 실패할 수 있다.
그럴 때는 `docker run --platform linux/arm64`로 직접 확인하면 된다.
사용처는 `ch7/7.4.2/argocd.yaml` 한 곳이며 Argo CD upstream 매니페스트에 박힌 이미지다.

---

## 정상으로 확인한 것 (재조사 방지)

### 이미지 manifest 44개

공식·서드파티 29개(nginx, alpine, curl, jaeger, otel, argocd, argo-rollouts, metallb,
metrics-server, csi-driver-nfs 계열, dex, nginx-gateway-fabric, reloader, zulu-openjdk,
distroless, bitnami/kubectl, kubernetesui 등) 전부 arm64 포함.

`sysnet4admin/*` 14개 중 `nginx-status` 1개만 문제였고 나머지는 멀티 플랫폼.

### 컨테이너 내부 ELF 실측 (유형 B 탐지)

manifest만 믿지 않고 arm64 변형을 실제로 열어 확인했다. **kustomize 외 혼입 없음.**

```
echo-ip / echo-hname / audit-trail        ELF 11~15개 전부 arm64
hpa-cpu-memory / sleepy                   전부 arm64
net-tools / net-tools-ifn                 ELF 32개 전부 arm64
mysql-auth                                ELF 106개 전부 arm64
dashboard:blue / :canary-v1               ELF 8개 전부 arm64
harbor-core / jobservice / registry-photon (v2.10.0-arm64)   ELF 30개 전부 arm64
```

### IaC Dockerfile 44개

책이 쓰는 이미지 중 바이너리를 직접 내려받는 건 `kustomize` 하나뿐이었다.
나머지는 nginx/alpine 설정만 얹거나(`echo-ip` 등) `apk add`를 쓰고,
`mysql-auth`는 `uname -m` 분기가 이미 있다.

### 설치 스크립트 12개

전부 아키텍처 분기가 제대로 들어가 있다.

```
ch5/5.2.2/install_kustomize.sh       case $(uname -m) 분기
ch5/5.2.3/install_helm.sh             x86_64) ARCH="amd64" 분기
ch7/7.4.3/install_argo_rollouts.sh    uname -m 검사 후 arm64/amd64
ch3/3.1.3/k8s_env_build.sh            분기 있음
ch4/4.4.2/2.harbor/2-1.get_harbor.sh  aarch64 분기
```

`install_argo_rollouts.sh`의 `ARCH="amd64"`는 `uname -m` 검사의 else 분기라 정상.

---

## 변경 파일

### `sysnet4admin/IaC`

| 커밋 | 파일 | 내용 |
|---|---|---|
| `2585ca7` | `docker/Dockerfiles/kustomize/Dockerfile` | `ARG TARGETARCH`로 아키텍처별 다운로드 |
| `2ae8ebc` | `docker/Dockerfiles/nginx-status/{Dockerfile,default.conf}` | 역공학 복원 (신규) |
| `e1cc128` | `docker/Dockerfiles/AGENTS.md` | 멀티 플랫폼 빌드 규약 (신규) |

### Docker Hub

| 이미지 | 태그 | 새 digest |
|---|---|---|
| `sysnet4admin/kustomize` | `5.4.1` (유지) | `sha256:d526a7f8…` |
| `sysnet4admin/nginx-status` | `latest` (유지) | `sha256:636c0ac2…` |

### 책 저장소 / 원고

**변경 없음.** 두 건 다 같은 태그로 덮어썼으므로 아래가 전부 그대로 유효하다.

- `ch6/6.2.3/nginx-status-annot.yaml`, `nginx-status-metrics.yaml`
- `Bkv2_sub_blue-green/Jenkinsfile` 14번 줄 (`sysnet4admin/kustomize:5.4.1`)
- ch5 원고 1719번 줄(리스팅 012), 1811번 줄("4~26번째 줄" 설명)
- ch6 원고 6.2.3 전체 (`nl | grep -A2 annot`의 13~15번째 줄 출력 포함)

## 재발 방지

`sysnet4admin/IaC`의 `docker/Dockerfiles/AGENTS.md`(`e1cc128`)에 규약을 적어 두었다.
멀티 플랫폼 빌드 기본, 태그 규칙(`latest` + `FROM`에서 뽑은 짧은 베이스 버전),
`ARG TARGETARCH` 사용, 맥 `docker run`은 Rosetta 때문에 검증 환경으로 부적합,
푸시 후 ELF `e_machine` 확인, 태그 덮어쓴 뒤 캐시 삭제.
