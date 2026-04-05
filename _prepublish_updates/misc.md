# 기타 변경 사항

컴포넌트 버전 업데이트가 아닌 **저장소 구조 정리 / 파일 교정 / 스크립트 수정** 류의 변경을 기록합니다.

---

## FROM_3.4.3/ 디렉토리 → 심볼릭 링크 전환

### 변경 내용

| 파일 | 변경 전 | 변경 후 |
|---|---|---|
| `ch5/5.2.2/FROM_3.4.3/` | 일반 디렉토리 (ch3/3.4.3 복사본) | `../../ch3/3.4.3` 심볼릭 링크 |
| `ch5/5.2.3/FROM_3.4.3/` | 일반 디렉토리 (ch3/3.4.3 복사본) | `../../ch3/3.4.3` 심볼릭 링크 |

### 이유

`FROM_3.4.3/`의 목적은 "ch3/3.4.3과 항상 동일"이므로 단일 소스를 바라보는 심볼릭 링크가 적합.
복사본 구조에서는 ch3/3.4.3 변경 시 ch5/5.2.2, ch5/5.2.3 두 곳을 수동으로 동기화해야 해서 누락 위험이 있었음.

### 동작 조건

- Vagrantfile에서 `synced_folder` disabled → VM은 Linux에서 git clone으로 저장소 수신
- Linux git은 심볼릭 링크를 그대로 생성하므로 정상 동작

### docx 영향

직접적인 내용 변경 없음. 동작 방식만 변경.

---

## ⚠️ Harbor v2.10.0 arm64 미지원 — 공저자 확인 필요

### 현상

ch4/4.4.2 Harbor 설치 시 arm64 환경에서 다음 오류 발생:

```
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8)
exec /usr/bin/python3: exec format error
```

### 원인

- Harbor v2.10.0의 모든 컴포넌트 이미지(`prepare`, `harbor-core`, `harbor-db` 등)가 **linux/amd64 단일 아키텍처**만 지원
- Docker Hub 확인 결과 arm64 이미지 없음
- `ch4/4.4.2/2.harbor/2-1.get_harbor.sh`에 arch 감지 로직 없음
- QEMU 에뮬레이션도 동작하지 않음 (`exec format error`)

### 공식 arm64 지원 시점

- Harbor GitHub PR #22311 (Full Multi-Architecture Enablement) — v2.16 예정 기능으로 밀림 (2026년 기준 미병합)
- v2.10.x ~ v2.15.x 전 버전 amd64 전용

### 영향

- 책이 arm64 환경(Apple Silicon Mac + VirtualBox)도 지원하도록 설계된 경우 ch4/4.4.2 Harbor 챕터는 동작하지 않음
- x86_64 환경에서는 정상 동작

### 공저자 논의 필요

- arm64 독자에 대한 Harbor 챕터 대응 방안 결정 필요
- 선택지: ① arm64 미지원 명시 (책에 note 추가) ② arm64 이미지 직접 빌드 후 배포 (아래 참고)

### arm64 이미지 직접 빌드 가능성 — 복잡도: MEDIUM

**참고**: `_Lecture_prom_learning.kit`의 `harbor_config.sh`에서 동일 패턴 사용 중:
```bash
if [ "$(uname -m)" == "aarch64" ]; then
  sed -i 's,goharbor/prepare:v2.4.3,seongjumoon/prepare:v2.4.3-arm64,gi' prepare
  # docker-compose.yml도 동일하게 치환
fi
```
→ `seongjumoon` 계정에 v2.4.3-arm64 이미지 존재. v2.10.0은 없음.

**v2.10.0 arm64 빌드 방법**

Harbor v2.10.0 Makefile에는 buildx/multi-arch 지원 없음. 소스 수정 최소화로 arm64 빌드 가능:

1. **패치 1곳 (1줄)** — `make/photon/exporter/Dockerfile`
   ```dockerfile
   ENV GOARCH=amd64  # ← 이 줄 제거 (arm64에서도 amd64 바이너리 생성하는 원인)
   ```

2. **빌드 커맨드** (arm64 호스트에서 실행)
   ```bash
   make build \
     -e DEVFLAG=false \
     -e VERSIONTAG=v2.10.0 \
     -e BASEIMAGETAG=v2.10.0 \
     -e IMAGENAMESPACE=sysnet4admin \
     -e BASEIMAGENAMESPACE=sysnet4admin \
     -e BUILD_BASE=true \
     -e PULL_BASE_FROM_DOCKERHUB=false \
     -e BUILDBIN=true \
     -e TRIVYFLAG=false
   ```
   - `BUILDBIN=true`: registry 바이너리를 amd64 prebuilt 다운로드 대신 소스 컴파일
   - `PULL_BASE_FROM_DOCKERHUB=false`: 로컬 빌드한 base 이미지 사용

3. **베이스 이미지 arm64 지원 여부 확인**

   | 베이스 이미지 | arm64 지원 |
   |---|---|
   | `photon:5.0` | ✅ |
   | `golang:1.21.4` | ✅ |
   | `node:16.18.0` | ✅ |

4. **결과물 푸시**: `sysnet4admin/harbor-core:v2.10.0`, `sysnet4admin/prepare:v2.10.0` 등 DockerHub 푸시

5. **`2-1.get_harbor.sh`에 arch 분기 추가** (prom 패턴 적용)
   ```bash
   if [ "$(uname -m)" == "aarch64" ]; then
     sed -i 's,goharbor/prepare:v2.10.0,sysnet4admin/prepare:v2.10.0,gi' 2-3.prepare
     echo '
   sed -i "s,goharbor/,sysnet4admin/,gi" /opt/harbor/docker-compose.yml
   sed -i "s,:v2.10.0-dev-arm,:v2.10.0,gi" /opt/harbor/docker-compose.yml
   ' >> 2-3.prepare
   fi
   ```

**참고**: IabSDocker 커뮤니티가 v2.11+에서 동일 방식으로 arm64 빌드 성공 확인. v2.10.0 전례 없으나 blocker가 exporter 1줄뿐이므로 실현 가능성 높음.

---

## 구 yaml 파일 삭제

| 삭제 파일 | 이유 |
|---|---|
| `ch5/5.2.2/FROM_3.4.3/nfs-subdir-external-provisioner-v4.0.0.yaml` | csi-driver-nfs 전환으로 더 이상 사용하지 않음 |

(ch5/5.2.3/FROM_3.4.3/에는 이미 존재하지 않았음)

### docx 영향

직접적인 내용 변경 없음. 불필요 파일 정리.
