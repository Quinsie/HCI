/// OP0 — 스플래시. 로고 5탭 → 디버그, 3초 후 로그인(§3.1).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/store.dart';
import '../../theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(kSplash, () {
      if (mounted) context.read<AppStore>().setScreen('login');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Column(
      children: [
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.read<AppStore>().tapLogo(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset('assets/logo.png', width: 92, height: 132),
              if (store.logoTaps > 0)
                Positioned(
                  right: -12,
                  bottom: -12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.ink),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${store.logoTaps}/5',
                        style: const TextStyle(fontSize: 11)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('전자출결',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Text('Electronic Attendance',
            style: TextStyle(fontSize: 12, color: AppColors.mut)),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('로고 5번 탭 → 디버그 · 3초 후 로그인',
              style: TextStyle(fontSize: 11, color: AppColors.mut)),
        ),
      ],
    );
  }
}
