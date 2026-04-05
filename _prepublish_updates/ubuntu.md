# Ubuntu 22.04 → 24.04 ✅

## 전환 이유

### 1. LTS 지원 기간

| 항목 | Ubuntu 22.04 (Jammy) | Ubuntu 24.04 (Noble) |
|---|---|---|
| 표준 지원 종료 | 2027년 4월 | 2029년 4월 |
| ESM 지원 종료 | 2032년 4월 | **2034년 4월 (10년)** |

책 출판 후 독자들이 장기간 사용하는 환경을 고려하면 24.04가 훨씬 안전한 기반.

### 2. 커널 6.8 — eBPF 고도화

22.04의 커널 5.15 → 24.04의 커널 **6.8**로 전환되면서 eBPF 생태계가 크게 강화됨.

#### eBPF 프로그램 타입 확장
- **BPF_PROG_TYPE_SOCKMAP** 안정화: 소켓 레벨 리다이렉션으로 동일 노드 Pod 간 통신 시 커널 내부에서 처리 (네트워크 스택 우회)
- **XDP (eXpress Data Path)** 성능 향상: NIC 드라이버 레벨에서 패킷 처리, kube-proxy 없이 L4 로드밸런싱 가능
- **TC (Traffic Control) BPF** 개선: ingress/egress 양방향 BPF 훅, Cilium의 네트워크 정책 구현 기반

#### BTF (BPF Type Format) & CO-RE
- **BTF** 완전 내장: 커널 빌드 시 타입 정보 포함 → BPF 프로그램이 커널 버전 무관하게 동작
- **CO-RE (Compile Once, Run Everywhere)**: 한 번 컴파일된 BPF 바이너리가 다양한 커널에서 실행 가능
- 5.15에서는 일부 BTF 기능 미지원으로 Cilium이 fallback 모드로 동작했으나, 6.8에서 완전 지원

#### Cilium에 미치는 영향
| 기능 | 커널 5.15 (22.04) | 커널 6.8 (24.04) |
|---|---|---|
| kube-proxy 완전 대체 | 제한적 | ✅ 완전 지원 |
| BPF NodePort | 지원 | ✅ 성능 향상 |
| BPF Host Routing | 일부 제한 | ✅ 완전 지원 |
| Hubble 관측 데이터 | 기본 | ✅ 상세 메타데이터 |
| Bandwidth Manager (EDT) | 불안정 | ✅ 안정 |

#### 관측 가능성 (Observability)
- `bpftool`로 실행 중인 BPF 프로그램 실시간 확인 가능
- BPF ring buffer (`BPF_MAP_TYPE_RINGBUF`) 안정화: perf event 대비 낮은 오버헤드로 이벤트 수집
- kprobe/tracepoint BPF 훅 범위 확대 → 컨테이너 시스템 콜 추적 정밀도 향상

### 3. cgroup v2 완전 지원

| 항목 | 22.04 (cgroup v1/v2 혼용) | 24.04 (cgroup v2 기본) |
|---|---|---|
| 메모리 QoS | 제한적 | ✅ PSI 기반 정밀 제어 |
| CPU 버스팅 제어 | 불완전 | ✅ `cpu.max` 정밀 조정 |
| containerd 권장 설정 | `SystemdCgroup=true` 별도 패치 | ✅ 기본 일치 |
| kubelet 리소스 관리 | 일부 제한 | ✅ 완전 지원 |

PSI (Pressure Stall Information): CPU/Memory/IO 압박 수준을 실시간 측정, HPA/VPA 스케일링 정확도 향상.

### 4. io_uring 안정화

- 비동기 I/O 인터페이스 성능 대폭 향상
- containerd의 이미지 레이어 추출, 컨테이너 스토리지 I/O에 직접적 영향
- 5.15 대비 컨테이너 이미지 pull 및 스토리지 집약적 워크로드에서 체감 가능한 성능 개선

### 5. 보안 강화

- **AppArmor 4.0** 기본 탑재: 컨테이너별 LSM 프로필 적용 개선
- **Landlock LSM**: 프로세스 단위 파일시스템 접근 제한 (샌드박스 강화)
- **unprivileged user namespaces** 기본 제한: 컨테이너 탈출 공격 벡터 축소
- **seccomp** 기본 프로필 강화: Kubernetes 기본 seccomp 정책과 정렬

### 6. 패키지 버전 형식 변경

Docker APT 저장소 패키지 버전이 Noble부터 distro suffix 포함:
- Jammy: `1.7.24-1`
- Noble: `2.2.2-1~ubuntu.24.04~noble`

코드에서 버전 문자열 명시 시 Noble 형식 사용 필요 → containerd 업데이트에서 반영 완료.

### 7. ARM64 (Apple Silicon) 안정성

- 24.04에서 ARM64 패키지 지원 범위 확대
- Apple Silicon Mac 기반 VirtualBox VM에서 호환성 향상
- 이번 작업의 기반 박스(`sysnet4admin/Ubuntu-k8s` v1.0.0)가 24.04 ARM64로 빌드됨

### 8. Kubernetes 최신 버전 호환성

- k8s 1.32+ 공식 테스트 환경이 Ubuntu 24.04 기준으로 전환
- kubeadm, kubelet, kubectl의 Noble APT 저장소 지원

---

## 변경 파일

| 파일 | 상태 | 내용 |
|---|---|---|
| `ch3/3.1.3/Vagrantfile` | ✅ 완료 | box → `sysnet4admin/Ubuntu-k8s` v1.0.0 (24.04) |
| `ch7/7.1.1/Vagrantfile` | ✅ 완료 | 동일 |
| `ch7/7.1.1/opt-w12g/Vagrantfile` | ✅ 완료 | 동일 |
| `ch3/3.1.3/Vagrantfile` (containerd 버전) | ✅ 완료 | Noble 형식 적용 |
| `ch7/7.1.1/Vagrantfile` (containerd 버전) | ✅ 완료 | Noble 형식 적용 |
| `ch4/4.2.1/install_docker.sh` | ⏳ Docker 업데이트 항목에서 처리 | jammy → noble 버전 문자열 변경 필요 |

## 테스트 결과

Ubuntu 24.04 기반 클러스터 전체 테스트는 containerd/Calico/MetalLB 업데이트 항목에서 검증 완료.
각 항목 PASS 14/14 확인.
