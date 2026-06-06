/// 학생 하단 3탭 — 홈 / 현황 / 설정 (§8.1). 모든 학생 화면 하단에 고정.
library;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class BottomNav extends StatelessWidget {
  final String tab; // home | history | settings
  final ValueChanged<String> onTap;
  const BottomNav({super.key, required this.tab, required this.onTap});

  static const _items = [
    ('home', '홈', Icons.home_outlined, Icons.home),
    ('history', '현황', Icons.assignment_outlined, Icons.assignment),
    ('settings', '설정', Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: _items.map((it) {
          final on = tab == it.$1;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(it.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      on ? it.$4 : it.$3,
                      size: 20,
                      color: on ? AppColors.ink : const Color(0xFFAAAAAA),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      it.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: on ? FontWeight.w800 : FontWeight.w400,
                        color: on ? AppColors.ink : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
