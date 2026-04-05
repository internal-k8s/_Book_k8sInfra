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

### HIGH RISK — 테스트 결과 반영

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

**`workaround` 결정 보류**: `docker push` → Harbor 테스트 결과에 따라 `daemon.json`의 `containerd-snapshotter: false` 적용 여부 결정.

참고 이슈: [moby#51532](https://github.com/moby/moby/issues/51532), [moby#51665](https://github.com/moby/moby/issues/51665), [moby#49473](https://github.com/moby/moby/issues/49473)

#### 2. 파일 디스크립터 제한 변경 (Docker 29 + containerd 2.x)

컨테이너 기본 ulimit `nofile`: 1,048,576 → 1,024 (systemd 기본값으로 변경).
Harbor 컴포넌트(DB, Redis, core)가 영향받을 가능성 있음. **단일 사용자 실습 환경에서는 사실상 영향 없을 것으로 판단** — Harbor startup 테스트로 확인.

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
| `ch4/4.2.1/install_docker.sh` | 버전 문자열 noble 형식으로 변경 ✅ + Harbor push 테스트 결과에 따라 `daemon.json` 추가 여부 결정 |
| `ch4/4.4.1/copy_docker_2_containerd.sh` | `ctr image import --base-name multistage-img` → `--base-name` 제거 ✅ |

> `ch5/5.3.4/install_docker_on_all_nodes.sh`는 `install_docker.sh` scp 방식이므로 자동 반영.

---

## 테스트 결과

**환경**: ch3/3.1.3 (4-node cluster, Ubuntu 24.04 Noble, Docker 29.3.1, containerd image store 기본값 활성화)

| # | 항목 | 결과 |
|---|---|---|
| 1 | Dockerfile 빌드 (멀티스테이지, ch4/4.3.4) | ✅ |
| 2 | `docker save` → `docker load` (`copy_docker_2_docker.sh`) | ✅ |
| 3 | `docker save` → `ctr import` (`copy_docker_2_containerd.sh`, `--base-name` 제거 후) | ✅ |
| 4 | `docker push` → Harbor v2.10 | 테스트 예정 |
| 5 | Harbor startup (`docker compose up`) | 테스트 예정 |
| 6 | `docker image ls` 출력 | ✅ 영향 없음 |
