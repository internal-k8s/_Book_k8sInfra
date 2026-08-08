# ch5/5.4.3 블루그린 파이프라인 — Jenkinsfile 저장소 이름 수정

> **작업 상태 (2026-08-08) — 저장소·원고 모두 완료 ✅**
> - ✅ **저장소 반영 완료** — `k8s-edu/Bkv2_sub_blue-green` main `d3f8457`. **32번 줄 1곳만 변경**
> - ✅ **원고(docx) 2곳 반영 완료** — `컨테이너 - 5...젠킨스_08Aug2026.docx`(핑크 윈도 랩탑에서 작업).
>   리스팅 101줄 전체를 저장소 `d3f8457`과 대조해 **차이 0건** 확인. 상세는 "변경 파일 → 원고" 절 참고
>
> 저장소 수정은 편집자 실습에 영향이 없다. 32번 줄이 리다이렉트로 도착하던 곳과
> **같은 저장소·같은 내용**이라 clone 결과가 한 바이트도 달라지지 않는다.
>
> **83번 줄(빈 값 정수 비교)은 검토 끝에 수정하지 않기로 했다.** 조사 내용은 남겨두되
> 조치는 하지 않는다. 판단 근거는 "수정하지 않기로 한 건" 절 참고.

## 배경

2026-08-07 편집자 리뷰 중 "5.4.3 블루그린 2차 배포(green)에서 젠킨스 빌드 실패" 보고.
원인 확인을 위해 ch3/3.1.3 클러스터(arm64)에서 Harbor 구성 → 대시보드 blue/green 빌드 →
푸시 → 배포까지 전 구간을 재현함(2026-08-08).

**재현 결과: 이미지 빌드·푸시·pull 경로에 구조적 결함 없음.** 상세는
[harbor.md](harbor.md)의 "ch5/5.4.3 연계 검증" 절 참고. 편집자 환경 고유 문제로 판단.

다만 재현 과정에서 Jenkinsfile의 문제 2건을 확인했다. 둘 다 편집자의 실패 원인은 아니다
(32번 줄은 현재 정상 동작, 83번 줄은 원인일 수도 있으나 미확정). 검토 결과 **32번 줄만
고치고 83번 줄은 그대로 두기로 했다.**

## 대상 파일

수정 대상 Jenkinsfile은 **이 저장소에 없다.** `github.com/k8s-edu/Bkv2_sub_blue-green`
(별도 저장소, 총 101줄). 맥 로컬에 상시 클론된 사본이 없으므로 clone부터 해야 한다.

- 저장소 성격: `Bkv2_` 접두사 = 2판 전용. `Bkv2_main` README의 Sub-Source 목록에 "ch5 → blue-green"으로 등록
- 강의 kit(`_Lecture_*`) 어디에서도 참조하지 않음 (2026-08-08 전수 확인)
- push 권한: `gh` 인증 계정 `sysnet4admin`이 `admin: true, push: true`

원고는 `컨테이너 - 5.지속적인 통합과 배포 자동화, 젠킨스_08Aug2026.docx`
(반영 작업 시 `19July2026` → `08Aug2026`으로 파일명 갱신됨).
수정 지점 2곳 모두 **5.4.3의 8번 단계** 안에 있다(문서 65~68% 지점).

원고 8번의 구조:

```
8. pl-blue-green 프로젝트를 빌드하기 전에 ... 확인할 필요가 있습니다.
<그림>그림 572 ...
이제 https://github.com/k8s-edu/Bkv2_sub_blue-green에 존재하는 실제 Jenkins 코드를 살펴보겠습니다.
<코드> Jenkinsfile   001 ~ 101        ← 저장소 파일을 그대로 옮겨 실은 리스팅
블루그린 배포에서 사용하는 Jenkinsfile 코드 설명은 다음과 같습니다
  3번째 줄: / 4~26번째 줄: / 29~34번째 줄: / 35~45번째 줄: / 46~64번째 줄: / 65~99번째 줄:
```

원고 리스팅의 001~101 줄번호가 저장소 Jenkinsfile의 줄번호와 정확히 일치함을 확인했다
(032 = `git url`, 083 = `if`).

---

## 수정 — 32번째 줄, 저장소 이름 ✅

### 현상

```groovy
git url: 'https://github.com/k8s-edu/Bkv2_sub_blue-green-pipeline.git', branch: 'main'
```

`Bkv2_sub_blue-green-pipeline`은 GitHub API에서 301(Moved Permanently)로 응답하며
`k8s-edu/Bkv2_sub_blue-green`으로 리다이렉트된다. 두 이름으로 각각 clone해 비교하면
내용이 완전히 동일(`diff -rq` 차이 없음). **같은 저장소이며, 파이프라인이 자기 자신을
옛 이름으로 clone하고 있다.**

### 경위 — 1판→2판 저장소 이전 정리에서 누락된 건

이 줄은 **1판 저장소 주소를 2판 이름으로 옮기는 작업에서 빠진 것**이다. 같은 시기 다른
저장소에는 그 정리가 이미 적용돼 있다.

`Bkv2_sub_echo-ip`의 커밋 `df109b7` (2024-06-10 04:03, GNU Shim,
메시지 "Jenkinsfile git repository url fix"):

```diff
- git url: 'https://github.com/IaC-Sources/echo-ip.git', branch: 'main'
+ git url: 'https://github.com/k8s-edu/Bkv2_sub_echo-ip.git', branch: 'main'
```

두 저장소의 커밋을 날짜순으로 나란히 놓으면 누락 지점이 드러난다.

| 날짜 | 저장소 | 커밋 | 작성자 |
|---|---|---|---|
| 2024-06-09 | echo-ip | first commit | Gnu Shim |
| 2024-06-10 | echo-ip | **Jenkinsfile git repository url fix** ← URL 정리됨 | GNU Shim |
| 2024-06-10 | blue-green | first commit ← **이 정리에서 빠짐** | `root <root@cp-k8s>` |
| 2024-06-29 | echo-ip | apply Bkv2_sub_echo-ip Jenkinsfile namespace default | GNU Shim |
| 2024-06-29 | blue-green | apply Bkv2_sub_blue-green-pipeline namespace default | GNU Shim |
| 2024-06-29 | blue-green | Update Jenkinsfile ×2 | GNU Shim |

blue-green의 32번째 줄 URL은 **첫 커밋 `750dc83`(2024-06-10)에 이미 들어 있었고**,
`git log -L 32,32`로 확인해도 그 줄을 마지막으로 건드린 커밋이 첫 커밋이다. 이후 커밋 3개는
이 줄을 안 건드렸다. 첫 커밋 작성자가 `root <root@cp-k8s>`(cp-k8s VM에서 git 사용자 설정 없이
커밋)인 점으로 보아, echo-ip와 달리 사람 손을 거친 URL 점검 없이 그대로 올라간 것으로 보인다.

저장소 생성은 `2024-06-09T19:16:40Z`. 2024-06-29 커밋 메시지에 아직 `-pipeline` 이름이
쓰여 있으므로, 그 뒤 어느 시점에 저장소 이름만 `Bkv2_sub_blue-green`으로 rename했다
(rename 시점·주체는 GitHub API로 조회 불가, 조직 Audit log 필요). rename 시 GitHub이
리다이렉트를 걸어줘 파이프라인이 계속 동작했기 때문에 옛 URL이 눈에 안 띄고 남았다.

### 고치는 이유

**같은 정리 작업이 echo-ip에는 적용되고 blue-green에만 누락된 상태다.** 위 경위대로
1판→2판 저장소 이전 시 URL을 맞추는 작업이 이미 진행됐고, blue-green 하나가 빠졌을 뿐이다.
따라서 이건 새 결정이 아니라 **미완료 작업의 마무리**다.

부수적으로 원고 내부의 이름 불일치도 해소된다.

```
5.4.3  6번  →  SCM Repository URL을 Bkv2_sub_blue-green 으로 설정하세요
5.4.3  8번  →  git url의 주소는 Bkv2_sub_blue-green-pipeline.git 으로 설정했습니다
```

독자에겐 저장소가 두 개인 것처럼 보이고, `Bkv2_main`의 Sub-Source 목록에는 `blue-green`
하나뿐이라 `-pipeline`을 찾게 된다. 파이프라인이 자기 자신을 clone하는 구조도 안 드러난다.

리다이렉트 의존은 부차적이며 위험도는 낮다. 리다이렉트가 끊기는 조건은 `k8s-edu` 조직에
`Bkv2_sub_blue-green-pipeline`이라는 저장소가 새로 생길 때뿐이고, 조직 소유라 외부인이
선점할 수 없다. **이것만으로는 고칠 이유가 못 된다.**

### 수정 내용

```diff
- git url: 'https://github.com/k8s-edu/Bkv2_sub_blue-green-pipeline.git', branch: 'main'
+ git url: 'https://github.com/k8s-edu/Bkv2_sub_blue-green.git', branch: 'main'
```

`-pipeline` 8글자만 삭제. `.git` 접미사는 유지.

---

## 수정하지 않기로 한 건 — 83번째 줄, 빈 값 정수 비교 ❌

### 현상

`switching LB` 단계가 배포 완료를 판단하는 부분:

```bash
export ready=$(kubectl get deployments --selector=app=dashboard,deploy=$tag \
  -o jsonpath --template="{.items[0].status.readyReplicas}" -n default)
...
if [ "$ready" -eq "$replicas" ]; then
```

쿠버네티스는 `Deployment.status.readyReplicas`를 준비된 파드가 0개일 때 필드 자체를
내보내지 않는다(omitempty). 파드가 전부 `ImagePullBackOff`면 jsonpath가 빈 문자열을
돌려주고, 그 빈 문자열이 그대로 정수 비교로 들어간다.

`sysnet4admin/kustomize:5.4.1` 컨테이너(셸 = busybox)에서 실측:

```
[현재 코드]
total replicas: 3, ready replicas:
sh: out of range          ← 종료 코드 2
ELSE

[수정안]
total replicas: 3, ready replicas:
ELSE
```

`while true` 안이므로 1초마다 무한 반복된다. 콘솔에 남는 건 `sh: out of range`뿐이고
**이미지를 못 가져왔다는 메시지는 한 줄도 안 나온다.** 독자는 셸 문법 오류로 오해한다.

### 주의 — 이건 "빌드 실패"가 아니다

`if` 조건이 거짓으로 처리되어 else의 `sleep 1`로 빠지므로, 잡은 **실패하지 않고 무한 대기**한다.
편집자가 보고한 "빌드 실패"와 바로 연결되지는 않는다. 편집자가 직접 중단시켰다면 젠킨스가
실패로 표시했을 수 있다.

**확정에 필요한 자료**: 2026-08-07 편집자 메일에 첨부된 Console Output 캡처(`image.png`).
`sh: out of range`가 반복 출력돼 있으면 이 줄이 원인이고 우선순위가 올라간다.
없으면 실패 지점이 다른 곳이며 이 수정은 코드 품질 개선에 그친다.

### 판단 — 수정하지 않는다 (2026-08-08 결정)

한때 방어 코드를 넣어 push했다가(`1511dae`, `4356e7e`) **원복했다**(`d3f8457`).
저장소와 원고 모두 **원래 코드를 그대로 둔다.**

```groovy
if [ "$ready" -eq "$replicas" ]; then      // 원래대로 유지
```

**근거 1 — 원래 코드는 안전한 쪽으로 실패한다.** 빈 값이 들어오는 모든 비정상 상태에서
busybox 오류와 함께 거짓 처리되어 대기 분기를 탄다. 잘못 전환하는 일이 없다.

**근거 2 — 방어 코드로 얻는 건 콘솔 메시지 정리뿐이다.** 이미지 pull 실패 시 잡이 무한히
도는 동작 자체는 수정 전후가 같다. 문제를 해결하지 못한다.

**근거 3 — 진단 정보는 이미 나와 있다.** 바로 앞줄이
`echo "total replicas: $replicas, ready replicas: $ready"`이므로 콘솔에
`ready replicas: ` 뒤가 빈 채로 반복 출력된다. 로그를 보면 `readyReplicas`가 안 올라오고
있다는 사실이 드러난다. `sh: out of range`는 그 옆의 잡음일 뿐이다.

**근거 4 — 잘못 쓰면 배포 로직을 깨뜨린다. 실제로 그랬다.** 1차 안
`if [ "${ready:-0}" -eq "${replicas:-0}" ]`(`1511dae`)은 `kubectl apply` 직후 컨트롤러가
status를 쓰기 전 `status.replicas`와 `status.readyReplicas`가 **둘 다 없는** 순간에
`[ 0 -eq 0 ]`이 되어 참을 반환했다. 배포가 시작되지도 않았는데 로드밸런서를 넘기고 기존
디플로이먼트를 삭제한다 — **무중단 배포가 깨진다.** 안전한 실패를 위험한 통과로 바꾸는
개악이었다. 이득 대비 위험이 맞지 않는다.

**근거 5 — 원고 수정 범위가 3곳에서 2곳으로 줄어든다.** 편집자 검토 중인 시점에 손댈 곳이
적은 편이 낫다.

### 재검토 시 참고 — 검증해 둔 대안 (개정판 몫)

개정판에서 다시 다룬다면 아래가 4가지 상태에서 올바르게 동작함을 busybox
(`sysnet4admin/kustomize:5.4.1`)에서 확인해 두었다. **`${replicas:-0}`는 절대 쓰지 말 것**
(위 근거 4).

```bash
if [ -n "$replicas" ] && [ "${ready:-0}" -eq "$replicas" ]; then
```

| `replicas` | `ready` | 상황 | 결과 |
|---|---|---|---|
| (빈 값) | (빈 값) | `kubectl apply` 직후 | 대기 ✅ |
| 3 | (빈 값) | 이미지 pull 실패 | 대기 ✅ |
| 3 | 1 | 1/3 준비 | 대기 ✅ |
| 3 | 3 | 3/3 준비 완료 | **전환** ✅ |

다만 이것도 **무한 대기는 그대로다.** 진짜 해결은 반복 횟수 제한과 `exit 1`인데, 줄이 늘어나
001~101 번호가 밀리고 "46~64번째 줄", "65~99번째 줄" 등 설명의 줄 범위를 전부 다시 매겨야
한다. 개정판에서 리스팅을 새로 짤 때 함께 처리하는 편이 맞다.

---

## ch5 전수 대조 (2026-08-08)

같은 유형의 옛 이름이 ch5 다른 곳에도 남아 있는지 전수 확인했다.
**결론: 없다. blue-green 한 저장소, 두 자리뿐이다.**

### 원고 코드 리스팅 ↔ 실제 파일

원고의 `<코드>` 블록 6개를 실제 파일과 공백 정규화 후 전부 대조했다. **6개 모두 정확히 일치.**
원고가 코드를 잘못 옮겨 적은 곳은 없다 — 저장소 파일 자체에 옛 이름이 있고 원고가 그걸
충실히 옮긴 것이므로, 고칠 곳은 양쪽 다이다.

| 원고 위치 | 실제 파일 | 줄 수 | 결과 |
|---|---|---|---|
| 5.3.1 `install_jenkins_by_helm.sh` | `ch5/5.3.1/install_jenkins_by_helm.sh` | 25 | ✅ 일치 |
| 5.4.2 `Jenkinsfile` | `k8s-edu/Bkv2_sub_echo-ip/Jenkinsfile` | 30 | ✅ 일치 |
| 5.4.3 `Jenkinsfile` | `k8s-edu/Bkv2_sub_blue-green/Jenkinsfile` | 101 | ✅ 일치 |
| 5.5.1 `Jenkinsfile` | `ch5/5.5.1/Jenkinsfile` | 18 | ✅ 일치 |
| 5.5.2 `Jenkinsfile` | `ch5/5.5.2/Jenkinsfile` | 30 | ✅ 일치 |
| 5.5.3 `Jenkinsfile` | `ch5/5.5.3/Jenkinsfile` | 37 | ✅ 일치 |

### ch5가 참조하는 외부 주소

| 참조 | 상태 |
|---|---|
| `k8s-edu/Bkv2_sub_blue-green-pipeline` | ✅ **해소** — 당시 301 → `Bkv2_sub_blue-green`(유일한 문제, 원고 2곳). 저장소·원고 모두 반영 완료 |
| `k8s-edu/Bkv2_sub_blue-green` | ✅ 200 |
| `k8s-edu/Bkv2_sub_echo-ip` | ✅ 200, Jenkinsfile 내부 URL도 자기 이름으로 정확 |
| `k8s-edu/Bkv2_sub_dashboard` | ✅ 200 |
| `k8s-edu/Bkv2_sub_gitops` | ✅ 200 |
| `k8s-edu/Bkv2_main` | ✅ 200 |
| `.../Bkv2_main/main/jenkins-cfg/jcasc/jenkins-config.yaml` | ✅ 200 |
| `.../Bkv2_main/main/jenkins-cfg/update-center/update-center.json` | ✅ 200 |
| `k8s-edu.github.io/Bkv2_main/helm-charts` (helm repo add edu) | ✅ 정상 |

### 정상으로 확인한 것 (오탐 주의)

- **`sysnet4admin/gitops` (원고에 9회 등장)** — 5.5절이 독자에게 `k8s-edu/Bkv2_sub_gitops`를
  포크해 개인 저장소로 만들라고 안내하고, 그 예시로 저자 계정을 쓴 것. 원고에도
  "원격 개인 저장소 (사용자마다 다름)" 주석이 달려 있다. 수정 대상 아님
- **5.5.1~5.5.3의 `git url: 'Git-URL'`** — `sed -i 's,Git-URL,<사용자의 깃허브 저장소 주소>,g'`로
  독자 주소를 넣게 되어 있는 자리표시자. 수정 대상 아님
- **`Bkv2_sub_dashboard/src/app/page.tsx`의 `github.com/sysnet4admin/_book_k8sinfra`** —
  대시보드 화면 우상단 아이콘 링크. 대소문자가 저장소 실제 표기와 다르지만 GitHub이
  대소문자를 구분하지 않아 200으로 열린다. 수정 불요
- **`k8s-edu/Bkv2_sub_colosseum`** — ch5 미사용. ch6(`ch6/6.6.x`) 실습용

---

## 변경 파일

### 저장소 — `github.com/k8s-edu/Bkv2_sub_blue-green`

| 파일 | 줄 | 변경 | 상태 |
|---|---|---|---|
| `Jenkinsfile` | 32 | `Bkv2_sub_blue-green-pipeline.git` → `Bkv2_sub_blue-green.git` | ✅ 완료 (원고 반영됨) |
| `Jenkinsfile` | 83 | (변경 없음 — 원래 코드 유지) | — (원고도 그대로, 일치 확인) |

**원본 `c57930e` 대비 최종 차이는 32번 줄 1곳뿐이다.** 101줄 유지.

**커밋 이력 (2026-08-08, main)**

| 커밋 | 내용 |
|---|---|
| `1511dae` | 32번 줄 + 83번 줄 방어 코드 (83번은 `${replicas:-0}` — 결함 있음) |
| `4356e7e` | 83번 줄 정정 (`-n "$replicas"` 검사 추가) |
| `d3f8457` | **83번 줄 원복.** 최종 상태 — 32번 줄만 변경된 형태 |

83번 줄 관련 두 커밋은 히스토리에 남아 있으나 최종 파일에는 반영돼 있지 않다.
판단 근거는 "수정하지 않기로 한 건" 절 참고.

> **확인 시 주의**: `raw.githubusercontent.com`은 CDN 캐시 때문에 push 직후 옛 내용을
> 반환할 수 있다. `gh api repos/k8s-edu/Bkv2_sub_blue-green/contents/Jenkinsfile --jq '.content' | base64 -d`
> 로 확인할 것.

### 원고 — `컨테이너 - 5...젠킨스_08Aug2026.docx`

**✅ 2곳 반영 완료 (2026-08-08, 핑크 윈도 랩탑).** 두 곳 다 5.4.3 8번 안에 있고,
`-pipeline` 8글자만 삭제했다. `.git` 접미사는 유지.

> **⚠️ 편집자에게 파일을 보내지 말 것.** 편집자는 2026-08-07 기준으로
> `5장-실습새로캡처-ing-20260807.docx`라는 **더 최신 작업본**에서 실습 캡처를 갈아끼우는
> 중이다(2026-08-07 메일 첨부). 여기 있는 `19July2026` 버전을 고쳐 보내면 편집자가
> 3주간 넣은 캡처와 교정이 덮인다. ch4 파일이 `_yk피드백`으로 회신된 것도 편집자가
> 파일에 직접 표시하며 작업한다는 뜻이다.
> **수정 지시를 텍스트로 전달하고, 반영은 편집자 파일에서 하도록 한다.**
> 이 docx 수정은 저자 보관본 최신화 목적이다.

| # | 위치 | 문단 위치 | 상태 |
|---|---|---|---|
| 1 | `<코드> Jenkinsfile` 리스팅 **032**번 줄 | 1736 / 2661 (65%) | ✅ |
| 2 | 코드 설명 **"29~34번째 줄:"** 문단 | 1811 / 2661 (68%) | ✅ |

반영 후 `blue-green-pipeline`은 **ch5 전체에서 0건**이다(반영 전에는 정확히 이 2건뿐).

반영 후 032번 줄이 저장소 최종본(`d3f8457`)과 일치한다:

```
032:        git url: 'https://github.com/k8s-edu/Bkv2_sub_blue-green.git', branch: 'main'
```

2번 문단의 수정 전/후:

> 29~34번째 줄: 깃허브로부터 대시보드 배포에 필요한 야믈을 내려받는 단계입니다. 이 때 소스
> 코드를 내려받기 위해 git 작업을 사용합니다. git 작업에서 인자로 요구하는 git url의 주소는
> `https://github.com/k8s-edu/Bkv2_sub_blue-green` **(← `-pipeline` 삭제)** `.git`으로
> 설정했고, branch는 main으로 설정합니다.

**083번 줄은 건드리지 않는다.** 원고 리스팅이 저장소 파일과 이미 일치한다.

**수정 불필요한 곳**:
- **`<코드> Jenkinsfile` 리스팅 083번 줄** — 83번 줄은 수정하지 않기로 했으므로 원고도 그대로.
  현재 원고 리스팅이 저장소 파일과 이미 일치한다
- "65~99번째 줄:" 설명 문단 — 비교식을 인용하지 않음
- 001~101 줄번호, 그리고 "3번째 줄", "4~26번째 줄", "35~45번째 줄", "46~64번째 줄",
  "65~99번째 줄" 등 모든 줄 범위 — 줄 수가 안 바뀜
- 5.4.3 6번의 SCM 설정 안내와 그림 570 캡처 — 이미 `Bkv2_sub_blue-green`으로 되어 있음

---

## 남은 작업

**저장소·원고 모두 반영 완료. 남은 것은 파이프라인 실기 검증뿐이다.**

원고 8번이 "실제 Jenkins 코드를 살펴보겠습니다"라며 저장소 파일을 그대로 싣는 구조이므로
인쇄될 코드와 실제 코드가 일치해야 한다. 아래 대조로 확인됨.

1. ✅ **docx 2곳 반영** (2026-08-08, 핑크 윈도 랩탑에서 저자가 직접 편집)
2. ✅ **반영 후 저장소 `d3f8457`과 대조 — 리스팅 101줄 전체 차이 0건**
   - 줄번호 라벨 `001`~`101`(문단 1604–1704)과 코드 101줄(문단 1705–1805) 개수·정렬 무손상
   - 032번 줄(문단 1736) = `Bkv2_sub_blue-green.git` ✅
   - 083번 줄(문단 1787) = `if [ "$ready" -eq "$replicas" ]; then` — 원래 코드 유지 ✅
   - 5.4.3 6번 SCM 설정 안내(문단 1587)도 `Bkv2_sub_blue-green` — 6번↔8번 이름 불일치 해소
3. ⏳ 파이프라인 재실행으로 1차(blue)/2차(green) 통과 확인 — 아직 미수행 (아래 "미해결")

편집자 실습 종료를 기다릴 필요는 없다고 판단해 저장소를 먼저 반영했다. 32번 줄 변경이
clone 결과를 바꾸지 않기 때문이다(같은 저장소·같은 내용).

> **⚠️ 편집자에게 이 docx를 보내지 말 것** — 이유는 "변경 파일 → 원고" 절의 경고 참고.
> 이 반영은 저자 보관본 최신화 목적이며, 편집자에게는 수정 지시를 텍스트로 전달한다.

## 미해결

- 편집자 환경의 실제 실패 원인 — Console Output 캡처 필요
- 저장소 rename 시점·주체 — k8s-edu 조직 Audit log 확인 필요 (수정 자체엔 불필요.
  "누가 잘못 커밋했나"는 이미 규명됨 — 아무도 잘못 넣은 게 아니라 1판→2판 URL 정리에서
  blue-green 한 건이 누락된 것. "경위" 절 참고)
- 젠킨스 파이프라인 실제 실행 검증 미수행. 2026-08-08 재현은 이미지 빌드·푸시·배포까지만
  진행했고, 젠킨스(ch5 5.2.3 헬름 → 5.3.1 설치 → 5.3.4 SA 권한)는 세우지 않았음
