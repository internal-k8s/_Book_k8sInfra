# 저장소 이전 (internal-k8s → sysnet4admin)

이 저장소(`internal-k8s/_Book_k8sInfra`)는 집필 중 기록과 테스트에 쓰는 저장소다.
출간 직전에 `sysnet4admin/_Book_k8sInfra`로 옮긴다. 저장소 이름의 글자 수를 같게 맞춘
것도 그 때문이다.

이 저장소의 파일은 지우지 않는다. 옮길 때 아래 목록만 빼고 옮긴다.

## 옮기지 않는 것

| 대상 | 이유 | 결정일 |
|---|---|---|
| `ch2/2.1.3/vagrantup.output` | 1판 때(2023-04) 찍은 `vagrant up` 출력. 박스 0.8.0, VirtualBox 7.0 기준이라 2판 본문(박스 1.0.0, VirtualBox 7.2.8)과 다르다. 책에서 언급하지 않는 참고 파일 | 2026-10-10 |
| `ch2/2.2.1/vagrantup.output` | 위와 같음 | 2026-10-10 |
| `ch2/2.2.2/vagrantup.output` | 위와 같음 | 2026-10-10 |
| `ch2/2.2.3/vagrantup.output` | 위와 같음 | 2026-10-10 |
| `_prepublish_updates/` | 집필 중 기록. 독자용이 아니다 | 2026-11-20 |
| `UPDATE_PLAN.md` | 집필 계획 | 2026-11-20 |
| `ch3/3.1.3/81.backup-v1.25.9-w-docker/`, `82.backup-v1.27.4-w-docker/`, `83.backup-v1.27.4-wo-docker/`, `98.old-w-cilium/`, `99.old-w-calico/` | 예전 버전 환경. 책 88쪽 그림 3-10이 `ch3/3.1.3`을 파일 5개로 보여 준다. 안에 `internal-k8s` 주소도 남아 있다 | 2026-11-20 |
| `ch7/7.1.3/old/` | 예전 헤드램프 실습 파일(`flatted_kubeconfig.sh`). 책에서 쓰지 않는다 | 2026-11-20 |
| `ch7/old/` | 예전 Lens 실습(`7.2.3-lens/`, 2023). 책에서 쓰지 않는다 | 2026-11-20 |
| `ch7/docs/` | 7.5절 집필 중 설계, 성능, 테스트 기록 4개. 옮기지 않는 `_prepublish_updates/misc.md`를 가리킨다 | 2026-11-20 |
| `ch7/7.1.3/backup_kubeconfig.sh` | 어디서도 부르지 않는다. 디버그 문구가 남아 있다 | 2026-11-20 |
| `app/C.kubespray/pre-kubespray-w-simple.sh` | Vagrantfile이 쓰지 않는 예전 변형 | 2026-11-20 |

옮기지 않기로 한 것이 더 생기면 이 표에 이어서 적는다.

남길 파일은 책과 저장소의 다른 파일에서 쓰이는지 두 번 확인했다(2026-11-20, 파일 이름 기준과 디렉터리, 파일 내용 기준).

## 옮길 때 지킬 것

- `git archive`로 옮긴다. 심볼릭 링크 2개(`ch5/5.2.2/FROM_3.4.3`, `ch5/5.2.3/FROM_3.4.3`, 책 289쪽에서 설명)와 실행 비트,
  `maven-wrapper.jar` 2개가 그대로 유지되어야 한다. 일반 복사는 링크를 실제 폴더 사본으로 바꿀 수 있다.

