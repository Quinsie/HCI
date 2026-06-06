# 전자출결 (Electronic Attendance)

대학 강의용 **전자출결** 크로스플랫폼(iOS · Android) 앱 — HCI 팀 프로젝트(C팀, 2026).
실서버 없이 **전부 로컬(기기 내 상태 + 영속 저장)**으로 동작하며, 운영자가 디버그 화면에서
시나리오를 미리 세팅한 뒤 피험자에게 건네는 **운영자 프리셋(Operator Preset)** 방식으로
4개 핵심 Task(정시 출석 · 지각 · 사후확인 · 오류 대응)와 교수 흐름을 재현·검증한다.

> 기준 문서: `prototype/전자출결 명세서 v1.html` (source of truth) · 동작 레퍼런스: `prototype/prototype/*` ·
> 레이아웃 참고: `prototype/Flow Wireframe v1.html`. 충돌 시 **명세서 > 프로토타입 > 와이어프레임**.

---

## 1. 기술 스택 · 아키텍처

| 영역 | 선택 | 이유 |
|---|---|---|
| 프레임워크 | **Flutter** (Dart) | iOS/Android 단일 렌더 → "중앙 원 불변"·픽셀 일관성, 로딩 링/색전환/햅틱 내장 |
| 상태관리 | **Provider + ChangeNotifier** | 프로토타입의 단일 스토어(`useReducer`+Context)와 1:1 |
| 영속 저장 | **shared_preferences** | 프로토타입 `localStorage`(키 `eatt_proto_v1`)와 1:1, `{preset, runtime}` JSON 1키 |
| 라우팅 | **상태-구동 화면 스위치** | `store.screen` 기반. "타이틀 5탭→디버그", "오류 화면 복원", "핸드오프→스플래시"를 스택 없이 처리 |

핵심 로직(상수·판정·시뮬 타이밍)은 프로토타입 `core.jsx`/`student.jsx`/`prof.jsx`를 그대로 이식했다.
대기 큐 `7→0`(470ms), 스플래시 `3초`, 교수 시뮬 `1100ms`, 인증번호 `7301`, 인정시간 `5분 고정` 등 수치 동일.

### 프로젝트 구조
```
lib/
 ├ main.dart                  앱 진입 · shared_preferences 로드 · Provider 주입
 ├ app.dart                   AppRoot — store.screen 기반 화면 스위치 + 토스트 오버레이
 ├ core/
 │  ├ constants.dart          상수 · SUBJECTS · ROSTER(40명) · 계정 · 기본 프리셋
 │  ├ models.dart             Preset/Perms/Env/Runtime/SubjectState/Fault/Subject/Session/Week …
 │  ├ time_utils.dart         fmtClock/fmtMMSS/profClass/studentWindow (동적 시각 §5.1)
 │  ├ evaluate.dart           출결 판정 §6 (감지된 모든 결함 수집)
 │  ├ store.dart              AppStore(ChangeNotifier) + 영속 연동
 │  ├ persistence.dart        shared_preferences 래퍼
 │  └ dummy_history.dart      사후확인 더미 주차(15주) 데이터
 ├ theme/                     colors · app_theme
 ├ widgets/                   TopBar(5탭 디버그) · AttendCircle(원 불변) · BottomNav · Seg · Pill · 카드/버튼
 └ screens/
    ├ onboarding/   splash · login · debug1(OP1) · debug2(OP2)
    ├ student/      home · attend(S03~S07) · auth(S08) · settings · history(S10) · weeks(S11) · detail(S12)
    └ professor/    prof_home · prof_start(P01) · prof_dash(P02) · prof_edit(P09) · prof_common(시뮬)
```

---

## 2. 실행 · 빌드 방법

### 사전 준비
- **Flutter SDK (stable)** 필요. 이 개발 머신에는 `D:\flutter`에 설치되어 있다(Flutter 3.44 / Dart 3.12).
- PATH 등록(새 터미널에서 `flutter` 직접 사용하려면):
  ```powershell
  setx PATH "$($env:Path);D:\flutter\bin"   # 새 터미널부터 적용
  ```
  또는 매번 전체 경로 사용: `& "D:\flutter\bin\flutter.bat" <cmd>`

### 의존성 설치
```powershell
flutter pub get
```

### 실행
```powershell
flutter run                 # 연결된 기기/에뮬레이터 선택
flutter run -d chrome       # 웹(빠른 동작 확인용)
```

### 📦 Android APK (빌드 완료 · 즉시 설치 가능)
이 머신(`D:\dev\HCI`)에서 **빌드 성공**했고, 결과 APK는 다음 위치에 있다:
```
dist\전자출결-v1.0-release.apk        (46MB · 통합 ABI · 디버그키 서명 → 사이드로드 가능)
build\app\outputs\flutter-apk\app-release.apk   (동일 파일)
```
직접 빌드하려면:
```powershell
flutter build apk --release   # → build\app\outputs\flutter-apk\app-release.apk
```
**휴대폰 설치**: APK를 폰으로 전송(USB/클라우드) → 파일 탭 → "출처를 알 수 없는 앱 설치" 허용 → 설치 → 홈에 **전자출결** 아이콘.

### iOS (Mac + Xcode 필요 · 무료 Apple ID로 5명 직접 설치)
이 머신(macOS 26.3, Apple M4 / Xcode 26.5 / Flutter 3.44)에서 **빌드 검증 완료**
(`flutter build ios --no-codesign` → `✓ Built build/ios/iphoneos/Runner.app`). 의존성은 **Swift Package Manager**로 처리되어 CocoaPods가 필요 없다.

무료 Apple ID로 **본인 포함 5명 아이폰에 케이블로 직접 설치**(서명 7일 만료 → 재설치)하는 시나리오다.
- 🧰 **설치 담당자(Mac)** 전체 절차(Xcode 설치·서명·배포·재설치): **[docs/iOS_빌드_가이드.md](docs/iOS_빌드_가이드.md)**
- 📱 **아이폰 사용자별** 따라하기(비개발자용): **[docs/아이폰_설치_안내.md](docs/아이폰_설치_안내.md)**

설치는 헬퍼 스크립트로 한 줄:
```bash
scripts/ios_install.sh                 # 사전 점검 + 연결된 기기 device-id 확인
scripts/ios_install.sh <device-id>     # 그 아이폰에 release 설치 (pub get·SPM 자동)
```

### 검증 (이 저장소에서 통과 확인됨)
```powershell
dart analyze                # 정적 분석 → No issues found!
flutter analyze             # (ASCII 경로라 정상 동작) → No issues found!
flutter test                # 스모크 + 15화면 렌더 + 플로우 8개 → All tests passed!
flutter build web           # 웹 컴파일 → ✓ Built build\web
flutter build apk --release # Android → ✓ Built app-release.apk (46MB)
```

### 이 머신의 Android 빌드 환경 (셋업 완료)
APK 빌드를 위해 아래가 설치·구성되어 있다(`flutter build apk` 재실행 시 그대로 동작):
- **JDK 17**: `D:\jdk17\jdk-17.0.19+10` (Flutter에 `flutter config --jdk-dir`로 연결)
- **Android SDK**: `%LOCALAPPDATA%\Android\Sdk` — cmdline-tools, **platform android-36**, **build-tools 36.0.0**, platform-tools, NDK 28.2/CMake 3.22(빌드 중 자동 설치), 라이선스 동의 완료
- **`android/gradle.properties`에 `kotlin.incremental=false`** — Pub 캐시(C:)와 프로젝트(D:)가 다른 드라이브일 때 Kotlin 증분 캐시가 "different roots"로 크래시하는 문제 회피
- **`windows/` 데스크톱 폴더 제거** — Flutter가 APK 빌드 중에도 *Windows 데스크톱* 플러그인 심링크를 만들려다 권한(개발자 모드) 부족으로 실패하던 것을 원천 차단(타깃은 Android·iOS·web)

---

## 3. 디버그(운영자 프리셋) 사용법

| 진입 | 방법 |
|---|---|
| 콜드 스타트 | 스플래시에서 **로고 5탭** → 디버그 OP1 |
| 앱 작동 중 | 좌상단 **'전자출결' 타이틀 5탭** → 디버그 OP1 (재부팅 불필요) |
| 전체 초기화 | 디버그 OP1 하단 **[전체 초기화 · 처음부터]** → 저장 삭제 → 스플래시 |

흐름: **OP1(페르소나·이름·과목·남은 인정시간)** → (학생) **OP2(권한·환경)** → **[적용 & 핸드오프]** →
기기에 영구 저장 후 스플래시 재시작. 앱을 껐다 켜도 같은 프리셋 유지(재설정 전까지).

> 프로토타입의 프레임 밖 플로팅 리셋 버튼은 데모 전용이라 실제 앱에는 넣지 않았다. 초기화는 디버그 안 버튼으로만.

### 계정 (고정)
| 페르소나 | ID | 비밀번호 | 이름 |
|---|---|---|---|
| 학생 | `202600001` | `1q2w3e` | 운영자 자유 입력 |
| 교수 | `50001` | `1a2s3d` | 운영자 자유 입력 |

로그인 화면은 항상 노출되며 프리셋 계정이 자동 입력된다.

---

## 4. 4개 Task · 교수 흐름 재현법

OP1/OP2에서 아래처럼 세팅하고 핸드오프하면 각 Task가 재현된다. 학생의 T1·T2·T4는
별도 선택이 아니라 **세팅한 환경/시간**이 결과를 결정한다(T3는 환경 무관 공통 기능).

| Task | 페르소나 | 남은 인정시간 | 위치 | 블루투스 | 강의실 | 네트워크 | 서버 | 피험자 경험 |
|---|---|---|---|---|---|---|---|---|
| **T1 정시 출석** | 학생 | `> 0` (예 2:30) | 허용 | 허용 | 내 | 정상 | 정상 | 출석체크 → 로딩(큐 7→0) → **초록 출석** |
| **T2 지각** | 학생 | `0:00`(경과) | 허용 | 허용 | 내 | 정상 | 정상 | 출석체크 → **노랑 지각 처리됨** |
| **T4 오류·권한** | 학생 | 임의 | **거부** | 허용 | 내 | 정상 | 정상 | **빨강 오류 PERM-03** → [설정으로 이동]에서 위치 ON → [재시도] 통과 |
| **T4 오류·환경** | 학생 | 임의 | 허용 | 허용 | 내 | **오류** | 정상 | **오류 NET-02**(피험자 못 고침) → [인증번호 입력] `7301` → 최초 시도 시각 기준 판정 |
| **T4 차단** | 학생 | — | — | — | **밖** | — | — | 출석체크 버튼 **비활성** + "강의실 밖에서는 출석할 수 없습니다" |
| **T3 사후확인** | 학생 | 임의 | — | — | — | — | — | 하단 **현황** 탭 → 과목 카드 → 주차 아코디언 → 차시 상세(처리/최초시도/오류) |
| **P 교수** | 교수 | — | — | — | — | — | — | 홈 → 출석 시작(인정시간) → 대시보드(40명 타이머 시뮬·정렬) → 행 탭 상태변경(실행취소) |

추가 검증 포인트:
- **여러 결함 동시 표시**: 위치 거부 + 네트워크 오류로 세팅 → 오류 화면에 `PERM-03`·`NET-02` 동시 노출.
- **오류 상태 복원**: 오류가 난 과목은 홈에서 재진입 시 출결 메인이 아니라 **마지막 오류 화면**으로 복원.
- **동적 시각**: 모든 표시 시각·카운트다운은 기기 현재 시각 기준으로 계산(하드코딩 없음). 교수 수업시간 = 현재 정시~+90분.

---

## 5. 핵심 동작 매핑 (명세서 ↔ 구현)

- **중앙 원 불변(§8.6)** — `widgets/attend_circle.dart`: 위치·크기(200) 고정, 색/텍스트만 변경. 로딩은 링만 회전(글씨 정지).
- **출결 판정(§6)** — `core/evaluate.dart`: 강의실 밖=차단, 그 외 **감지된 모든 결함 수집**(PERM-03·BT-05·NET-02·SRV-04), 무결함이면 잔여>0 출석 / ≤0 지각.
- **시간 모델(§5)** — `core/time_utils.dart` + 스토어 `deadline`. 인정 5분 고정, 진입 잔여로부터 실시간 카운트다운, 콜드 스타트 시 미시도면 deadline 갱신.
- **최초 시도 시각(§7)** — `runtime.firstAttemptAt/firstRemMs`. 재시도·인증번호 판정은 항상 최초 시도 기준.
- **인증번호 fallback(§7)** — `screens/student/auth_screen.dart`: 오류 후에만 진입, 고정 `7301`. 명세 §8.6 "시스템 키패드"에 맞춰 **네이티브 숫자 키패드**(autofocus) + 4핀 표시.
- **교수 시뮬(§9.1)** — `screens/professor/prof_common.dart`: 인정시간 내 2~4명 출석(88%)/오류(12%), 이후 미처리>6일 때 가끔 지각(75%)/오류(25%) → 전원 출석/오류가 되지 않음. 정렬 오류→지각→미처리→출석, 동순위 이름 오름차순.
- **사후확인(§10)** — hci(주2차시)=전체30, ux·dr(주1차시)=전체15. 주차 아코디언 → 차시 상세.
- **영속(§12)** — `{preset, runtime}` 1키 저장. 과목별 상태·최초시도시각 유지.

### 명세 우선 결정 / 프로토타입과 의도적 차이
- **모든 오류 동시 표시**: 명세 §6 본문은 "첫 코드만"이라 적었으나, 운영자 지시 + 프로토타입 `evaluate`가 모든 결함을 수집하므로 **동시 표시**를 채택(상위 권위인 지시·동작 레퍼런스 일치).
- **인증번호 키패드**: 프로토타입은 커스텀 온스크린 키패드였으나, 명세 §7.2/§8.6의 "기기 기본 숫자 키패드"에 맞춰 **네이티브 키보드**로 구현(=네이티브답게 다듬기).
- **가짜 디바이스 프레임/상태바**: 웹 데모용 목업 요소라 네이티브에선 제거. 실기기 화면을 채우고(태블릿/데스크톱은 최대 폭 480 중앙 정렬), OS 상태바는 SafeArea로 회피.
- **BT-05(블루투스)**: 명세 §13 미결정 항목이나 운영자 결정으로 **유지**(위치+블루투스 2종 권한 분기).

---

## 6. 알려진 제약
- iOS 빌드는 macOS·Xcode 필요(코드는 iOS/Android 양쪽 동작하도록 작성).
- Android 실기기 빌드는 이 머신 기준 cmdline-tools·JDK17 추가 설정 + 공백/한글 없는 경로로의 복사가 필요할 수 있음(§2 참고).
- 푸시 알림 미구현(테스트가 출석 시뮬이라 외부 진입 없음 — 명세 §8).
- 사후확인 더미는 hci(주2차시) 누계가 `att7/late1/abs1`과 정확히 일치하도록 구성. 주1차시 과목은 표시용 더미라 누계와 주차 상세가 1:1로 맞지 않을 수 있음(테스트 빌드 한정, 프로토타입과 동일).
