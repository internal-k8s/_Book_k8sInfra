# kubespray (app/B.kubespray)

## 변경 배경

1판(app/C.kubespray)과 동일한 kubespray 구성을 시도했으나 여러 환경 변화로 인해
추가 설정 없이는 배포가 실패합니다. 아래는 각 변경사항과 근본 원인입니다.

## 1판 → 2판 변경 요약

| 항목 | 1판 (C.kubespray) | 2판 (B.kubespray) | 근본 원인 |
|---|---|---|---|
| OS | CentOS (x86_64) | Ubuntu 24.04 (arm64) | 환경 전환 |
| kubespray | release-2.17 (k8s ~1.20) | release-2.31 (k8s v1.35.4) | 버전 업 |
| CP vCPU | 2 | 4 | arm64 에뮬레이션 오버헤드 |
| CP 메모리 | 2048MB | 2048MB | 동일 (kubeadm 1700MB 실제 필요) |
| Worker 메모리 | 1536MB | 1280MB | Ubuntu 24.04 메모리 인식량 차이 |
| /etc/hosts localhost | 없음 | 127.0.0.1/::1 명시 | Ubuntu 24.04 systemd-resolved 의존성 |
| auto_pass.sh 필터 | 없음 | loopback 항목 제외 | localhost 추가의 연쇄 수정 |
| kubeadm 내부 타임아웃 | 4분(기본값) | 15분 | arm64 에뮬레이션 + k8s 1.35 기동 지연 |
| kubespray shell 타임아웃 | 300s(기본값) | 960s | 내부 타임아웃과 정합 필요 |
| download_run_once | 없음 | true | Docker Hub rate limit 대응 |
| CRI | Docker (dockershim) | containerd | k8s 1.24+ dockershim 제거 |

## 변경사항별 원인 상세

### 1. `/etc/hosts`에 localhost 추가 (config.sh)

**원인**: Ubuntu 24.04의 `systemd-resolved` + `nsswitch.conf`는 DNS 해석 시
`/etc/hosts`를 먼저 참조합니다. config.sh가 `/etc/hosts`를 빈 파일로 덮어쓰면
`localhost` 항목이 사라지고, kube-apiserver가 내부 통신에서 `localhost`를
외부 DNS(168.126.63.1)로 조회하다 실패합니다.

**검증**: `controlPlaneComponentHealthCheck: 12m`으로 연장해도 localhost 없으면
12분을 전부 소진 후 실패. localhost 있으면 8분 이내 통과.

**1판이 괜찮았던 이유**: CentOS는 `/etc/hosts`가 비어있어도 loopback 주소를
커널 레벨에서 처리하거나, 당시 kubespray(k8s 1.20)에서 kube-apiserver가
localhost를 내부 통신에 덜 사용했습니다.

### 2. auto_pass.sh loopback 필터 추가

**원인**: config.sh에 localhost를 추가한 결과 `/etc/hosts`에 loopback 항목이
생기면서 auto_pass.sh의 `readarray hosts < /etc/hosts`가 `127.0.0.1`,
`::1`, `localhost`를 SSH 대상으로 처리 → 자기 자신에 SSH 연결 시도.

config.sh 수정의 연쇄 수정입니다.

### 3. kubeadm 타임아웃 15분 (pre-kubespray.sh)

**원인 1 — arm64 에뮬레이션**: Apple Silicon에서 VirtualBox는 x86_64를
소프트웨어 에뮬레이션으로 실행. CPU 처리 속도가 실질적으로 절반 이하.

**원인 2 — k8s 1.35**: kubespray release-2.17 시대(k8s 1.20)에 비해 etcd 3.5.x
초기화 + admission webhook 준비까지 kube-apiserver 기동 시간이 크게 증가.

**검증 결과**:
- kube-scheduler, kube-controller-manager: 항상 ~2m14s에 healthy ✅
- kube-apiserver: localhost 있을 때 8분 내 통과, 없으면 12분도 실패

**shell 타임아웃(960s) 동시 설정 이유**: kubespray Ansible의 shell wrapper
`timeout -k 300s 300s kubeadm init`이 5분에 프로세스를 강제 종료하므로
내부 타임아웃(15분)과 반드시 맞춰야 합니다. 960s(16분)으로 여유를 줌.

**15분으로 설정한 이유**: 이 책의 테스트 환경(Apple Silicon M-series)에서
8분 내 통과하지만, 독자 환경(Windows + Intel i5/i7 + VirtualBox)은 2-3배
느릴 수 있습니다. 넉넉한 여유값으로 설정. 일찍 통과되면 대기 없이 다음 단계로
진행되므로 손해 없음.

### 4. download_run_once: true (pre-kubespray.sh → group_vars)

**원인**: Docker Hub는 2020년 11월부터 익명 pull에 rate limit 도입
(6시간 100회), 이후 강화. kubespray release-2.31 기준 k8s 1.35 설치에
필요한 컨테이너 이미지 수가 많고, VM 9대가 각자 pull하면 동일 호스트 IP에서
rate limit 초과 발생 → `nginx:1.28.2-alpine` 등에서 size validation 실패.

**1판이 괜찮았던 이유**: kubespray release-2.17(k8s 1.20) 시대에는
rate limit 정책이 없었거나, 필요 이미지 수가 적었습니다.

### 5. CP vCPU 4개, Worker 1280MB

**CP vCPU**: arm64 에뮬레이션에서 2 vCPU로는 kubeadm preflight 메모리 체크
(ansible_memtotal_mb ≥ 1500)는 통과하지만 kube-apiserver 기동 시 CPU 부하가
크게 증가. 4 vCPU로도 여전히 느리지만 타임아웃 연장으로 커버 가능.

**Worker 메모리**: kubespray가 요구하는 최소 1024MB(ansible_memtotal_mb 기준).
1152MB 할당 시 Ubuntu 24.04에서 실제 인식은 ~947MB로 부족. 1280MB 할당 시
~1070MB 인식으로 통과.

## 테스트 결과

| 환경 | PLAY RECAP | 결과 |
|---|---|---|
| localhost없음 + 8m timeout | cp11 failed=1 (rc=124, shell timeout) | ❌ |
| localhost없음 + 12m timeout | cp11 failed=1 (apiserver 12분 내 unhealthy) | ❌ |
| localhost있음 + 8m timeout | cp11 failed=0, 9노드 Ready | ✅ |
| localhost있음 + 12m timeout | cp11 failed=0, 9노드 Ready | ✅ |
| localhost있음 + 15m timeout (최종) | cp11 failed=0, 9노드 Ready | ✅ |

## 수정된 파일

| 파일 | 변경 내용 |
|---|---|
| `app/B.kubespray/Vagrantfile` | CP 4vCPU/2048MB, Worker 1280MB |
| `app/B.kubespray/config.sh` | /etc/hosts에 127.0.0.1 localhost 추가 |
| `app/B.kubespray/auto_pass.sh` | loopback 항목 SSH 대상 제외 |
| `app/B.kubespray/pre-kubespray.sh` | kubeadm timeout 15m, shell timeout 960s, download_run_once: true |
