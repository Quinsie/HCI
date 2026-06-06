/// P-HOME — 교수 홈. 오늘의 강의 강조 → 출석 시작 진입(§9). 3탭 없음(단독 흐름).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/store.dart';
import '../../core/time_utils.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class ProfHomeScreen extends StatelessWidget {
  const ProfHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final cls = profClass(nowMs());
    final subj = subjectById('hci');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(title: '전자출결 교수', right: store.preset.name),
        Expanded(
          child: AppCard(
            emphasized: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Lbl('오늘의 강의'),
                Text(subj.name,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                Text(subj.room,
                    style: const TextStyle(fontSize: 13, color: AppColors.mut)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('${cls.start} ~ ${cls.end}',
                      style: const TextStyle(fontSize: 13)),
                ),
                const Spacer(),
                AppButton('출석 시작하기 →',
                    kind: AppBtn.blue,
                    fontSize: 16,
                    padding: const EdgeInsets.all(16),
                    onTap: () => store.setScreen('profStart')),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 6),
          child: Text('다음 강의',
              style: TextStyle(fontSize: 13, color: AppColors.mut)),
        ),
        AppCard(
          opacity: 0.5,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('사용자 경험 디자인'),
              Text('11:00', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
