/// 사후확인(T3) 더미 주차 데이터 — 15주차, 현재 5주차 기준.
/// 프로토타입 student.jsx 의 WEEKS 생성 로직을 그대로 이식한다.
///
/// 주 2차시(hci) 기준 누계는 att 7 · late 1 · abs 1 로, kSubjects[hci].hist 와 일치하도록
/// 구성돼 있다(3주차 2차시 지각 + 오류 상세, 4주차 2차시 결석, 5주차 2차시 예정).
library;

import 'models.dart';

const int kCurWeek = 5;

const List<List<String>> _wd = [
  ['03.04', '03.06'], ['03.11', '03.13'], ['03.18', '03.20'], ['03.25', '03.27'], //
  ['04.01', '04.03'], ['04.08', '04.10'], ['04.15', '04.17'], ['04.22', '04.24'], //
  ['04.29', '05.01'], ['05.06', '05.08'], ['05.13', '05.15'], ['05.20', '05.22'], //
  ['05.27', '05.29'], ['06.03', '06.05'], ['06.10', '06.12'], //
];

List<Week> _buildWeeks() {
  final weeks = <Week>[];
  for (var i = 0; i < _wd.length; i++) {
    final w = i + 1;
    final d = _wd[i];
    var s1 = 'att', s2 = 'att';
    String? f1, p1, v1, er1; // 1차시 상세
    String? f2, p2, v2, er2; // 2차시 상세

    if (w > kCurWeek) {
      s1 = 'none';
      s2 = 'none';
    } else if (w == kCurWeek) {
      s2 = 'none'; // 진행 중: 1차시 완료, 2차시 예정
    }
    if (w == 3) {
      s2 = 'late';
      f1 = '09:01';
      p1 = '09:03';
      v1 = '인증번호 출석';
      er1 = 'PERM-03';
      f2 = '09:07';
      p2 = '09:08';
      v2 = '인증번호 지각';
      er2 = 'NET-02';
    }
    if (w == 4) {
      s2 = 'abs';
    }

    weeks.add(Week(w: w, sess: [
      Session(n: 1, d: '2026.${d[0]}', s: s1, first: f1, proc: p1, via: v1, err: er1),
      Session(
        n: 2,
        d: s2 == 'none' ? '예정' : '2026.${d[1]}',
        s: s2,
        first: f2,
        proc: p2,
        via: v2,
        err: er2,
      ),
    ]));
  }
  return weeks;
}

/// 사후확인 주차 데이터 (15주)
final List<Week> kWeeks = _buildWeeks();

/// 상태 코드 → (Pill 색 키, 라벨). student.jsx SLABEL 대응.
const Map<String, (String key, String label)> kStatusLabel = {
  'att': ('att', '출석'),
  'late': ('late', '지각'),
  'abs': ('abs', '결석'),
  'none': ('none', '미처리'),
};
