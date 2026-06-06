/// HOME — 학생 홈. 권한 체크리스트 + 활성 과목 강조 + 비활성 과목(§8.2). 하단 3탭.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/store.dart';
import '../../core/time_utils.dart';
import '../../theme/colors.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // 카운트다운 실시간 갱신 (useTick 1000)
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final subj = subjectById(store.preset.subject);
    final win = studentWindow(store.runtime.deadline);
    final remMs = store.runtime.deadline - nowMs();
    final p = store.preset.perms;
    final ss = store.runtime.subjectStates[subj.id];

    final slab = ss == null
        ? '미처리'
        : const {'present': '출석 완료', 'late': '지각', 'error': '출결 오류'}[ss.state]!;
    final spill = ss == null
        ? 'none'
        : const {'present': 'att', 'late': 'late', 'error': 'err'}[ss.state]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(title: '전자출결', right: store.preset.name),
        // 권한 체크리스트
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Lbl('출결 준비 상태'),
              Row(
                children: [
                  _check('위치 권한', p.location == 'allow'),
                  const SizedBox(width: 18),
                  _check('블루투스', p.bluetooth == 'allow'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 활성 과목 강조
        Expanded(
          child: AppCard(
            emphasized: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Lbl('현재 강의'),
                    Pill(spill, slab),
                  ],
                ),
                Text(subj.name,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                Text(subj.room,
                    style: const TextStyle(fontSize: 13, color: AppColors.mut)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text.rich(TextSpan(
                    style: const TextStyle(fontSize: 13),
                    children: [
                      TextSpan(text: '인정 ${win.start}~${win.end} · 남은시간 '),
                      TextSpan(
                        text: remMs > 0 ? fmtMMSS(remMs) : '종료',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  )),
                ),
                const Spacer(),
                AppButton(
                  ss != null ? '출결 화면 열기' : '출석체크',
                  kind: AppBtn.blue,
                  fontSize: 16,
                  padding: const EdgeInsets.all(16),
                  onTap: () => store.setScreen('attend'),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 6),
          child: Text('내 수강 과목 · 수업시간 아님',
              style: TextStyle(fontSize: 13, color: AppColors.mut)),
        ),
        // 비활성 과목
        ...kSubjects.where((s) => s.id != subj.id).map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AppCard(
                  opacity: 0.5,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  onTap: () => store.showToast('수업시간이 아닙니다'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.name),
                      const Text('비활성', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        BottomNav(tab: store.navTab, onTap: store.tabNavigate),
      ],
    );
  }

  Widget _check(String label, bool ok) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ok ? Icons.check : Icons.close,
            size: 16, color: ok ? AppColors.green : AppColors.red),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ok ? AppColors.green : AppColors.red)),
      ],
    );
  }
}
