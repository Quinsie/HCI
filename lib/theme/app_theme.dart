/// 앱 테마 — 밝은 테마, 잉크 텍스트, 블루 시드. 한글은 플랫폼 기본 폰트로 폴백 렌더.
library;

import 'package:flutter/material.dart';

import 'colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
    ).copyWith(surface: AppColors.paper),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}
