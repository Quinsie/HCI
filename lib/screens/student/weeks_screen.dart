/// S11 — 주차별 출석(아코디언 펼치기/접기). per=1 과목은 차시 1개만 표시(§10).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/dummy_history.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class WeeksScreen extends StatefulWidget {
  const WeeksScreen({super.key});
  @override
  State<WeeksScreen> createState() => _WeeksScreenState();
}

class _WeeksScreenState extends State<WeeksScreen> {
  int _open = kCurWeek;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final subj = subjectById(store.histSubject ?? 'hci');
    final title =
        subj.name.length > 11 ? '${subj.name.substring(0, 10)}…' : subj.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(title: title, onBack: () => store.setScreen('history')),
        // 범례
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill('att', '출석'),
              Pill('late', '지각'),
              Pill('abs', '결석'),
              Pill('none', '미처리'),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: kWeeks.map((w) {
              final op = _open == w.w;
              final sess = subj.per == 1 ? [w.sess[0]] : w.sess;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 주차 헤더
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _open = op ? 0 : w.w),
                    child: Container(
                      margin: EdgeInsets.only(bottom: op ? 0 : 6),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: op
                            ? const BorderRadius.vertical(top: Radius.circular(10))
                            : BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(op ? '▾' : '▸',
                                  style: const TextStyle(color: AppColors.mut)),
                              const SizedBox(width: 6),
                              Text('${w.w}주차',
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Text(_summary(sess),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.mut)),
                        ],
                      ),
                    ),
                  ),
                  if (op)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => store
                          .goDetail(WeekDetail(w: w.w, sess: sess)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAFAFA),
                          border: Border(
                            left: BorderSide(color: AppColors.cardBorder),
                            right: BorderSide(color: AppColors.cardBorder),
                            bottom: BorderSide(color: AppColors.cardBorder),
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          children: [
                            ...sess.map((se) {
                              final sl = kStatusLabel[se.s]!;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${se.n}차시 · ${se.d}',
                                        style: const TextStyle(fontSize: 13)),
                                    Pill(sl.$1, sl.$2),
                                  ],
                                ),
                              );
                            }),
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text('차시 상세 보기 ›',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.mut)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _summary(List<Session> sess) {
    var att = 0, late = 0, abs = 0;
    for (final s in sess) {
      switch (s.s) {
        case 'att':
          att++;
          break;
        case 'late':
          late++;
          break;
        case 'abs':
          abs++;
          break;
      }
    }
    if (att + late + abs == 0) return '미처리/예정';
    return '출석 $att · 지각 $late · 결석 $abs';
  }
}
