// 화면 렌더 스모크 — 15개 화면을 폰 크기(390×844)로 렌더하여
// 레이아웃 오버플로우/빌드 예외가 없는지 확인한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eatt/app.dart';
import 'package:eatt/core/dummy_history.dart';
import 'package:eatt/core/models.dart';
import 'package:eatt/core/store.dart';
import 'package:eatt/core/persistence.dart';

void main() {
  testWidgets('15개 화면 렌더 — 오버플로우/예외 없음', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});
    final persistence = await Persistence.create();
    final store = AppStore(persistence);

    final cases = <String, void Function(AppStore)>{
      'splash': (s) => s.setScreen('splash'),
      'login': (s) => s.setScreen('login'),
      'debug1': (s) => s.enterDebug(),
      'debug2': (s) {
        s.enterDebug();
        s.setScreen('debug2');
      },
      'home': (s) => s.setScreen('home'),
      'attend': (s) => s.setScreen('attend'),
      'auth': (s) => s.setScreen('auth'),
      'settings': (s) => s.setScreen('settings'),
      'history': (s) => s.setScreen('history'),
      'weeks': (s) {
        s.histSubject = 'hci';
        s.setScreen('weeks');
      },
      'detail': (s) {
        s.detail = WeekDetail(w: 3, sess: kWeeks[2].sess);
        s.setScreen('detail');
      },
      'profHome': (s) => s.setScreen('profHome'),
      'profStart': (s) => s.setScreen('profStart'),
      'profDash': (s) => s.startProf(5),
      'profEdit': (s) {
        s.startProf(5);
        s.editTarget = s.prof!.first;
        s.setScreen('profEdit');
      },
    };

    for (final entry in cases.entries) {
      entry.value(store);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStore>.value(
          value: store,
          child: const MaterialApp(home: AppRoot()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: '화면 "${entry.key}" 렌더 실패');
      // 다음 화면 전에 트리 정리(주기 타이머 취소)
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });
}
