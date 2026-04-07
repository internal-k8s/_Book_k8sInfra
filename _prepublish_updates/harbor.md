# Harbor v2.10.0 → v2.15.0 ✅

> **업데이트 결정 근거**: Harbor v2.10.0은 EOL 수준의 구버전. v2.15.0이 현재 안정 최신. v2.16은 2026년 9월 예정으로 대기 불가. v2.15.1은 mid-May 2026 예정이나 v2.15.0 오픈 이슈가 책 사용 범위에 영향 없어 v2.15.0으로 결정.

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

```bash
if [ "$(uname -m)" == "aarch64" ]; then
  sed -i "s,goharbor/prepare:${HARBOR_VERSION},sysnet4admin/prepare:${HARBOR_VERSION}-arm64,gi" 2-3.prepare
  echo '
sed -i "s,goharbor/,sysnet4admin/,gi" /opt/harbor/docker-compose.yml
sed -i "s,:v2.15.0,:v2.15.0-arm64,gi" /opt/harbor/docker-compose.yml
' >> 2-3.prepare
fi
```

**arm64 이미지 빌드 상태**: ⏳ 미완료 (build.sh 작성 완료, DockerHub 푸시 필요)

---

## v2.10.0 → v2.15.0 주요 변경

### UI/UX 변경 — docx 수정 필요

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

| 파일 | 변경 내용 | 상태 |
|---|---|---|
| `ch4/4.4.2/2.harbor/2-1.get_harbor.sh` | v2.10.0 → v2.15.0, arm64 arch 감지 추가 | ✅ |
| `ch4/4.4.2/_image-builder/build.sh` | arm64 이미지 빌드 스크립트 (저자 전용) | ✅ (gitignore) |
| `ch4/4.4.2/2.harbor/uninstall_harbor.sh` | TAG v2.10.0 → v2.15.0 업데이트 | ✅ |
| docx (ch4/4.4.3 또는 Harbor 사용 설명) | "Copy docker pull" 위치 변경 스크린샷 | ⏳ 공저자 작업 필요 |

---

## 버그 수정 — docker-compose.yml 이중 치환

### 현상

arm64 prepare 이미지(`sysnet4admin/prepare:v2.15.0-arm64`)가 이미 `IMAGENAMESPACE=sysnet4admin`, `VERSIONTAG=v2.15.0-arm64`로 빌드되어 있어, docker-compose.yml을 생성할 때 이미 올바른 이미지명(`sysnet4admin/harbor-core:v2.15.0-arm64`)을 사용함.

그런데 `2-1.get_harbor.sh`의 arm64 블록이 `2-3.prepare`에 아래 sed를 추가로 주입:
```bash
sed -i "s,:v2.15.0,:v2.15.0-arm64,gi" /opt/harbor/docker-compose.yml
```
→ `v2.15.0-arm64` 내의 `:v2.15.0`도 치환하여 `v2.15.0-arm64-arm64` 이중 태그 생성.

### 수정

docker-compose.yml sed 주입 라인 전체 제거 (arm64 prepare가 이미 올바른 이미지명 생성).
`prepare` 이미지명만 치환하면 충분.

---

## 테스트 결과

**환경**: ch3/3.1.3 클러스터 (arm64, VirtualBox on Apple Silicon, Docker 29.3.1)

| # | 항목 | 결과 |
|---|---|---|
| 1 | arm64 이미지 빌드 (11개) | ✅ `sysnet4admin/...:v2.15.0-arm64` DockerHub 푸시 완료 |
| 2 | Harbor startup (`docker compose up`) | ✅ 9개 컨테이너 모두 healthy |
| 3 | `docker push` → Harbor | ✅ nginx:latest 푸시 성공 |
| 4 | arm64 Harbor uninstall | ✅ 전체 정리 완료 |
| 5 | x86_64 Harbor startup | ✅ 9개 컨테이너 모두 healthy, fd 제한 문제 없음 |
| 6 | x86_64 `docker push` → Harbor | ✅ nginx:latest 푸시 성공 |

---

## ⚠️ harbor-exporter 배포 여부 — 공저자 확인 필요

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

### 공저자 확인 필요

- 책 실습에서 Harbor metrics(exporter)를 사용하는 내용이 있는지 확인
- 있다면 `2-2.modify_config.sh`에 `metric.enabled: true` 설정 추가 필요
- 없다면 현재 구성(exporter 미포함) 유지
