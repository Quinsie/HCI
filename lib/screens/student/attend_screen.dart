/// S03~S07 — 출결 메인/진행/출석/지각/오류. 중앙 원 불변, 대기 큐 7→0,
/// §6 판정, 최초 시도 시각 기준, 오류 상태 복원, 햅틱(§8).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/evaluate.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/time_utils.dart';
import '../../theme/colors.dart';
import '../../widgets/attend_circle.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class AttendScreen extends StatefulWidget {
  const AttendScreen({super.key});
  @override
  State<AttendScreen> createState() => _AttendScreenState();
}

class _AttendScreenState extends State<AttendScreen> {
  late String _phase; // idle | loading | present | late | error | block
  int _queue = kQueueStart;
  bool _blocked = false;
  Timer? _iv; // 대기 큐 타이머
  Timer? _ticker; // idle 카운트다운 갱신

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    final subj = subjectById(store.preset.subject);
    final saved = store.runtime.subjectStates[subj.id];
    _blocked = store.preset.env.classroom == 'out';
    _phase = _blocked ? 'block' : (saved != null ? saved.state : 'idle');
    if (_phase == 'idle') _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _iv?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _press() {
    if (_blocked || _phase == 'loading') return;
    final store = context.read<AppStore>();
    final rt = store.runtime;
    int firstRem;
    if (rt.firstAttemptAt == null) {
      // 최초 시도 시각·잔여 기록 (§7.1)
      firstRem = rt.deadline - nowMs();
      store.setRuntime(rt.copyWith(firstAttemptAt: nowMs(), firstRemMs: firstRem));
    } else {
      firstRem = rt.firstRemMs ?? 0;
    }

    _ticker?.cancel();
    setState(() {
      _phase = 'loading';
      _queue = kQueueStart;
    });

    var q = kQueueStart;
    _iv?.cancel();
    _iv = Timer.periodic(kQueueTick, (t) {
      q -= 1;
      if (mounted) setState(() => _queue = q > 0 ? q : 0);
      if (q <= 0) {
        t.cancel();
        _finish(firstRem);
      }
    });
  }

  void _finish(int firstRem) {
    final store = context.read<AppStore>();
    final res = evaluate(store.preset.env, store.preset.perms, firstRem);
    final SubjectState o;
    if (res.type == 'error') {
      o = SubjectState(state: 'error', faults: res.faults);
    } else {
      o = SubjectState(state: res.type, method: '자동', at: fmtClockMs(nowMs()));
    }
    final subjId = subjectById(store.preset.subject).id;
    store.setRuntime(store.runtime.copyWith(
      subjectStates: {...store.runtime.subjectStates, subjId: o},
    ));
    if (!mounted) return;
    setState(() => _phase = res.type == 'error' ? 'error' : res.type);
    _haptic(_phase);
  }

  void _haptic(String phase) {
    switch (phase) {
      case 'present':
      case 'late':
        HapticFeedback.mediumImpact();
        break;
      case 'error':
        HapticFeedback.heavyImpact();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final subj = subjectById(store.preset.subject);
    final saved = store.runtime.subjectStates[subj.id];
    final win = studentWindow(store.runtime.deadline);
    final remMs = store.runtime.deadline - nowMs();

    final faults = saved?.faults ?? const <Fault>[];
    final fixList = faults
        .where((f) => f.fix != null)
        .map((f) => f.fix == 'loc' ? '위치 권한' : '블루투스')
        .toList();
    final hasFix = fixList.isNotEmpty;
    final fixNames = fixList.join(' · ');

    final cstate = const {
      'idle': 'idle',
      'loading': 'load',
      'present': 'green',
      'late': 'yellow',
      'error': 'red',
      'block': 'block',
    }[_phase]!;
    final ctitle = const {
      'idle': '출석체크',
      'loading': '출결 진행 중',
      'present': '출석 완료',
      'late': '지각',
      'error': '출결 오류',
      'block': '출석 불가',
    }[_phase]!;
    final csub = _phase == 'late' ? '처리됨' : null;

    final title = subj.name.length > 10 ? '${subj.name.substring(0, 9)}…' : subj.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(title: title, onBack: () => store.setScreen('home'), right: '홈'),
        // ===== attTop (고정 196) =====
        SizedBox(
          height: 196,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subj.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('인정 ${win.start} ~ ${win.end}',
                        style: const TextStyle(fontSize: 13, color: AppColors.mut)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _topStatus(store, saved, remMs, faults, hasFix, fixNames)),
            ],
          ),
        ),
        // ===== circleZone (원 불변, 항상 중앙) =====
        Expanded(
          child: Center(
            child: AttendCircle(
              state: cstate,
              title: ctitle,
              sub: csub,
              onTap: _phase == 'idle' ? _press : null,
            ),
          ),
        ),
        // ===== attBottom (고정 124) =====
        SizedBox(
          height: 124,
          child: _bottom(store, saved, hasFix),
        ),
      ],
    );
  }

  Widget _topStatus(AppStore store, SubjectState? saved, int remMs,
      List<Fault> faults, bool hasFix, String fixNames) {
    if (_phase == 'idle' || _phase == 'loading') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('남은 출석 인정 시간',
                style: TextStyle(fontSize: 11, color: AppColors.mut)),
            Text(remMs > 0 ? fmtMMSS(remMs) : '지남',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }
    if (_phase == 'present' || _phase == 'late') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('처리 시각',
                style: TextStyle(fontSize: 11, color: AppColors.mut)),
            Text(saved?.at ?? '—',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }
    if (_phase == 'error') {
      final firstAt = store.runtime.firstAttemptAt;
      return AppCard(
        warn: true,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '감지된 오류 ${faults.length}건 · 최초 시도 ${firstAt != null ? fmtClockMs(firstAt) : '—'}',
              style: const TextStyle(fontSize: 11, color: AppColors.mut),
            ),
            const SizedBox(height: 2),
            ...faults.map((f) => Text.rich(TextSpan(
                  style: const TextStyle(fontSize: 11),
                  children: [
                    TextSpan(
                        text: f.code,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: ' · ${f.msg}'),
                  ],
                ))),
            if (hasFix)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text.rich(TextSpan(
                  style: const TextStyle(fontSize: 11),
                  children: [
                    const TextSpan(text: '→ 설정에서 '),
                    TextSpan(
                        text: fixNames,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: ' 켠 뒤 재시도'),
                  ],
                )),
              ),
          ],
        ),
      );
    }
    // block
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('강의실 밖에서는 출석할 수 없습니다.',
            style: TextStyle(fontSize: 13, color: AppColors.mut)),
      ),
    );
  }

  Widget _bottom(AppStore store, SubjectState? saved, bool hasFix) {
    switch (_phase) {
      case 'idle':
        return const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('강의실 안에서 출석체크 버튼을 눌러주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.mut)),
        );
      case 'loading':
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            children: [
              Text('대기 순번 $_queue번',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const Text('처리 결과가 도착하면 표시됩니다',
                  style: TextStyle(fontSize: 11, color: AppColors.mut)),
            ],
          ),
        );
      case 'present':
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${saved?.method == '인증번호' ? '인증번호 출석' : '자동 출석'} 처리되었습니다.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.mut),
          ),
        );
      case 'late':
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '인정시간 이후 처리되어 ${saved?.method == '인증번호' ? '인증번호 ' : ''}지각 기록되었습니다.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.mut),
          ),
        );
      case 'error':
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            children: [
              if (hasFix)
                AppButton('설정으로 이동 →',
                    kind: AppBtn.ghost,
                    fontSize: 13,
                    padding: const EdgeInsets.all(9),
                    onTap: () =>
                        store.setScreen('settings', navTab: 'settings')),
              if (hasFix) const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: AppButton('재시도',
                        kind: AppBtn.ghost,
                        fontSize: 13,
                        padding: const EdgeInsets.all(9),
                        onTap: _press),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton('인증번호 입력',
                        fontSize: 13,
                        padding: const EdgeInsets.all(9),
                        onTap: () => store.setScreen('auth')),
                  ),
                ],
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
