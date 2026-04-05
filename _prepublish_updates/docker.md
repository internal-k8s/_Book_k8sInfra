# Docker 24.0.6 → 29.3.1 ⏳

## 변경 이유

### 1. Ubuntu 24.04 전환에 따른 필수 업데이트

Ubuntu 24.04(Noble)로 box가 전환되면서 APT 패키지 버전 문자열 형식이 변경됨:

```bash
# Ubuntu 22.04 Jammy
docker_V='5:24.0.6-1~ubuntu.22.04~jammy'

# Ubuntu 24.04 Noble
docker_V='5:29.3.1-1~ubuntu.24.04~noble'
```

### 2. 책 용도에서의 영향 범위

Docker는 책에서 컨테이너 런타임(k8s)이 아닌 **이미지 빌드/푸시 전용**으로만 사용:
- `docker build` — Dockerfile 빌드
- `docker push` — Harbor 레지스트리에 푸시
- ch4 Dockerfile 예제 실습

---

## 버전별 주요 변경 (24 → 29)

| 버전 | 주요 변경 | 책 영향 |
|---|---|---|
| 25.0 | classic/legacy builder 공식 deprecated (Linux), BuildKit 이미 기본값 | 없음 (BuildKit 이미 사용) |
| 26.0 | API v1.24 미만 제거, deprecated image format 기본 비활성화 | 없음 |
| 27.0 | GraphDriver plugin deprecated, 네트워킹 변경 | 없음 |
| 28.0 | iptables SCTP 규칙 제거 | 없음 |
| **29.0** | **containerd image store가 신규 설치 기본값으로 변경** | ⚠️ 테스트 필요 |

### ⚠️ containerd image store 기본값 변경 (29.0)

Docker 29부터 신규 설치 시 containerd image store가 기본값. `docker push` 시 OCI manifest list 형태로 전송 → 일부 레지스트리가 거부할 수 있음.

**Harbor push 테스트 필수.**

문제 발생 시 workaround:
```json
// /etc/docker/daemon.json
{
  "features": { "containerd-snapshotter": false }
}
```

### Dockerfile 호환성

책의 모든 Dockerfile(`FROM`, `COPY`, `RUN`, `WORKDIR`, `ENTRYPOINT`, `LABEL`, `EXPOSE`, multi-stage `AS`)은 v29에서 **변경 없이 동작**. 수정 불필요.

---

## 변경 파일

| 파일 | 변경 내용 |
|---|---|
| `ch4/4.2.1/install_docker.sh` | `docker_V`, `buildx_V`, `compose_V` 버전 문자열 → noble 형식으로 변경 |

> `ch5/5.3.4/install_docker_on_all_nodes.sh`는 `install_docker.sh`를 scp로 전달하는 방식이므로 자동 반영.

### 버전 문자열 확인 필요

`buildx_V`, `compose_V`는 실제 APT 저장소에서 확인 후 결정:

```bash
apt list --all-versions docker-buildx-plugin 2>/dev/null
apt list --all-versions docker-compose-plugin 2>/dev/null
```

---

## 테스트 결과

-
