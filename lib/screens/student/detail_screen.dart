/// S12 — 차시 상세. 처리 상태·처리 시각·최초 시도 시각·처리 방식·오류 여부(정정 근거, §10).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dummy_history.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final d = store.detail;
    final sess = d?.sess ?? const <Session>[];
    final title = '${d != null ? '${d.w}주차 ' : ''}출석 상세';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(title: title, onBack: () => store.setScreen('weeks')),
        Expanded(
          child: ListView(
            children: [
              ...sess.map((se) {
                final sl = kStatusLabel[se.s]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${se.n}차시',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            Pill(sl.$1, sl.$2),
                          ],
                        ),
                        Text(se.d,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.mut)),
                        const HLine(),
                        _kv('처리 시각', se.proc ?? '—'),
                        _kv('최초 시도 시각', se.first ?? '—'),
                        _kv('처리 방식',
                            se.via ?? (se.s == 'none' ? '미실시' : '자동 처리')),
                        _kv('오류 발생', se.err != null ? '있음 · ${se.err}' : '없음'),
                      ],
                    ),
                  ),
                );
              }),
              const AppCard(
                dashed: true,
                child: Text('처리 시각·방식·오류 여부는 정정 요청의 근거 자료로 사용됩니다.',
                    style: TextStyle(fontSize: 13, color: AppColors.mut)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 13, color: AppColors.mut)),
            Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
