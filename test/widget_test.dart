// 스모크 테스트 — 스플래시가 '전자출결'을 표시하고 5탭으로 디버그에 진입한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eatt/app.dart';
import 'package:eatt/core/persistence.dart';
import 'package:eatt/core/store.dart';

void main() {
  testWidgets('스플래시 표시 + 로고 5탭 → 디버그', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final persistence = await Persistence.create();
    final store = AppStore(persistence);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppStore>.value(
        value: store,
        child: const MaterialApp(home: AppRoot()),
      ),
    );

    // 스플래시
    expect(find.text('전자출결'), findsWidgets);
    expect(store.screen, 'splash');

    // 로고 5탭 → 디버그 진입
    final logo = find.text('로고').first;
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo);
      await tester.pump();
    }
    expect(store.screen, 'debug1');

    // 트리 정리(스플래시 타이머 취소)
    await tester.pumpWidget(const SizedBox());
  });
}
