# iOS 빌드·설치 가이드 (무료 Apple ID로 5명 아이폰에 직접 설치)

> **이 프로젝트의 목표 시나리오**
> - **본인 포함 5명**의 아이폰에 **무료 Apple ID**로 직접 설치한다.
> - 무료 계정 서명은 **7일 후 만료** → 만료되면 다시 설치(재서명)하면 된다. 테스트 기간(1주)엔 충분.
> - iOS는 Android APK처럼 "파일 하나 더블클릭 설치"가 **안 된다.** 반드시 **Apple 계정으로 서명**해서 케이블로 설치한다.
> - 유료 Apple Developer Program($99/년)이 있으면 TestFlight/ad-hoc `.ipa`로 케이블 없이 배포 가능(맨 아래 참고). 무료론 불가.

가장 현실적인 방법: **한 대의 Mac + 한 개의 Apple ID로, 5대의 아이폰을 차례로 케이블 연결해 설치.** 아래 순서대로.

---

## 0. 도구 설치 (Mac에서 1회)

| 도구 | 설치 | 비고 |
|---|---|---|
| **Xcode** | App Store에서 "Xcode" 검색 → 설치 (약 12~15GB) | iOS 빌드·서명 필수. Command Line Tools만으론 **불가** |
| **Flutter SDK** | `brew install --cask flutter` | `/opt/homebrew/bin`이 PATH에 있어 바로 `flutter` 사용 |
| ~~CocoaPods~~ | (불필요) | 이 프로젝트는 **Swift Package Manager(SPM)**로 의존성을 처리 → CocoaPods 없이 빌드됨 |

### Xcode 설치 후 (중요)
정식 Xcode를 받았으면 아래를 한 번씩 실행한다(라이선스·구성요소·iOS 플랫폼):
```bash
xcode-select -p          # /Applications/Xcode.app/Contents/Developer 가 아니면 ↓ 전환
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept   # Xcode 라이선스 동의
sudo xcodebuild -runFirstLaunch   # 추가 구성요소 설치
xcodebuild -downloadPlatform iOS  # iOS 기기 플랫폼(수 GB) — 없으면 "iOS not installed" 빌드 오류
xcodebuild -version               # 버전이 뜨면 성공
```
> ⚠️ 최근 Xcode는 **iOS 플랫폼이 분리 배포**라 `-downloadPlatform iOS`를 안 하면 기기 빌드 시 *"iOS 26.x is not installed"* 오류가 난다. (이 저장소에서 이미 검증 완료)

### 설치 검증
```bash
flutter --version
flutter doctor          # 'Xcode - develop for iOS' 항목이 ✓ 가 되도록 안내 따르기
```

---

## 1. 프로젝트 준비 (1회)
저장소 루트에서:
```bash
flutter pub get
flutter build ios --no-codesign      # (선택) 서명 없이 컴파일 검증 → build/ios/iphoneos/Runner.app
```
SPM 패키지는 `flutter run`/`flutter build`가 자동으로 받아오므로 `pod install` 같은 별도 단계가 없다.
위 준비는 헬퍼 스크립트(`scripts/ios_install.sh`)가 자동으로 해주므로 생략 가능.

---

## 2. 서명 설정 (Mac마다 1회 · 무료 Apple ID)
1. 워크스페이스 열기:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. 왼쪽에서 **Runner** 타깃 → **Signing & Capabilities** 탭.
3. **Automatically manage signing** 체크.
4. **Team** → **Add an Account…** → 본인 **Apple ID** 로그인 → 그 **Personal Team** 선택.
5. **Bundle Identifier**는 `com.hci.eatt`. 만약 "Failed to register bundle identifier"(이미 사용 중) 오류가 나면 뒤에 본인 식별자를 붙여 고유하게:
   - 예: `com.hci.eatt.jiho` — Xcode의 Bundle Identifier 칸에서 바로 수정하면 됨.

> 한 Apple ID로 5대 모두 설치하면 **Bundle ID·서명은 한 번만 설정**하면 된다. 기기만 바꿔 끼우면 됨.

---

## 3. 아이폰 1대에 설치하기
1. 아이폰을 **케이블로 Mac에 연결** → "이 컴퓨터를 신뢰?" → **신뢰**.
2. 기기 인식 확인:
   ```bash
   flutter devices        # 목록에 아이폰과 device-id가 떠야 함
   ```
3. 설치(둘 중 하나):
   ```bash
   # (간단) 헬퍼 스크립트 — pub get + 설치까지 한 번에
   scripts/ios_install.sh                 # 먼저 실행해 device-id 확인
   scripts/ios_install.sh <device-id>     # 그 기기에 release 설치

   # (또는 직접)
   flutter run --release -d <device-id>
   ```
4. 첫 실행 시 아이폰에 "신뢰되지 않은 개발자" 경고 → 아이폰 **설정 ▸ 일반 ▸ VPN 및 기기 관리 ▸ 본인 Apple ID 개발자 앱 ▸ 신뢰**.
5. 홈 화면의 **전자출결** 아이콘 실행 🎉

---

## 4. 5명에게 배포 (한 Mac, 한 Apple ID 기준)
2번(서명)은 한 번만 해두고, **각 아이폰을 차례로** 연결해 3번을 반복:
```bash
# 아이폰 A 연결·신뢰 후
scripts/ios_install.sh <A의 device-id>
# 케이블을 아이폰 B로 옮기고
scripts/ios_install.sh <B의 device-id>
# … C, D, E 반복 (총 5대)
```
- 각 아이폰은 **처음 연결 시 1회 '신뢰'** + **설치 후 기기에서 개발자 1회 '신뢰'**가 필요(3번 1·4단계).
- 무료 계정 제한: 앱은 **7일마다 재설치** 필요, 짧은 기간에 만들 수 있는 App ID 수에 한도가 있으나 **앱 1개·기기 5대**는 문제없음.

> 대안: 팀원이 각자 Mac을 가지고 있다면, 각자 저장소를 clone 후 **자기 Apple ID**로 2~3번을 직접 해도 된다(Bundle ID 충돌 시 5번 참고).

---

## 5. 7일 후 — 다시 설치(재서명)
무료 서명이 만료되면 앱이 "더 이상 사용할 수 없음"이 된다. 해당 아이폰을 다시 연결하고 같은 명령 한 줄:
```bash
scripts/ios_install.sh <device-id>
```
재빌드·재서명 후 다시 7일간 사용 가능.

---

## 자주 나는 오류
| 증상 | 해결 |
|---|---|
| `xcodebuild requires Xcode` | 0번의 `sudo xcode-select -s …`로 활성 경로 전환 |
| `Failed to register bundle identifier` | 2-5: Bundle ID를 고유하게(`com.hci.eatt.<이름>`) |
| 아이폰에서 앱이 안 열리고 "신뢰 안 됨" | 3-4: 설정 ▸ 일반 ▸ VPN 및 기기 관리 ▸ 신뢰 |
| 7일 뒤 실행 불가 | 5번: 다시 `scripts/ios_install.sh <device-id>` |
| `iOS 26.x is not installed` | `xcodebuild -downloadPlatform iOS` (0번) |
| 의존성/빌드 꼬임 | `flutter clean && flutter pub get` 후 재시도 |

---

## (참고) 다른 방식
- **시뮬레이터로 동작만 확인** (아이폰·서명 불필요):
  ```bash
  open -a Simulator
  flutter run                       # 시뮬레이터에서 실행
  ```
- **케이블 없이 배포 — Apple Developer Program($99/년) 필요**:
  - TestFlight: Xcode Archive → App Store Connect 업로드 → 링크로 배포(가장 편함).
  - ad-hoc `.ipa`: 등록 기기에 설치 가능한 파일 생성 → `flutter build ipa` (`build/ios/ipa/*.ipa`).
  - 무료 계정으론 TestFlight/`.ipa` 배포 불가(케이블 직접 설치만).
