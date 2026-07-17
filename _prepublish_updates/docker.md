# Docker 24.0.6 → 29.3.1 (테스트 완료) → 26.0.0 (최종 결정, 2026-07-17) ⚠️

> **최종 결정(2026-07-17)**: 29.3.1 테스트까지 전부 완료했으나, ch4~ch6 버전 변경 최소화 정책
> (`_prepublish_updates/misc.md` "정책: ch4~ch6은 버전 변경 최소화" 참고)에 따라 **26.0.0으로 재조정**.
>
> - 원래 목표였던 24.0.6은 Ubuntu 24.04(noble) 저장소에 아예 빌드된 적이 없어 설치 불가능
>   (noble 저장소는 26.0.0부터 시작 — 책이 이미 22.04→24.04로 전체 전환 완료되어 이 하드 블로커는 피할 수 없음)
> - "가장 적게 벗어나는 선택" 기준으로 noble에서 설치 가능한 가장 이른 버전인 26.0.0으로 결정
> - 26.0.0은 29.x의 두 가지 문제(containerd-snapshotter 기본값 전환, `docker images` UI 개편)를
>   구조적으로 피함 — 둘 다 29.0.0에서 새로 도입된 변경이라 26.x엔 없음 (아래 "26.0.0 사전 조사" 참고)
> - buildx `0.13.1`, compose `2.25.0`은 Docker 26.0.0(2024-03-20) 출시 1주일 이내 버전으로 짝을 맞춤
> - 아래 29.3.1 관련 분석·테스트 결과는 **모두 히스토리로 보존** — 다시 최신화를 검토할 때 재사용 가능

## 26.0.0 사전 조사 (2026-07-17)

- 공식 릴리스 노트: containerd image store 관련 변경 전부 **수동으로 `containerd-snapshotter` 기능을
  켰을 때만** 적용되는 옵션 기능 변경 — 26.0.0 기본값은 24.x와 동일한 classic 방식이라 해당 없음
- "25.0.0에서 만든 컨테이너는 MAC 주소 중복 가능" — 25→26 업그레이드 시 기존 컨테이너 재사용 케이스만
  해당. 책은 항상 새 VM에 처음 설치하므로 무관
- [moby#47674](https://github.com/moby/moby/issues/47674) "docker image ls does not show images
  loaded from a tar file" — `docker save`→`docker load`(`ch4/4.4.1`)와 겹치는 시나리오라 확인했으나,
  재현 조건이 `daemon.json`에 `containerd-snapshotter`를 수동으로 켠 경우로 한정됨. 우리는 이 옵션을
  켤 이유가 없어 해당 없음
- Harbor push 관련 26.x 특이 이슈 없음

## (히스토리) Docker 24.0.6 → 29.3.1 결정 근거

> **업데이트 결정 근거**: Docker 24.x 보안 패치 중단, 29.x가 최신 안정 버전. 책에서 Docker는 컨테이너 런타임이 아닌 이미지 빌드/푸시 전용으로만 사용하므로 대부분의 변경이 영향 없음. HIGH RISK 2항목은 테스트 후 최종 결정.

## 책에서 Docker 사용 범위

| 용도 | 파일 |
|---|---|
| Docker 설치 | `ch4/4.2.1/install_docker.sh` |
| Dockerfile 빌드 | ch4/4.3.x, ch4/4.4.3, ch7/7.5.1 |
| `docker save` → `docker load` | `ch4/4.4.1/copy_docker_2_docker.sh` |
| `docker save` → `ctr import` | `ch4/4.4.1/copy_docker_2_containerd.sh` |
| `docker push` → Harbor | ch4/4.4.3 |
| Harbor 운영 (`docker compose`) | ch4/4.4.2 |
| 전체 노드 Docker 설치 | `ch5/5.3.4/install_docker_on_all_nodes.sh` (install_docker.sh 재사용) |

---

## 버전별 영향도 분석

### HIGH RISK — 테스트 결과 반영

> **최종 요약**
> - HIGH RISK 1: 우려했던 대부분은 정상 동작. 단, `ctr import --base-name` 무음 실패 → **코드 수정 완료**. Harbor push는 arm64 한계로 미확인.
> - HIGH RISK 2: 단일 사용자 실습 환경에서 영향 없을 것으로 판단. Harbor startup으로 최종 확인 필요하나 arm64 한계로 미수행.
> - 두 항목 모두 x86_64에서 Harbor 테스트 완료 후 최종 결론.

#### 1. containerd image store 기본값 변경 (Docker 29, 신규 설치) — ⚠️ 코드 수정 발생

Docker 29부터 신규 설치 시 containerd image store가 기본값 (`driver-type: io.containerd.snapshotter.v1`).
`docker save` 출력 형식이 **Docker archive → OCI Image Layout**으로 변경됨.

| 명령 | 변화 | 테스트 결과 |
|---|---|---|
| `docker build` | 변화 없음 | ✅ 정상 |
| `docker save` → `docker load` | OCI layout tar 생성 | ✅ `docker load`가 OCI tar 처리 가능 — 정상 |
| `docker save` → `ctr import --base-name` | OCI layout tar | ❌ **`--base-name` 플래그가 OCI tar에서 무음 실패** (exit 0이지만 이미지 미등록) |
| `docker save` → `ctr import` (base-name 제거) | OCI layout tar | ✅ `docker.io/library/multistage-img:latest`로 정상 import — k8s pod spec 호환 |
| `docker push` → Harbor | OCI manifest list 형태로 전송 | 테스트 예정 |
| `docker image ls` | untagged 이미지 기본 숨김 | ✅ 영향 없음 (BuildKit 기본값으로 intermediate 이미지 미저장) |

**`--base-name` 실패 원인**: Docker archive 형식에서는 `manifest.json`의 `RepoTags`를 `--base-name`으로 재지정하는 방식이었으나, OCI layout 형식에서는 `index.json`의 `annotations`에 이미 image name이 내장됨 → `--base-name` 오버라이드가 동작하지 않음.

**코드 변경 내용 (`copy_docker_2_containerd.sh` Step 3)**:
```bash
# 변경 전
ctr --namespace $KUBERNETES_NAMESPACE image import --base-name multistage-img $TEMP_DOCKER_FILE_PATH
#                                                  └── 플래그 ──┘ └── 플래그값 ──┘  └── tar 파일 경로

# 변경 후 — --base-name과 그 값(multistage-img)을 함께 제거, $TEMP_DOCKER_FILE_PATH는 원래부터 있던 인자
ctr --namespace $KUBERNETES_NAMESPACE image import $TEMP_DOCKER_FILE_PATH
```

OCI tar의 `index.json`에 `docker.io/library/multistage-img:latest`가 이미 기록되어 있어, `--base-name` 없이도 해당 이름으로 정상 import됨. k8s pod spec의 `image: multistage-img:latest`와 호환.

**`workaround` 불필요**: arm64/x86_64 모두 Harbor push ✅ 정상 동작 확인. `daemon.json`의 `containerd-snapshotter: false` 적용 불필요.

참고 이슈: [moby#51532](https://github.com/moby/moby/issues/51532), [moby#51665](https://github.com/moby/moby/issues/51665), [moby#49473](https://github.com/moby/moby/issues/49473)

#### 2. 파일 디스크립터 제한 변경 (Docker 29 + containerd 2.x)

컨테이너 기본 ulimit `nofile`: 1,048,576 → 1,024 (systemd 기본값으로 변경).
Harbor 컴포넌트(DB, Redis, core)가 영향받을 가능성 있음. **단일 사용자 실습 환경(이미지 1~2개 push 수준)에서는 fd 1,024개 제한이 문제가 되지 않을 것으로 판단** — Harbor startup 테스트로 최종 확인 필요하나 arm64 한계로 미수행.

**workaround (필요 시 적용)**:
```json
// /etc/docker/daemon.json
{
  "default-ulimits": {
    "nofile": { "Name": "nofile", "Soft": 1048576, "Hard": 1048576 }
  }
}
```

---

### 영향 없음 — 적용 불필요

| 변경 | 버전 | 근거 |
|---|---|---|
| classic builder deprecated | v25 | 이미 BuildKit이 기본값 (v23부터) |
| 최소 API 버전 1.24 → 1.44 | v29 | CLI만 사용, 외부 툴 없음 |
| manifest v2 schema 1 제거 | v28.2 | 책 base image 전부 현대 포맷 (zulu-openjdk, distroless, nginx, ollama) |
| `docker stop --time` → `--timeout` | v28 | 책에서 미사용 |
| Docker Content Trust CLI 제거 | v29 | 책에서 미사용 |
| `docker commit --pause` deprecated | v29 | 책에서 미사용 |
| `docker inspect` 일부 필드 제거 | v26 | 책에서 해당 필드 미사용 |
| Compose `version` 키 무시 | v2 spec | Harbor compose는 이미 동작 중 |

---

## 설치 방식

### APT 패키지명 — 변경 없음

`docker-ce`, `docker-ce-cli`, `docker-ce-rootless-extras`, `docker-buildx-plugin`, `docker-compose-plugin`, `containerd.io`

### 버전 문자열 형식 — Ubuntu에 따라 변경

```bash
# Ubuntu 22.04 Jammy (최초 원고 기준)
docker_V='5:24.0.6-1~ubuntu.22.04~jammy'
buildx_V='0.23.0-1~ubuntu.22.04~jammy'
compose_V='2.35.1-1~ubuntu.22.04~jammy'

# Ubuntu 24.04 Noble, Docker 29.3.1 (히스토리 — 테스트까지 완료했으나 최종 미채택)
docker_V='5:29.3.1-1~ubuntu.24.04~noble'
buildx_V='0.33.0-1~ubuntu.24.04~noble'
compose_V='5.1.1-1~ubuntu.24.04~noble'   # compose-plugin v5 GA (v2에서 versioning 변경, 하위호환)

# Ubuntu 24.04 Noble, Docker 26.0.0 (최종 결정, 2026-07-17) — noble 최초 빌드 버전
docker_V='5:26.0.0-1~ubuntu.24.04~noble'
buildx_V='0.13.1-1~ubuntu.24.04~noble'   # 26.0.0(2024-03-20) 출시 8일 전 버전
compose_V='2.25.0-1~ubuntu.24.04~noble'  # 26.0.0 출시 5일 전 버전
```

---

## 변경 파일 (최종, 26.0.0 기준)

| 파일 | 변경 내용 |
|---|---|
| `ch4/4.2.1/install_docker.sh` | 버전 문자열 26.0.0/noble 형식으로 변경 ✅ |
| `ch4/4.4.1/copy_docker_2_containerd.sh` | `ctr image import --base-name multistage-img` **복원** ✅ (26.0.0은 classic docker-archive 포맷이라 다시 필요) |

> `ch5/5.3.4/install_docker_on_all_nodes.sh`는 `install_docker.sh` scp 방식이므로 자동 반영.
> 26.0.0 자체의 실기 테스트는 아직 미수행 — 사전 조사(위 "26.0.0 사전 조사")만 완료.

---

## (히스토리) 29.3.1 테스트 결과

**환경**: ch3/3.1.3 (4-node cluster, Ubuntu 24.04 Noble, Docker 29.3.1, containerd image store 기본값 활성화)

| # | 항목 | 결과 |
|---|---|---|
| 1 | Dockerfile 빌드 (멀티스테이지, ch4/4.3.4) | ✅ |
| 2 | `docker save` → `docker load` (`copy_docker_2_docker.sh`) | ✅ |
| 3 | `docker save` → `ctr import` (`copy_docker_2_containerd.sh`, `--base-name` 제거 후) | ✅ |
| 4 | `docker push` → Harbor v2.15.0 (arm64) | ✅ nginx:latest 푸시 성공 |
| 5 | Harbor startup (`docker compose up`, arm64) | ✅ 9개 컨테이너 모두 healthy |
| 6 | `docker image ls` 출력 | ✅ 영향 없음 |
| 7 | `docker push` → Harbor (x86_64) | ✅ nginx:latest 푸시 성공, daemon.json workaround 불필요 |
| 8 | Harbor startup (x86_64) | ✅ 9개 컨테이너 모두 healthy, fd 제한 문제 없음 |
