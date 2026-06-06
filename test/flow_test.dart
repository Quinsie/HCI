// 플로우(상태머신) 검증 — 출결 버튼→대기 큐→판정, 오류→인증 복구, 교수 시뮬.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eatt/app.dart';
import 'package:eatt/core/constants.dart';
import 'package:eatt/core/models.dart';
import 'package:eatt/core/store.dart';
import 'package:eatt/core/persistence.dart';

Future<AppStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  final p = await Persistence.create();
  return AppStore(p);
}

Future<void> _pumpApp(WidgetTester tester, AppStore store) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppStore>.value(
      value: store,
      child: const MaterialApp(home: AppRoot()),
    ),
  );
}

/// 대기 큐(7×470ms) 통과
Future<void> _drainQueue(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(kQueueTick);
  }
  await tester.pump();
}

void main() {
  testWidgets('T1 정시: 출석체크 → 대기 큐 → 출석', (tester) async {
    final store = await _freshStore();
    // 기본 프리셋(잔여 150s, 모두 정상)
    store.setScreen('attend');
    await _pumpApp(tester, store);

    await tester.tap(find.text('출석체크'));
    await _drainQueue(tester);

    expect(store.runtime.subjectStates['hci']?.state, 'present');
    expect(store.runtime.subjectStates['hci']?.method, '자동');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('T2 지각: 잔여 0 → 지각', (tester) async {
    final store = await _freshStore();
    store.applyPreset(defaultPreset().copyWith(remainingSec: 0));
    store.setScreen('attend');
    await _pumpApp(tester, store);

    await tester.tap(find.text('출석체크'));
    await _drainQueue(tester);

    expect(store.runtime.subjectStates['hci']?.state, 'late');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('T4 오류(권한): PERM-03 → 위치 ON → 재시도 출석', (tester) async {
    final store = await _freshStore();
    store.applyPreset(defaultPreset()
        .copyWith(perms: const Perms(location: 'deny', bluetooth: 'allow')));
    store.setScreen('attend');
    await _pumpApp(tester, store);

    // 1차: 오류
    await tester.tap(find.text('출석체크'));
    await _drainQueue(tester);
    final faults = store.runtime.subjectStates['hci']?.faults ?? [];
    expect(store.runtime.subjectStates['hci']?.state, 'error');
    expect(faults.any((f) => f.code == 'PERM-03'), isTrue);

    // 권한 복구 후 재시도 → 출석 (최초 시도 잔여 > 0)
    store.setPreset(store.preset.copyWith(
        perms: const Perms(location: 'allow', bluetooth: 'allow')));
    await tester.pump();
    await tester.tap(find.text('재시도'));
    await _drainQueue(tester);
    expect(store.runtime.subjectStates['hci']?.state, 'present');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('T4 오류(환경): NET-02 → 인증번호 7301 → 출석', (tester) async {
    final store = await _freshStore();
    store.applyPreset(defaultPreset()
        .copyWith(env: const Env(classroom: 'in', network: 'err', server: 'ok')));
    store.setScreen('attend');
    await _pumpApp(tester, store);

    await tester.tap(find.text('출석체크'));
    await _drainQueue(tester);
    expect(store.runtime.subjectStates['hci']?.state, 'error');
    expect((store.runtime.subjectStates['hci']?.faults ?? [])
        .any((f) => f.code == 'NET-02'), isTrue);

    // 인증번호 입력
    await tester.tap(find.text('인증번호 입력'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), kAuthCode);
    await tester.pump();

    expect(store.runtime.subjectStates['hci']?.method, '인증번호');
    expect(store.runtime.subjectStates['hci']?.state, 'present'); // 최초 잔여 > 0
    await tester.pump(const Duration(milliseconds: 1700)); // 토스트 타이머 비우기
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('강의실 밖: 출석체크 버튼 비활성(차단)', (tester) async {
    final store = await _freshStore();
    store.applyPreset(defaultPreset()
        .copyWith(env: const Env(classroom: 'out', network: 'ok', server: 'ok')));
    store.setScreen('attend');
    await _pumpApp(tester, store);

    // 차단 상태 — 출석체크 텍스트 없음(출석 불가), 탭해도 변화 없음
    expect(find.text('출석체크'), findsNothing);
    expect(find.text('출석 불가'), findsOneWidget);
    expect(store.runtime.subjectStates['hci'], isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('교수 시뮬: 시작 후 출석 카운트 증가', (tester) async {
    final store = await _freshStore();
    store.applyPreset(defaultPreset().copyWith(persona: 'prof'));
    store.startProf(5);
    await _pumpApp(tester, store);

    // 시작 시 전원 미처리
    expect(store.prof!.every((s) => s.state == 'none'), isTrue);
    // 시뮬 몇 틱 진행 (인정시간 내 → 출석 증가)
    for (var i = 0; i < 4; i++) {
      await tester.pump(kSimTick);
    }
    final attCount = store.prof!.where((s) => s.state == 'att').length;
    expect(attCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });
}
