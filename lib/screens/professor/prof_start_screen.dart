/// P01 — 출석 시작. 인정 시간 선택 후 출석 시작 → 대시보드 시뮬(§9).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/store.dart';
import '../../core/time_utils.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class ProfStartScreen extends StatefulWidget {
  const ProfStartScreen({super.key});
  @override
  State<ProfStartScreen> createState() => _ProfStartScreenState();
}

class _ProfStartScreenState extends State<ProfStartScreen> {
  int _acc = 5;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final cls = profClass(nowMs());
    final subj = subjectById('hci');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(title: '출석 시작', onBack: () => store.setScreen('profHome')),
        Expanded(
          child: ListView(
            children: [
              AppCard(
                emphasized: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Lbl('오늘의 강의'),
                    Text(subj.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('${subj.room} · ${cls.start} ~ ${cls.end}',
                        style:
                            const TextStyle(fontSize: 13, color: AppColors.mut)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const AppCard(
                dashed: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Lbl('출결 정책'),
                    Text('· 인정 시간: 출석 시작 후 설정한 분 동안',
                        style: TextStyle(fontSize: 11, color: AppColors.mut)),
                    Text('· 인정 시간 이후 시도 → 지각',
                        style: TextStyle(fontSize: 11, color: AppColors.mut)),
                    Text('· 오류 시 인증번호(7301) fallback',
                        style: TextStyle(fontSize: 11, color: AppColors.mut)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Lbl('출결 인정 시간'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [3, 5, 10, 15]
                          .map((m) => AppChip(
                                label: '$m분',
                                on: _acc == m,
                                onTap: () => setState(() => _acc = m),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('[출석 시작]을 누른 시각부터 $_acc분간 인정됩니다.',
                style: const TextStyle(fontSize: 11, color: AppColors.mut)),
          ),
        ),
        AppButton('출석 시작',
            kind: AppBtn.blue,
            padding: const EdgeInsets.all(16),
            onTap: () => store.startProf(_acc)),
      ],
    );
  }
}
