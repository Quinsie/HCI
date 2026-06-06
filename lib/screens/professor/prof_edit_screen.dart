/// P09 — 학생 상태 변경(출석/지각/결석 + 실행취소). 대시보드 행 탭으로 진입(§9).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';
import 'prof_common.dart';

class ProfEditScreen extends StatefulWidget {
  const ProfEditScreen({super.key});
  @override
  State<ProfEditScreen> createState() => _ProfEditScreenState();
}

class _ProfEditScreenState extends State<ProfEditScreen> {
  String? _prev;

  RosterStudent _cur(AppStore store) {
    final t = store.editTarget!;
    return (store.prof ?? const <RosterStudent>[])
        .firstWhere((x) => x.id == t.id, orElse: () => t);
  }

  void _change(String ns) {
    final store = context.read<AppStore>();
    final t = store.editTarget!;
    setState(() => _prev = _cur(store).state);
    store.setProf(store.prof!
        .map((x) => x.id == t.id ? x.copyWith(state: ns) : x)
        .toList());
    store.showToast('${kProfStatus[ns]!.$2}(으)로 변경됨');
  }

  void _undo() {
    final store = context.read<AppStore>();
    final t = store.editTarget!;
    store.setProf(store.prof!
        .map((x) => x.id == t.id ? x.copyWith(state: _prev!) : x)
        .toList());
    setState(() => _prev = null);
    store.showToast('실행 취소');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.editTarget;
    if (t == null) {
      return Column(children: [
        TopBar(title: '학생 상태 변경', onBack: () => store.setScreen('profDash')),
      ]);
    }
    final cur = _cur(store);
    final st = kProfStatus[cur.state]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(title: '학생 상태 변경', onBack: () => store.setScreen('profDash')),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(t.id,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.mut)),
                    ],
                  ),
                  Pill(st.$1, st.$2),
                ],
              ),
              const HLine(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('현재 상태',
                      style: TextStyle(fontSize: 13, color: AppColors.mut)),
                  Text(st.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 8),
          child: Text('대시보드 리스트에서 학생을 누르면 바로 이 화면이 열립니다.',
              style: TextStyle(fontSize: 13, color: AppColors.mut)),
        ),
        if (_prev != null)
          AppCard(
            dashed: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('상태가 변경되었습니다.', style: TextStyle(fontSize: 13)),
                AppButton('실행 취소',
                    kind: AppBtn.ghost,
                    fontSize: 13,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    onTap: _undo),
              ],
            ),
          ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text('상태 변경', style: TextStyle(fontSize: 13, color: AppColors.mut)),
        ),
        Row(
          children: [
            _stateBtn('출석', AppColors.green, Colors.white, () => _change('att')),
            const SizedBox(width: 8),
            _stateBtn('지각', AppColors.yellow, AppColors.onYellow, () => _change('late')),
            const SizedBox(width: 8),
            _stateBtn('결석', AppColors.red, Colors.white, () => _change('abs')),
          ],
        ),
      ],
    );
  }

  Widget _stateBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: bg),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
        ),
      ),
    );
  }
}
