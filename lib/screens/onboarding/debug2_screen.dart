/// OP2 — 디버그 · 기기 상태. 권한(피험자 변경 가능) / 환경(변경 불가) + 결과 미리보기(§3.2, §4).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/evaluate.dart';
import '../../core/store.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class Debug2Screen extends StatelessWidget {
  const Debug2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final d = store.draft ?? defaultPreset();

    final r = evaluate(d.env, d.perms, d.remainingSec > 0 ? 1 : -1);
    final String rTxt = r.type == 'error'
        ? '${r.faults.map((f) => f.code).join(', ')} 오류'
        : const {
            'present': '정상 출석',
            'late': '지각',
            'block': '차단(강의실 밖)',
          }[r.type]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(
          title: '디버그 · 기기 상태',
          onBack: () => store.setScreen('debug1'),
          right: '2/2',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Lbl('권한 초기값 · 피험자 변경 가능'),
                    _segRow('위치', d.perms.location, const [
                      ('allow', '허용'),
                      ('deny', '거부')
                    ], (v) => store.setDraft(d.copyWith(perms: d.perms.copyWith(location: v)))),
                    const SizedBox(height: 8),
                    _segRow('블루투스', d.perms.bluetooth, const [
                      ('allow', '허용'),
                      ('deny', '거부')
                    ], (v) => store.setDraft(d.copyWith(perms: d.perms.copyWith(bluetooth: v)))),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('거부로 줘도 피험자가 설정에서 켜면 정상',
                          style: TextStyle(fontSize: 11, color: AppColors.mut)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Lbl('환경 상태 · 피험자 변경 불가'),
                    _segRow('강의실 위치', d.env.classroom, const [
                      ('in', '내'),
                      ('out', '밖')
                    ], (v) => store.setDraft(d.copyWith(env: d.env.copyWith(classroom: v)))),
                    const SizedBox(height: 8),
                    _segRow('네트워크', d.env.network, const [
                      ('ok', '정상'),
                      ('err', '오류')
                    ], (v) => store.setDraft(d.copyWith(env: d.env.copyWith(network: v)))),
                    const SizedBox(height: 8),
                    _segRow('서버', d.env.server, const [
                      ('ok', '정상'),
                      ('err', '오류')
                    ], (v) => store.setDraft(d.copyWith(env: d.env.copyWith(server: v)))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                dashed: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Lbl('결과 미리보기'),
                    Text.rich(
                      TextSpan(
                        text: '현재 설정 → ',
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: rTxt,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('적용 시 기기에 저장 · 재시작해도 고정',
                style: TextStyle(fontSize: 11, color: AppColors.mut)),
          ),
        ),
        AppButton('적용 & 피험자에게 핸드오프',
            onTap: () => store.applyPreset(d)),
      ],
    );
  }

  Widget _segRow(String label, String value,
      List<(String, String)> options, ValueChanged<String> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Seg(value: value, options: options, onChanged: onChanged),
      ],
    );
  }
}
