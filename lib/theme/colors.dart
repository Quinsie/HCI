/// 색 토큰 — 프로토타입 index.html 의 CSS 변수와 동일.
library;

import 'package:flutter/material.dart';

class AppColors {
  // 상태 색
  static const blue = Color(0xFF1E6FD9); // 출석체크(idle)
  static const green = Color(0xFF2E7D32); // 출석
  static const yellow = Color(0xFFD6A200); // 지각
  static const red = Color(0xFFC0392B); // 오류 · 결석
  static const gray = Color(0xFF8A8A8A); // 미처리

  // 지각 칩 위 텍스트 (노랑 배경 대비)
  static const onYellow = Color(0xFF1A1400);

  // 잉크/면
  static const ink = Color(0xFF111111);
  static const paper = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF4F4F2);
  static const mut = Color(0xFF777777);

  // 선/카드
  static const line = Color(0xFFE6E6E3);
  static const cardBorder = Color(0xFFE2E2DE);
  static const fieldBorder = Color(0xFFD8D8D4);
  static const chipBorder = Color(0xFFCFCFCA);

  // 경고 카드(노랑 톤)
  static const warnBg = Color(0xFFFFF8DF);
  static const warnBorder = Color(0xFFE7D089);

  // 로딩 링 트랙
  static const loadTrack = Color(0xFFE6E6E6);

  // 차단(회색 원)
  static const block = Color(0xFF9A9A9A);
  static const blockBorder = Color(0xFF7A7A7A);
}
