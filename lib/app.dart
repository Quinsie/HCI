/// AppRoot — 프로토타입 app.jsx 의 라우터. store.screen 기반 화면 스위치 +
/// 기기 안전영역 + 토스트 오버레이. 데스크톱/태블릿에서는 최대 폭 480으로 중앙 정렬
/// (실제 폰에서는 화면을 채움 · 가짜 디바이스 프레임은 두지 않음).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/store.dart';
import 'screens/onboarding/debug1_screen.dart';
import 'screens/onboarding/debug2_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/professor/prof_dash_screen.dart';
import 'screens/professor/prof_edit_screen.dart';
import 'screens/professor/prof_home_screen.dart';
import 'screens/professor/prof_start_screen.dart';
import 'screens/student/attend_screen.dart';
import 'screens/student/auth_screen.dart';
import 'screens/student/detail_screen.dart';
import 'screens/student/history_screen.dart';
import 'screens/student/home_screen.dart';
import 'screens/student/settings_screen.dart';
import 'screens/student/weeks_screen.dart';
import 'theme/colors.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  Widget _screenFor(String name) {
    switch (name) {
      case 'login':
        return const LoginScreen();
      case 'debug1':
        return const Debug1Screen();
      case 'debug2':
        return const Debug2Screen();
      case 'home':
        return const HomeScreen();
      case 'attend':
        return const AttendScreen();
      case 'auth':
        return const AuthScreen();
      case 'settings':
        return const SettingsScreen();
      case 'history':
        return const HistoryScreen();
      case 'weeks':
        return const WeeksScreen();
      case 'detail':
        return const DetailScreen();
      case 'profHome':
        return const ProfHomeScreen();
      case 'profStart':
        return const ProfStartScreen();
      case 'profDash':
        return const ProfDashScreen();
      case 'profEdit':
        return const ProfEditScreen();
      case 'splash':
      default:
        return const SplashScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: _screenFor(store.screen),
                ),
                if (store.toast.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 80,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.ink.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            store.toast,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
