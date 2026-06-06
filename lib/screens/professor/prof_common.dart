/// 교수 대시보드 공용 — 상태 라벨/정렬 RANK + 타이머 기반 더미 시뮬(§9.1).
/// 프로토타입 prof.jsx 의 PST/RANK/evolve 를 1:1 이식.
library;

import 'dart:math';

import '../../core/models.dart';

/// 상태 코드 → (Pill 색 키, 라벨)
const Map<String, (String key, String label)> kProfStatus = {
  'att': ('att', '출석'),
  'late': ('late', '지각'),
  'none': ('none', '미처리'),
  'err': ('err', '오류'),
  'abs': ('abs', '결석'),
};

/// 정렬 우선순위: 오류 → 지각 → 미처리 → 결석 → 출석
const Map<String, int> kProfRank = {
  'err': 0,
  'late': 1,
  'none': 2,
  'abs': 3,
  'att': 4,
};

final Random _rng = Random();

/// 한 틱 진행 — 인정시간 내(inAccept)면 2~4명 출석(88%)/오류(12%),
/// 이후면 잔여 미처리>6일 때 가끔 1명 지각(75%)/오류(25%). (전원 출석/오류 안 됨)
List<RosterStudent> evolveRoster(List<RosterStudent> arr, bool inAccept) {
  final next = List<RosterStudent>.from(arr);
  final noneIdx = <int>[];
  for (var i = 0; i < next.length; i++) {
    if (next[i].state == 'none') noneIdx.add(i);
  }
  if (noneIdx.isEmpty) return next;

  int n;
  if (inAccept) {
    final r = 2 + _rng.nextInt(3); // 2..4
    n = noneIdx.length < r ? noneIdx.length : r;
  } else {
    n = (noneIdx.length > 6 && _rng.nextDouble() < 0.6) ? 1 : 0;
  }

  for (var c = 0; c < n; c++) {
    final j = _rng.nextInt(noneIdx.length);
    final pick = noneIdx.removeAt(j);
    final newState = inAccept
        ? (_rng.nextDouble() < 0.12 ? 'err' : 'att')
        : (_rng.nextDouble() < 0.25 ? 'err' : 'late');
    next[pick] = next[pick].copyWith(state: newState);
  }
  return next;
}
