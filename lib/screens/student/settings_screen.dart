/// SET — 설정. 피험자가 바꿀 수 있는 권한 토글(위치·블루투스)만. 환경은 비노출(§8.5).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store.dart';
import '../../theme/colors.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final p = store.preset.perms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TopBar(title: '설정'),
        Expanded(
          child: ListView(
            children: [
              const AppCard(
                warn: true,
                child: Text('출결 오류가 났다면 아래 권한을 켜고 다시 시도하세요.',
                    style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    _permRow(
                      '위치 권한',
                      p.location,
                      (v) => store.setPreset(
                          store.preset.copyWith(perms: p.copyWith(location: v))),
                    ),
                    const SizedBox(height: 10),
                    _permRow(
                      '블루투스',
                      p.bluetooth,
                      (v) => store.setPreset(
                          store.preset.copyWith(perms: p.copyWith(bluetooth: v))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text('※ 강의실 위치·네트워크·서버는 운영자만 설정(여기 없음).',
                  style: TextStyle(fontSize: 11, color: AppColors.mut)),
            ],
          ),
        ),
        BottomNav(tab: store.navTab, onTap: store.tabNavigate),
      ],
    );
  }

  Widget _permRow(String label, String value, ValueChanged<String> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Seg(
          value: value,
          options: const [('deny', 'OFF'), ('allow', 'ON')],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
