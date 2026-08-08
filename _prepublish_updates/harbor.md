# Harbor v2.10.0 → v2.15.0 (테스트 완료) → v2.10.0 (최종 결정, 2026-07-17) ✅

> **최종 결정(2026-07-17)**: v2.15.0까지 arm64 이미지 빌드·클린 환경 검증 전부 완료했으나, ch4~ch6
> 버전 변경 최소화 정책(`_prepublish_updates/misc.md`)에 따라 원고에 이미 쓰인 v2.10.0으로 되돌림.
> Docker/Docker CLI 문제(29.x의 `docker images` 출력 개편)와 달리 Harbor 자체엔 v2.15.0을 써야 할
> 만한 새 문제가 있던 건 아니었음 — 일관성을 위한 결정.

> ## ✅ arm64 블로커 해소 (2026-08-08 클린 환경 검증)
>
> upstream(`goharbor`)이 arm64 이미지를 배포하지 않는 것은 그대로입니다(v2.16부터 정식 지원 예정,
> 2026년 9월). 따라서 `ch4/4.4.2/2.harbor/2-1.get_harbor.sh`와 `ch4/4.4.2/uninstall_harbor.sh`의
> arm64 분기는 `sysnet4admin/*:v2.10.0-arm64` 이미지가 Docker Hub에 있어야 동작합니다.
>
> **이 이미지들은 이미 존재합니다.** 필요한 11개 태그 전부 Docker Hub에서 확인했고
> (`prepare`, `harbor-core`, `harbor-db`, `harbor-jobservice`, `harbor-log`, `harbor-portal`,
> `harbor-registryctl`, `harbor-exporter`, `redis-photon`, `nginx-photon`, `registry-photon`),
> `harbor-core:v2.10.0-arm64`의 푸시 시각은 `2026-07-17T10:37:40Z`입니다. 즉 이 문서에
> "미착수"로 적힌 그 날 빌드·푸시가 이뤄졌고 문서만 갱신되지 않은 상태였습니다.
>
> **클린 arm64 환경 검증 완료(2026-08-08)**: Harbor를 한 번도 설치한 적 없는 ch3/3.1.3 클러스터
> (aarch64, `/opt/harbor` 없음, Docker 컨테이너 0개)에서 `1-1` → `1-2` → `2-1` → `2-2` → `2-3` →
> `2-4.install.sh`를 순서대로 실행. 로컬 이미지 캐시가 전혀 없는 상태에서 10개 이미지
> (compose 9개 + `prepare`)를 전부 Docker Hub에서 pull해 9개 컨테이너 모두 healthy,
> `docker login`·`docker push`·`/v2/_catalog` 정상. `harbor-exporter`는 metrics 미활성이라
> 배포되지 않음(하단 "harbor-exporter 배포 여부" 절 참고).
>
> x86_64는 이 분기와 무관하게 정상 동작합니다 (arm64 분기를 타지 않음).

---

## arm64 지원 문제

### 현상

Harbor v2.10.0 ~ v2.15.0 전 버전의 컴포넌트 이미지가 **linux/amd64 단일 아키텍처**만 지원.  
arm64 환경에서 `prepare` 이미지 실행 시 아래 오류 발생:

```
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8)
exec /usr/bin/python3: exec format error
```

- Docker Hub에 arm64 이미지 없음 (전 버전)
- QEMU 에뮬레이션도 동작하지 않음 (`exec format error`)
- Harbor PR #22311 (Full Multi-Architecture Enablement) — v2.16 예정 (2026년 9월)

### 해결 방법 — arm64 이미지 직접 빌드

`ch4/4.4.2/_image-builder/build.sh` 작성 (gitignore, 저자 전용).

**빌드 방법**:
1. `make/photon/exporter/Dockerfile`에서 `ENV GOARCH=amd64` 제거 (1줄 패치)
2. `make build` 실행 (`DEVFLAG=false`, `TRIVYFLAG=false`, `BUILD_BASE=true`, `PULL_BASE_FROM_DOCKERHUB=false`)
3. 결과물 `sysnet4admin/...:v2.15.0-arm64`로 DockerHub 푸시

**arch 감지 적용 방식** (prom 강의 키트 패턴):  
`2-1.get_harbor.sh`에 arch 분기 추가 → arm64 감지 시 `2-3.prepare` 내 이미지명을 sed로 치환, `docker-compose.yml` 생성 후에도 치환하도록 prepare에 sed 명령 append.

> ⚠️ 아래는 **최초 구현 형태(역사 기록)**. 태그 sed의 이중 치환 버그("버그 수정" 섹션)와, 그 수정 때 네임스페이스 sed까지 잘못 제거된 문제를 거쳐 **최종 올바른 형태는 하단 "arm64 네임스페이스 치환 재주입" 섹션의 코드**임.

```bash
if [ "$(uname -m)" == "aarch64" ]; then
  sed -i "s,goharbor/prepare:${HARBOR_VERSION},sysnet4admin/prepare:${HARBOR_VERSION}-arm64,gi" 2-3.prepare
  echo '
sed -i "s,goharbor/,sysnet4admin/,gi" /opt/harbor/docker-compose.yml
sed -i "s,:v2.15.0,:v2.15.0-arm64,gi" /opt/harbor/docker-compose.yml
' >> 2-3.prepare
fi
```

**arm64 이미지 빌드 상태**: ✅ 완료 — 11개 이미지(`prepare`, `harbor-core`, `harbor-db`, `harbor-jobservice`, `harbor-log`, `harbor-portal`, `harbor-registryctl`, `harbor-exporter`, `redis-photon`, `nginx-photon`, `registry-photon`) 모두 `sysnet4admin/*:v2.15.0-arm64`로 DockerHub 푸시 완료 (2026-07-12 전체 태그 존재 재검증)

---

## v2.10.0 → v2.15.0 주요 변경 (히스토리 — v2.10.0으로 되돌려서 아래 변경들은 더 이상 해당 없음)

> v2.10.0으로 최종 확정되면서, 아래 변경 사항들은 이제 겪지 않음. "Copy docker pull" 버튼 관련
> docx 수정도 **불필요**.
>
> **✅ 2026-08-08 ch4 원고 전수 확인 결과 — 원복할 것 없음.** Harbor 버전 표기는 전부 `v2.10.0`
> (`goharbor/prepare:v2.10.0`, `goharbor/harbor-jobservice:v2.10.0` 등)이고 `v2.15.0` 흔적은
> 0건. 애초에 **"Copy docker pull" 버튼이나 아티팩트 체크박스 선택 흐름을 설명하는 대목이
> 원고에 존재하지 않음**(`Copy`/`아티팩트`/`toolbar`/`포털` 검색 결과 Harbor UI 관련 히트 없음).
> 즉 v2.15.0 UI를 미리 반영한 부분도 없었음.

### UI/UX 변경 — v2.10.0 유지로 더 이상 해당 없음

#### "Copy docker pull" 버튼 위치 변경 (v2.13+) — goharbor/harbor#21155

| 항목 | v2.12 이하 (변경 전) | v2.13+ (변경 후) |
|---|---|---|
| **위치** | 이미지 목록 테이블 **상단 toolbar** 버튼 | 각 행(row)의 **인라인 아이콘** |
| **활성화 조건** | 아티팩트 체크박스 선택 필수, 미선택 시 greyed-out | 선택 없이 즉시 클릭 가능 |
| **외형** | 텍스트 기반 버튼 | 아이콘 버튼 (복사 완료 시 toast 메시지) |
| **단계 수** | 체크박스 선택 → 버튼 클릭 (2~3 click) | 아이콘 클릭 1회 (1 click) |
| **런타임 선택** | 없음 | navbar에서 docker/podman/nerdctl/ctr/crictl 선택 가능 |

**docx 수정 범위:**
- Harbor 이미지 상세 페이지 스크린샷: 상단 toolbar 버튼 → 행별 인라인 아이콘으로 교체
- 설명 텍스트: "아티팩트 선택 후 클릭" 흐름 → "행의 아이콘 클릭" 으로 수정

### 기능 변경 — 책 영향 없음

| 변경 | 영향 |
|---|---|
| v2.11: Cosign 서명 지원 강화 | 책 미사용 |
| v2.12: OIDC 개선 | 책 미사용 |
| v2.13: 로봇 계정 UI 개편 | 기본 계정 사용으로 영향 없음 |
| v2.14: OCI artifact 지원 확대 | 책 미사용 |
| v2.15: Proxy cache 개선 (이슈 #23025) | proxy-cache 미사용으로 영향 없음 |

---

## 변경 파일

### 최종 (v2.10.0, 2026-07-17)

| 파일 | 변경 내용 | 상태 |
|---|---|---|
| `ch4/4.4.2/2.harbor/2-1.get_harbor.sh` | `HARBOR_VERSION` v2.15.0 → v2.10.0, arm64 분기 주석에 이미지 의존성 명시 | ✅ |
| `ch4/4.4.2/uninstall_harbor.sh` | `TAG` v2.15.0 → v2.10.0 | ✅ |
| `sysnet4admin/*:v2.10.0-arm64` (Docker Hub) | v2.10.0 소스로 arm64 이미지 11개 재빌드·재푸시 | ✅ 완료 (2026-07-17 푸시, 2026-08-08 클린 환경 검증) |
| docx | **수정 불필요 확인 완료** — ch4 원고의 Harbor 버전 표기가 전부 `v2.10.0`이고 `v2.15.0` 흔적 0건. 원복할 것 없음 | ✅ (2026-08-08 전수 확인) |

### (히스토리) v2.15.0 작업 내역

| 파일 | 변경 내용 | 상태 |
|---|---|---|
| `ch4/4.4.2/2.harbor/2-1.get_harbor.sh` | v2.10.0 → v2.15.0, arm64 arch 감지 추가 | ✅ (되돌림) |
| `ch4/4.4.2/2.harbor/2-1.get_harbor.sh` | **arm64 네임스페이스 sed 재주입 (하단 "arm64 네임스페이스 치환 재주입" 섹션)** | ✅ 적용 + 클린 환경 검증 완료 (2026-07-12, 되돌림) |
| `ch4/4.4.2/_image-builder/build.sh` | arm64 이미지 빌드 스크립트 (저자 전용, 리포 미포함 — 원저자 로컬에만 존재) | ✅ (v2.10.0 재빌드 시 재사용 가능) |
| `ch4/4.4.2/uninstall_harbor.sh` | TAG v2.10.0 → v2.15.0 + arm64 분기 추가 | ✅ (되돌림) |
| docx (ch4/4.4.3 또는 Harbor 사용 설명) | "Copy docker pull" 위치 변경 스크린샷 | v2.10.0 유지로 불필요해짐 |

---

## 버그 수정 — docker-compose.yml 이중 치환

> **⚠️ 2026-07-12 정정**: 이 섹션의 결론("sed 주입 라인 전체 제거", "prepare 이미지명만 치환하면 충분")은 **틀린 것으로 판명됨**. 전제였던 "arm64 prepare가 이미 올바른 이미지명 생성"이 태그에만 해당하고 네임스페이스에는 해당하지 않음. 반드시 하단 **"arm64 네임스페이스 치환 재주입"** 섹션 참고. 이 섹션은 경위 기록용으로만 유지.

### 현상

arm64 prepare 이미지(`sysnet4admin/prepare:v2.15.0-arm64`)가 이미 `IMAGENAMESPACE=sysnet4admin`, `VERSIONTAG=v2.15.0-arm64`로 빌드되어 있어, docker-compose.yml을 생성할 때 이미 올바른 이미지명(`sysnet4admin/harbor-core:v2.15.0-arm64`)을 사용함. *(→ 2026-07-12 정정: 태그(`v2.15.0-arm64`)는 맞지만 네임스페이스는 `goharbor`로 생성됨)*

그런데 `2-1.get_harbor.sh`의 arm64 블록이 `2-3.prepare`에 아래 sed를 추가로 주입:
```bash
sed -i "s,:v2.15.0,:v2.15.0-arm64,gi" /opt/harbor/docker-compose.yml
```
→ `v2.15.0-arm64` 내의 `:v2.15.0`도 치환하여 `v2.15.0-arm64-arm64` 이중 태그 생성.

### 수정 (→ 과잉 제거였음, 하단 🚨 섹션에서 재수정)

docker-compose.yml sed 주입 라인 전체 제거 (arm64 prepare가 이미 올바른 이미지명 생성).
`prepare` 이미지명만 치환하면 충분. *(→ 태그 sed 제거는 옳았으나 네임스페이스 sed까지 같이 제거된 것이 잘못)*

---

## arm64 네임스페이스 치환 재주입 (2026-07-12 조사 → 적용 → 클린 환경 검증 완료 ✅)

> `2-1.get_harbor.sh` 수정 및 **이미지 캐시 없는 클린 arm64 환경 검증까지 2026-07-12 완료.** 이 섹션은 발현 기전과 재발 방지(태그 sed 금지, 클린 환경 검증 필수) 기록용으로 유지.

### 증상

**깨끗한 arm64 클러스터**(이미지 캐시 없는 신규 VM)에서 `2-4.install.sh` 실행 시, `docker compose up`이 `goharbor/harbor-core:v2.15.0-arm64` 등 **Docker Hub에 존재하지 않는 이미지**를 pull 시도 → manifest not found로 전 컨테이너 기동 실패 → 실습 진행 불가. x86_64는 영향 없음.

### 발현 기전 (upstream v2.15.0 소스로 확인)

prepare 컨테이너가 docker-compose.yml을 생성할 때 이미지명의 **네임스페이스와 태그는 출처가 다름**:

| 구성 요소 | 출처 | `sysnet4admin` prepare 이미지에서의 결과 |
|---|---|---|
| 네임스페이스 (`goharbor/`) | `make/photon/prepare/templates/docker_compose/docker-compose.yml.jinja`에 **하드코딩** (`image: goharbor/harbor-core:{{version}}`) | `goharbor/` 그대로 ❌ |
| 태그 (`{{version}}`) | Makefile `versions_prepare` 타깃이 prepare 이미지 안에 굽는 `versions` 파일의 `VERSION_TAG`(=`$VERSIONTAG`) | `v2.15.0-arm64` ✅ |

- `IMAGENAMESPACE`는 Makefile에서 **빌드 결과물의 로컬 태깅/푸시 이름에만** 사용되고, prepare 이미지 내부(템플릿·versions 파일)에는 어디에도 반영되지 않음.
- 따라서 `sysnet4admin/prepare:v2.15.0-arm64`가 생성하는 compose는 `goharbor/<component>:v2.15.0-arm64` — 태그만 arm64이고 네임스페이스는 upstream 그대로. goharbor는 arm64 태그를 발행하지 않으므로 (이 작업의 출발점) pull 불가.
- 이중 태그 버그(`v2.15.0-arm64-arm64`)가 관측된 것 자체가 태그는 이미 `-arm64`로 생성됨을 증명 → **태그 sed 제거는 옳았음**. 잘못은 네임스페이스 sed까지 함께 제거한 것.

### 왜 당시 테스트(#2 arm64 startup)는 통과했나

테스트 머신이 곧 이미지 빌드 머신이었기 때문. `make build` 과정에서 로컬에 `goharbor/*:v2.15.0-arm64` 이름의 이미지가 남아 있어(빌드 기본 네임스페이스가 goharbor) pull 없이 로컬 캐시로 기동됨. **리포만 클론한 깨끗한 환경에서는 재현 불가** — 이번에 실기 검증 중 발견된 경위.

### 적용한 수정 — `2-1.get_harbor.sh` arm64 분기 (2026-07-12 적용 완료)

**네임스페이스 sed 한 줄만** `2-3.prepare` 끝에 재주입. **태그 sed(`s,:v2.15.0,:v2.15.0-arm64,`)는 절대 다시 넣지 말 것** (이중 태그 버그 재발).

```bash
# 수정 전 (깨진 상태)
if [ "$(uname -m)" == "aarch64" ]; then
  echo "arm64 detected — switching to sysnet4admin/prepare:${HARBOR_VERSION}-arm64"
  sed -i "s,goharbor/prepare:${HARBOR_VERSION},sysnet4admin/prepare:${HARBOR_VERSION}-arm64,gi" 2-3.prepare
fi

# 수정 후 (올바른 최종 형태 — 현재 적용된 상태)
if [ "$(uname -m)" == "aarch64" ]; then
  echo "arm64 detected — switching to sysnet4admin/prepare:${HARBOR_VERSION}-arm64"
  sed -i "s,goharbor/prepare:${HARBOR_VERSION},sysnet4admin/prepare:${HARBOR_VERSION}-arm64,gi" 2-3.prepare
  echo '
sed -i "s,goharbor/,sysnet4admin/,gi" /opt/harbor/docker-compose.yml' >> 2-3.prepare
fi
```

- 첫 sed: prepare 컨테이너 자체를 arm64 이미지로 교체 (기존 그대로).
- append되는 sed: prepare가 docker-compose.yml을 생성한 **직후** 네임스페이스만 `goharbor/` → `sysnet4admin/`으로 치환. 태그는 prepare가 이미 `-arm64`로 생성하므로 건드리지 않음.
- `uninstall_harbor.sh`의 arm64 분기(`NS=sysnet4admin`, `TAG=${TAG}-arm64`)는 이미 올바름 — 수정 불요.

### 검증 절차 (2026-07-12 클린 환경에서 전체 통과 ✅)

1. ✅ **반드시 이미지 캐시 없는 환경**에서 검증: 기존 테스트 VM이라면 `docker rmi`로 `goharbor/*:v2.15.0-arm64`, `sysnet4admin/*` 전부 제거 후 진행 (로컬 캐시가 이 버그를 가렸던 전례).
2. ✅ `2-1` → `2-2` → `2-3.prepare` 실행 후 `grep image: /opt/harbor/docker-compose.yml` — 전부 `sysnet4admin/*:v2.15.0-arm64` 확인.
3. ✅ `2-4.install.sh` → 컨테이너 전체 healthy + `docker push` 테스트 통과.

향후 arm64 관련 재작업 시에도 위 1번(캐시 제거)을 건너뛰지 말 것 — 캐시가 있으면 이 계열 버그는 PASS로 위장됨.

---

## 테스트 결과

**환경**: ch3/3.1.3 클러스터 (arm64, VirtualBox on Apple Silicon, Docker 29.3.1)

> **2026-07-12**: 당초 arm64 테스트(#2~#3)는 빌드 머신의 로컬 이미지 캐시 덕에 통과한 것으로 판명되어 무효화 → 네임스페이스 sed 적용 후 **이미지 캐시 없는 클린 arm64 환경에서 재검증 통과** ("arm64 네임스페이스 치환 재주입" 섹션 참고).

| # | 항목 | 결과 |
|---|---|---|
| 1 | arm64 이미지 빌드 (11개) | ✅ `sysnet4admin/...:v2.15.0-arm64` DockerHub 푸시 완료 |
| 2 | Harbor startup (`docker compose up`) | ✅ 클린 환경 재검증 통과 (2026-07-12, 네임스페이스 sed 적용 후) |
| 3 | `docker push` → Harbor | ✅ 클린 환경 재검증 통과 (2026-07-12) |
| 4 | arm64 Harbor uninstall | ✅ 전체 정리 완료 |
| 5 | x86_64 Harbor startup | ✅ 9개 컨테이너 모두 healthy, fd 제한 문제 없음 |
| 6 | x86_64 `docker push` → Harbor | ✅ nginx:latest 푸시 성공 |

### v2.10.0 클린 arm64 환경 검증 (2026-08-08)

**환경**: ch3/3.1.3 클러스터 (aarch64, VirtualBox on Apple Silicon, k8s v1.36.0, Docker 26.0.0).
Harbor 미설치 상태(`/opt/harbor` 없음, `docker ps -a` 0개)에서 시작.

| # | 항목 | 결과 |
|---|---|---|
| 1 | `sysnet4admin/*:v2.10.0-arm64` 태그 11개 Docker Hub 존재 확인 | ✅ 전부 200 |
| 2 | `1-1.create_certs.sh` → `1-2.deploy_certs.sh` | ✅ 워커 3대 ca.crt 배포·containerd 재시작 |
| 3 | `2-1.get_harbor.sh` (arm64 분기 → prepare 이미지 치환) | ✅ |
| 4 | `2-3.prepare` 생성 compose 이미지명 | ✅ 9개 전부 `sysnet4admin/*:v2.10.0-arm64` |
| 5 | `2-4.install.sh` (캐시 없는 상태에서 전체 pull) | ✅ 9개 컨테이너 healthy |
| 6 | `docker login 192.168.1.10:8443 -u admin -p admin` | ✅ Login Succeeded |
| 7 | `docker push` → `library/dashboard:blue`, `:green` | ✅ 태그 2개 등록 |
| 8 | 워커 노드에서 `imagePullPolicy: Always` pull | ✅ w1/w2/w3 전부 성공 |

ch5/5.4.3 블루그린 실습(대시보드 이미지 빌드·푸시·배포) 검증도 이 환경에서 함께 수행함 —
`_prepublish_updates/`에 별도 기록 없음, ch5 검증 결과는 아래 "ch5/5.4.3 연계 검증" 절 참고.

### ch5/5.4.3 연계 검증 (2026-08-08)

편집자 리뷰 중 "5.4.3 2차 배포(green)에서 젠킨스 빌드 실패" 보고에 따른 재현 시도.

| # | 항목 | 결과 |
|---|---|---|
| 1 | `docker build --build-arg=PHASE=blue` | ✅ 85초 (원고 390초) |
| 2 | `docker build --build-arg=PHASE=green` | ✅ 25초 (원고 186초) |
| 3 | 두 이미지 digest 상이 | ✅ `7eb939…` / `06a31d…` — 캐시 재사용으로 동일 이미지가 되는 문제 없음 |
| 4 | `/v2/library/dashboard/tags/list` | ✅ `["blue","green"]` |
| 5 | pl-blue / pl-green 각 replicas 3 배포 | ✅ 6개 파드 전부 Running |
| 6 | 렌더링 색상 구분 | ✅ blue 파드 `text-blue-700`, green 파드 `text-green-700` |

**결론**: 이미지 빌드·푸시·pull 경로에 구조적 결함 없음. 편집자 환경 고유 문제였다.
**2026-08-08 편집자 재실습 정상 회신으로 종결됨.**

**참고 — `/v2/` API 인증**: `library` 프로젝트는 Harbor 기본값대로 public(`"public": true`)이라
`/v2/library/dashboard/tags/list` 읽기는 익명 허용. `Authorization` 헤더가 있기만 하면 자격 증명
내용과 무관하게 200이 나오고(`-u admin:admin`, `-u admin:Harbor12345`, `-u nobody:wrongpw` 모두 동일),
헤더가 아예 없을 때만 401. 따라서 태그 확인 명령의 암호는 무엇이든 상관없음. 단 `docker login`과
`docker push`는 실제 인증이 필요하므로 `admin`/`admin`이어야 함.

**부수 발견**: 재현 과정에서 `k8s-edu/Bkv2_sub_blue-green`의 Jenkinsfile 문제 2건(32번 줄 옛 저장소
이름, 83번 줄 빈 값 정수 비교)을 확인함. 이유·수정 내용·원고 반영 위치는
[bluegreen-pipeline.md](bluegreen-pipeline.md) 참고.

---

## ✅ harbor-exporter 배포 여부 — 확인 완료 (현재 구성 유지)

### 조사 결과

`harbor-exporter` 컨테이너는 v2.10.0, v2.15.0 모두 docker-compose.yml 템플릿에서 **`metric.enabled` 조건으로 감싸져** 있음.

```jinja
{% if metric.enabled %}
  exporter:
    image: goharbor/harbor-exporter:{{version}}
{% endif %}
```

→ `harbor.yml`에서 metrics를 활성화하지 않으면 exporter 컨테이너는 배포되지 않음.  
→ 책의 `2-2.modify_config.sh`는 metrics를 활성화하지 않으므로 **기존 v2.10.0에서도, v2.15.0에서도 exporter는 배포되지 않았음.**  
→ `uninstall_harbor.sh`에서 `harbor-exporter` 제거 시 `|| true` 처리가 올바름.

### 원고 확인 결과 (2026-08-08) — 현재 구성 유지가 맞음

- **ch4 원고**: `exporter` / `metric` 언급 **0건** (`nginx-prometheus-exporter`가 `docker search`
  결과 목록에 한 줄 나오는 것이 유일한 히트로, Harbor와 무관)
- **ch6 원고**(모니터링 장): 하버 언급은 6.6.x 실습의 이미지 빌드·푸시·pull 용도 2건뿐
  (문단 2357·2397). Harbor metrics를 프로메테우스 스크레이프 대상으로 삼는 내용 없음
- → **`2-2.modify_config.sh`에 `metric.enabled: true` 추가 불필요.** exporter 미포함 현재 구성 유지
- → `uninstall_harbor.sh`의 `harbor-exporter` 제거 시 `|| true` 처리도 그대로 유지
