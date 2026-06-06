/// OP1 — 디버그 · 시나리오. 페르소나/이름/계정(고정)/과목/남은 인정시간(§3.2~3.3).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/store.dart';
import '../../core/time_utils.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class Debug1Screen extends StatefulWidget {
  const Debug1Screen({super.key});
  @override
  State<Debug1Screen> createState() => _Debug1ScreenState();
}

class _Debug1ScreenState extends State<Debug1Screen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: context.read<AppStore>().draft?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final d = store.draft ?? defaultPreset();
    final isStu = d.persona != 'prof';
    final remLbl = d.remainingSec <= 0
        ? '0:00 · 경과(지각)'
        : fmtMMSS(d.remainingSec * 1000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(
          title: '디버그 · 시나리오',
          onBack: () => store.setScreen('splash'),
          right: isStu ? '1/2' : '1/1',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            children: [
              // 페르소나
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Lbl('피험자 페르소나'),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Seg(
                        value: d.persona,
                        options: const [('student', '학생'), ('prof', '교수')],
                        onChanged: (v) => store.setDraft(d.copyWith(persona: v)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 이름 + 계정
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Lbl('이름 (직접 입력)'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.fieldBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _name,
                        onChanged: (v) => store.setDraft(d.copyWith(name: v)),
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: '이름 입력…',
                        ),
                      ),
                    ),
                    _kv(isStu ? '학번' : '사번', isStu ? kStudentAcc.id : kProfAcc.id),
                    _kv('비밀번호', isStu ? kStudentAcc.pw : kProfAcc.pw),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('계정·비번 고정',
                          style: TextStyle(fontSize: 11, color: AppColors.mut)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (isStu)
                _subjectTimeCard(store, d, remLbl)
              else
                const AppCard(
                  dashed: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Lbl('교수는 환경 분기 없음'),
                      Text(
                        '권한·환경 설정 없이 바로 핸드오프. 인정시간 설정·출석 시작은 앱 내 P01에서.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        AppButton(
          '전체 초기화 · 처음부터',
          kind: AppBtn.ghost,
          fontSize: 13,
          padding: const EdgeInsets.all(10),
          onTap: () => store.resetAll(),
        ),
        const SizedBox(height: 8),
        if (isStu)
          AppButton('다음 · 기기 상태 →', onTap: () => store.setScreen('debug2'))
        else
          AppButton('적용 & 핸드오프',
              onTap: () => store.applyPreset(d.copyWith(persona: 'prof'))),
      ],
    );
  }

  Widget _subjectTimeCard(AppStore store, d, String remLbl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Lbl('강의 · 시간'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kSubjects.map((s) {
              final label = s.name.length > 8 ? '${s.name.substring(0, 7)}…' : s.name;
              return AppChip(
                label: label,
                on: d.subject == s.id,
                onTap: () => store.setDraft(d.copyWith(subject: s.id)),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _kv('인정 시간', '5분 · 고정'),
          const HLine(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('남은 인정 시간',
                  style: TextStyle(fontSize: 13, color: AppColors.mut)),
              Text(remLbl, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton('− 15초',
                    kind: AppBtn.ghost,
                    padding: const EdgeInsets.all(10),
                    fontSize: 14,
                    onTap: () => store.setDraft(d.copyWith(
                        remainingSec: (d.remainingSec - 15).clamp(0, 300)))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton('+ 15초',
                    kind: AppBtn.ghost,
                    padding: const EdgeInsets.all(10),
                    fontSize: 14,
                    onTap: () => store.setDraft(d.copyWith(
                        remainingSec: (d.remainingSec + 15).clamp(0, 300)))),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('0:00 = 경과 → 지각 상황으로 시작',
                style: TextStyle(fontSize: 11, color: AppColors.mut)),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 13, color: AppColors.mut)),
            Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
