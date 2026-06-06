# iOS 빌드 가이드 (Mac에서 아이폰에 설치하기)

> **핵심 요약**
> - iOS 앱은 **Mac + Xcode**에서만 빌드·서명됩니다(Windows 불가). 코드는 이미 준비 완료(`ios/` 생성됨).
> - Android APK처럼 "파일 하나를 더블클릭해서 설치"하는 방식이 **아닙니다**. 반드시 **Apple 계정으로 서명**해서 설치합니다.
> - **무료 Apple ID**로도 아이폰에 바로 설치·실행 가능 → 단 **서명이 7일 후 만료**(다시 Run하면 갱신). 케이블 연결 필요.
> - **Apple Developer Program($99/년)**이 있으면 **TestFlight/ad-hoc .ipa**로 케이블 없이 다른 사람도 설치 가능.

테스트 검증용이라면 **무료 Apple ID + Xcode로 직접 설치**가 가장 빠르고 돈이 안 듭니다. 아래 순서대로 하면 됩니다.

---

## 0. Mac 사전 준비 (한 번만)
1. **Xcode 설치** — App Store에서 "Xcode" 검색 → 설치(용량 큼). 설치 후 한 번 실행해 라이선스 동의.
2. **명령행 도구**: 터미널에서
   ```bash
   xcode-select --install        # 이미 있으면 건너뜀
   sudo xcodebuild -license accept
   ```
3. **Flutter 설치** (없다면): https://docs.flutter.dev/get-started/install/macos 따라 설치 후
   ```bash
   flutter --version
   flutter doctor                 # iOS 항목이 ✓ 가까워지도록 안내 따르기
   ```
4. **CocoaPods** (대개 flutter가 안내):
   ```bash
   sudo gem install cocoapods
   ```

## 1. 프로젝트를 Mac으로 가져오기
둘 중 하나:
- **(권장) Git clone** — 레포에 푸시돼 있으면:
  ```bash
  git clone https://github.com/Quinsie/HCI.git
  cd HCI
  ```
  (아직 푸시 전이면 Windows에서 "푸시해줘"라고 하면 올려드립니다.)
- **폴더 복사** — `D:\dev\HCI` 폴더를 통째로 Mac으로 복사(USB/클라우드). 단 `build/`, `.dart_tool/`는 빼도 됨(자동 재생성).

## 2. 의존성 설치
```bash
cd HCI            # 프로젝트 루트
flutter pub get
cd ios && pod install && cd ..   # 보통 아래 run/build가 알아서 함
```

## 3. 아이폰 연결 + 신뢰
1. 아이폰을 **케이블로 Mac에 연결**.
2. 아이폰에 "이 컴퓨터를 신뢰하시겠습니까?" → **신뢰**.
3. 확인:
   ```bash
   flutter devices     # 목록에 본인 아이폰이 떠야 함
   ```

## 4. 서명 설정 (무료 Apple ID)
1. Xcode로 워크스페이스 열기:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. 왼쪽에서 **Runner** 프로젝트 → **Signing & Capabilities** 탭.
3. **Automatically manage signing** 체크.
4. **Team** 드롭다운 → **Add an Account…** → 본인 **Apple ID** 로그인 → 그 팀(Personal Team) 선택.
5. **Bundle Identifier**가 `com.hci.eatt`인데 이미 누가 썼다면 충돌날 수 있음 → 뒤에 본인 식별자를 붙여 고유하게(예: `com.hci.eatt.김철수`).

## 5. 아이폰에 설치·실행
터미널에서(가장 간단):
```bash
flutter run --release            # 연결된 아이폰에 설치 후 실행
```
또는 Xcode에서 상단의 기기를 **본인 아이폰**으로 고르고 **▶ Run**.

처음 실행 시 아이폰에서 "신뢰되지 않은 개발자" 경고가 나면:
- 아이폰 **설정 → 일반 → VPN 및 기기 관리** → 본인 Apple ID 개발자 앱 → **신뢰**.

이제 홈 화면의 **전자출결** 아이콘을 눌러 실행하면 됩니다. 🎉

> ⚠️ **무료 Apple ID는 서명이 7일 후 만료** → 앱이 "더 이상 사용할 수 없음"이 되면 4~5단계를 다시 실행(재설치)하면 됩니다.

---

## (선택) 케이블 없이 배포 — Apple Developer Program 필요
- **$99/년** 가입 후:
  - **TestFlight**: 팀원이 링크로 설치(가장 편함). Xcode에서 Archive → App Store Connect 업로드 → TestFlight.
  - **ad-hoc .ipa**: 등록한 기기들에 설치 가능한 `.ipa` 생성:
    ```bash
    flutter build ipa            # build/ios/ipa/*.ipa
    ```
- 무료 계정으로는 TestFlight/ipa 배포가 **불가**(직접 케이블 설치만).

## 검증 빌드만 보고 싶다면 (설치 없이)
아이폰 없이 동작만 보려면 Mac에서 **iOS 시뮬레이터**로:
```bash
open -a Simulator
flutter run                      # 시뮬레이터에서 실행 (서명 불필요)
```
