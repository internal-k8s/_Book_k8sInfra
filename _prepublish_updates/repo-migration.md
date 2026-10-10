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

옮기지 않기로 한 것이 더 생기면 이 표에 이어서 적는다.
