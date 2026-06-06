/// S10 — 출석 현황 요약. 과목 카드(전체·출석·지각·결석 + 위험도). 전체=총 차시(§10).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/store.dart';
import '../../theme/colors.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TopBar(title: '출석 현황'),
        Expanded(
          child: ListView(
            children: [
              const AppCard(
                warn: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Lbl('⚠ 출결 유의사항'),
                    Text.rich(TextSpan(
                      style: TextStyle(fontSize: 13),
                      children: [
                        TextSpan(text: '총 수업시수의 '),
                        TextSpan(
                            text: '1/4 이상 결석 시 F',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: '.'),
                      ],
                    )),
                    Text('전체 = 총 차시(15주 기준).', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ...kSubjects.map((s) {
                final h = s.hist;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => store.goWeeks(s.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const Text('›', style: TextStyle(color: AppColors.mut)),
                          ],
                        ),
                        const HLine(),
                        Wrap(
                          spacing: 14,
                          runSpacing: 6,
                          children: [
                            _stat('none', '전체', s.total),
                            _stat('att', '출석', h.att),
                            _stat('late', '지각', h.late),
                            _stat('abs', '결석', h.abs),
                          ],
                        ),
                        const HLine(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('현재 상태',
                                style: TextStyle(fontSize: 13, color: AppColors.mut)),
                            Pill(h.risk == '주의' ? 'warn' : 'att', h.risk),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        BottomNav(tab: store.navTab, onTap: store.tabNavigate),
      ],
    );
  }

  Widget _stat(String kind, String label, int n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Pill(kind, label),
        const SizedBox(width: 5),
        Text('$n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
