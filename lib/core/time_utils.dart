/// 시간/시각 헬퍼 — 모든 표시 시각은 기기 현재 시각 기준 동적 계산(§5.1).
/// 프로토타입 core.jsx 의 pad/fmtClock/fmtMMSS/profClass/studentWindow 이식.
library;

import 'constants.dart';

/// 현재 시각(epoch ms)
int nowMs() => DateTime.now().millisecondsSinceEpoch;

String pad2(int n) => n.toString().padLeft(2, '0');

/// HH:MM
String fmtClock(DateTime d) => '${pad2(d.hour)}:${pad2(d.minute)}';

/// epoch ms → HH:MM
String fmtClockMs(int ms) => fmtClock(DateTime.fromMillisecondsSinceEpoch(ms));

/// 남은 ms → MM:SS (음수는 0으로 클램프)
String fmtMMSS(int ms) {
  if (ms < 0) ms = 0;
  final s = (ms / 1000).round();
  return '${pad2(s ~/ 60)}:${pad2(s % 60)}';
}

/// 교수 수업시간: 시작 = 현재 시각의 정시(시 단위 내림), 종료 = 시작 + 90분 (§5.1)
({String start, String end}) profClass(int now) {
  final n = DateTime.fromMillisecondsSinceEpoch(now);
  final start = DateTime(n.year, n.month, n.day, n.hour);
  final end = start.add(const Duration(minutes: 90));
  return (start: fmtClock(start), end: fmtClock(end));
}

/// 학생 인정 window: 종료 = deadline, 시작 = deadline − 5분 (§5.1)
({String start, String end}) studentWindow(int deadline) {
  final start =
      DateTime.fromMillisecondsSinceEpoch(deadline - kAcceptMin * 60000);
  final end = DateTime.fromMillisecondsSinceEpoch(deadline);
  return (start: fmtClock(start), end: fmtClock(end));
}
