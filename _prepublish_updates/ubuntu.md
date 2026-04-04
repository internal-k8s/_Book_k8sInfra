# Ubuntu 22.04 → 24.04 ✅ (진행 중)

## 전환 이유

### 1. LTS 지원 기간
| 항목 | Ubuntu 22.04 (Jammy) | Ubuntu 24.04 (Noble) |
|---|---|---|
| 표준 지원 종료 | 2027년 4월 | 2029년 4월 |
| ESM 지원 종료 | 2032년 4월 | **2034년 4월 (10년)** |

책 출판 후 독자들이 장기간 사용하는 환경을 고려하면 24.04가 훨씬 안전한 기반.

### 2. 커널 버전 향상
- 22.04: 커널 5.15 LTS
- 24.04: 커널 **6.8** (GA)
  - eBPF 기능 확장 (Cilium 등 CNI 성능 향상)
  - io_uring 안정화
  - cgroup v2 완전 지원 → containerd/k8s 권장 설정과 일치

### 3. 패키지 버전 형식 변경
Docker APT 저장소 패키지 버전이 Noble부터 distro suffix 포함:
- Jammy: `1.7.24-1`
- Noble: `2.2.2-1~ubuntu.24.04~noble`

코드에서 버전 문자열 명시 시 Noble 형식 사용 필요 → containerd 업데이트에서 반영 완료.

### 4. 보안 강화
- AppArmor 4.0 기본 탑재
- unprivileged user namespaces 기본 제한 (k8s 환경에서는 별도 설정 필요)
- seccomp 프로필 개선

### 5. ARM64(Apple Silicon) 안정성
- 24.04에서 ARM64 패키지 지원 범위 확대
- Apple Silicon Mac 기반 VirtualBox VM에서 호환성 향상
- 이번 작업의 기반 박스(`sysnet4admin/Ubuntu-k8s` v1.0.0)가 24.04 ARM64로 빌드됨

### 6. Kubernetes 최신 버전 호환성
- k8s 1.32+ 공식 테스트 환경이 Ubuntu 24.04 기준으로 전환
- kubeadm, kubelet, kubectl의 Noble APT 저장소 지원

## 변경 파일

| 파일 | 상태 | 내용 |
|---|---|---|
| `ch3/3.1.3/Vagrantfile` | ✅ 완료 | box → `sysnet4admin/Ubuntu-k8s` v1.0.0 (24.04) |
| `ch7/7.1.1/Vagrantfile` | ✅ 완료 | 동일 |
| `ch3/3.1.3/Vagrantfile` (containerd 버전) | ✅ 완료 | Noble 형식 적용 |
| `ch7/7.1.1/Vagrantfile` (containerd 버전) | ✅ 완료 | Noble 형식 적용 |
| `ch4/4.2.1/install_docker.sh` | ⏳ Docker 업데이트 시 처리 | jammy → noble 버전 문자열 변경 필요 |

## 테스트 결과

Ubuntu 24.04 기반 클러스터 전체 테스트는 containerd/Calico/MetalLB 업데이트 항목에서 검증 완료.
각 항목 PASS 14/14 확인.
