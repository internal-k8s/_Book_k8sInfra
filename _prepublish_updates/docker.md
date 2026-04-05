# Docker 24.0.6 → 29.3.1 ⏳

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

### HIGH RISK — 테스트 후 결정

#### 1. containerd image store 기본값 변경 (Docker 29, 신규 설치)

Docker 29부터 신규 설치 시 containerd image store가 기본값. 이에 따라 동작이 달라지는 부분:

| 명령 | 변화 | 예상 동작 |
|---|---|---|
| `docker push` → Harbor | OCI manifest list 형태로 전송 | Harbor v2.10은 OCI 지원하나 레지스트리 거부 사례 있음 (AWS ECR 등) → **테스트 필수** |
| `docker save` → `ctr import` | tar가 OCI layout 형식으로 변경 | `ctr`은 양쪽 모두 읽으나 `--base-name` 동작이 미묘하게 다를 수 있음 → **테스트 필요** |
| `docker save` → `docker load` | 동일 | `docker load`가 OCI layout tar 처리 가능 → 동작함 |
| `docker image ls` | untagged 이미지 기본 숨김 | BuildKit이 이미 기본값(Docker 23+)이므로 중간 스테이지가 Docker 24에서도 이미지로 저장되지 않음 → **영향 없음** |
| `docker build` | 변화 없음 | 동작함 |

**workaround (테스트 결과에 따라 적용 여부 결정)**:
```json
// /etc/docker/daemon.json
{
  "features": { "containerd-snapshotter": false }
}
```

참고 이슈: [moby#51532](https://github.com/moby/moby/issues/51532), [moby#51665](https://github.com/moby/moby/issues/51665), [moby#49473](https://github.com/moby/moby/issues/49473)

#### 2. 파일 디스크립터 제한 변경 (Docker 29 + containerd 2.x)

컨테이너 기본 ulimit `nofile`: 1,048,576 → 1,024 (systemd 기본값으로 변경)

Harbor 컴포넌트(DB, Redis, core)가 영향받을 가능성 있음.

**단, 단일 사용자 실습 환경에서는 사실상 영향 없을 것으로 판단** — 테스트로 확인.

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
# Ubuntu 22.04 Jammy (이전)
docker_V='5:24.0.6-1~ubuntu.22.04~jammy'
buildx_V='0.23.0-1~ubuntu.22.04~jammy'
compose_V='2.35.1-1~ubuntu.22.04~jammy'

# Ubuntu 24.04 Noble (변경 후) — APT 저장소 확인 완료 (2026-04-05)
docker_V='5:29.3.1-1~ubuntu.24.04~noble'
buildx_V='0.33.0-1~ubuntu.24.04~noble'
compose_V='5.1.1-1~ubuntu.24.04~noble'   # compose-plugin v5 GA (v2에서 versioning 변경, 하위호환)
```

---

## 변경 파일

| 파일 | 변경 내용 |
|---|---|
| `ch4/4.2.1/install_docker.sh` | 버전 문자열 noble 형식으로 변경 ✅ + HIGH RISK 테스트 결과에 따라 `daemon.json` 추가 여부 결정 |

> `ch5/5.3.4/install_docker_on_all_nodes.sh`는 `install_docker.sh` scp 방식이므로 자동 반영.

---

## 테스트 항목

| # | 항목 | 결과 |
|---|---|---|
| 1 | `docker push` → Harbor v2.10 정상 동작 | - |
| 2 | `docker save` → `ctr import` 체인 (`copy_docker_2_containerd.sh`) | - |
| 3 | `docker save` → `docker load` 체인 (`copy_docker_2_docker.sh`) | - |
| 4 | Dockerfile 빌드 (멀티스테이지 포함) | - |
| 5 | Harbor startup (`docker compose up`) | - |
| 6 | `docker image ls` 출력 — 책 설명과 일치 여부 | ✅ 영향 없음 (BuildKit 기본값으로 intermediate 이미지 미저장) |
