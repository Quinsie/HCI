#!/usr/bin/env bash
#
# ios_install.sh — 무료 Apple ID로 연결된 아이폰에 '전자출결'을 설치/실행
# (Mac + 정식 Xcode 필요. 무료 계정은 7일 후 서명 만료 → 다시 실행하면 갱신)
#
# 이 프로젝트는 Swift Package Manager로 의존성을 처리한다 → CocoaPods 불필요.
# (flutter run이 SPM 패키지를 자동 해석)
#
# 사전(각 Mac에서 1회):
#   1) App Store에서 Xcode 설치 → 라이선스/구성요소:
#        sudo xcodebuild -license accept
#        sudo xcodebuild -runFirstLaunch
#        xcodebuild -downloadPlatform iOS      # iOS 기기 플랫폼(수 GB)
#   2) open ios/Runner.xcworkspace → Runner ▸ Signing & Capabilities
#        ▸ "Automatically manage signing" 체크
#        ▸ Team = 본인 Apple ID (Add an Account…로 로그인 후 Personal Team)
#      자세한 절차는 docs/iOS_빌드_가이드.md 참고.
#
# 사용법:
#   scripts/ios_install.sh            # 사전 점검 + 연결된 기기 목록 표시
#   scripts/ios_install.sh <기기ID>   # 해당 아이폰에 release 빌드 설치+실행
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

red()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; }
grn()  { printf '\033[32m✓ %s\033[0m\n' "$1"; }
cyn()  { printf '\033[36m• %s\033[0m\n' "$1"; }

# ── 사전 점검 ───────────────────────────────────────────────
command -v flutter >/dev/null || { red "flutter 없음 — Flutter SDK 설치 후 PATH 등록 필요"; exit 1; }

DEV_DIR="$(xcode-select -p 2>/dev/null || true)"
case "$DEV_DIR" in
  *CommandLineTools*|"")
    red "정식 Xcode가 활성화되지 않음 (현재: ${DEV_DIR:-없음})"
    red "App Store에서 Xcode 설치 후:"
    red "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1 ;;
esac
grn "Xcode active: $DEV_DIR"

# ── 의존성 (SPM은 flutter가 자동 처리) ─────────────────────────
cyn "flutter pub get"
flutter pub get

# ── 기기 ──────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo
  cyn "연결된 기기:"
  flutter devices
  echo
  cyn "설치하려면:  scripts/ios_install.sh <기기ID>   (위 목록의 device-id)"
  cyn "처음 설치하는 아이폰이라면:"
  cyn "  · 케이블 연결 후 아이폰에서 '이 컴퓨터를 신뢰' 탭"
  cyn "  · 설치 후 아이폰: 설정 ▸ 일반 ▸ VPN 및 기기 관리 ▸ 본인 Apple ID ▸ 신뢰"
  exit 0
fi

DEVICE="$1"
cyn "release 빌드 + 설치 → $DEVICE   (설치 후 'q'를 누르면 콘솔만 빠져나오고 앱은 남음)"
flutter run --release -d "$DEVICE"
