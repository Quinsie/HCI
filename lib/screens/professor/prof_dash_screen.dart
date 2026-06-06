/// P02 — 실시간 출석 대시보드. 타이머 기반 더미 시뮬, 카운트·정렬 갱신(§9.1).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/time_utils.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';
import 'prof_common.dart';

class ProfDashScreen extends StatefulWidget {
  const ProfDashScreen({super.key});
  @override
  State<ProfDashScreen> createState() => _ProfDashScreenState();
}

class _ProfDashScreenState extends State<ProfDashScreen> {
  Timer? _sim;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    final accMs = store.profAccept * 60000;
    // 더미 시뮬 (SIM_TICK 마다 진화)
    _sim = Timer.periodic(kSimTick, (_) {
      final s = context.read<AppStore>();
      final inAcc = nowMs() < (s.profStartedAt ?? 0) + accMs;
      s.setProf(evolveRoster(s.prof ?? const [], inAcc));
    });
    // 남은시간 카운트다운 (useTick 1000)
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sim?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = store.prof ?? const <RosterStudent>[];
    final accMs = store.profAccept * 60000;
    final remain = (store.profStartedAt ?? nowMs()) + accMs - nowMs();

    final cnt = {'att': 0, 'late': 0, 'none': 0, 'err': 0, 'abs': 0};
    for (final s in list) {
      cnt[s.state] = (cnt[s.state] ?? 0) + 1;
    }

    final sorted = [...list]..sort((a, b) {
        final r = kProfRank[a.state]! - kProfRank[b.state]!;
        return r != 0 ? r : a.name.compareTo(b.name);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(title: '인간-컴퓨터 상호작용', onBack: () => store.setScreen('profHome')),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('출석 진행 중',
                  style: TextStyle(fontSize: 13, color: AppColors.mut)),
              Text('남은시간 ${remain > 0 ? fmtMMSS(remain) : '종료'}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        AppCard(
          dashed: true,
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('인증번호 (fallback)',
                      style: TextStyle(fontSize: 13, color: AppColors.mut)),
                  Text(kAuthCode,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4)),
                ],
              ),
              const Text('오류 발생 학생에게만 사용',
                  style: TextStyle(fontSize: 11, color: AppColors.mut)),
            ],
          ),
        ),
        // 카운트 합계
        Row(
          children: [
            _sumCell('전체', list.length, null),
            _sumCell('출석', cnt['att']!, const Color(0x1A2E7D32)),
            _sumCell('지각', cnt['late']!, const Color(0x29D6A200)),
            _sumCell('미처리', cnt['none']!, const Color(0x248A8A8A)),
            _sumCell('오류', cnt['err']! + cnt['abs']!, const Color(0x1FC0392B)),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text('정렬: 오류→지각→미처리→출석 · 이름 오름차순 · 행 탭 → 변경',
              style: TextStyle(fontSize: 11, color: AppColors.mut)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              final s = sorted[i];
              final st = kProfStatus[s.state]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => store.goEdit(s),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFECECEC)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontSize: 14)),
                            Text(s.id,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.mut)),
                          ],
                        ),
                        Row(
                          children: [
                            Pill(st.$1, st.$2),
                            const SizedBox(width: 6),
                            const Text('›', style: TextStyle(color: AppColors.mut)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sumCell(String label, int value, Color? tint) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        decoration: BoxDecoration(
          color: tint ?? AppColors.paper,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.mut)),
            const SizedBox(height: 2),
            Text('$value',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
