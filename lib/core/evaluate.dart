/// 출결 판정 로직 (명세서 §6 · 프로토타입 core.jsx evaluate).
/// 강의실 밖 = 차단, 그 외엔 **감지된 모든 결함을 수집**(동시 표시),
/// 무결함이면 잔여 > 0 → 출석 / ≤ 0 → 지각.
library;

import 'models.dart';

class EvalResult {
  final String type; // 'block' | 'error' | 'present' | 'late'
  final List<Fault> faults;
  const EvalResult(this.type, {this.faults = const []});
}

EvalResult evaluate(Env env, Perms perms, int remainingMs) {
  if (env.classroom == 'out') return const EvalResult('block');

  final faults = <Fault>[];
  if (perms.location == 'deny') {
    faults.add(const Fault(code: 'PERM-03', msg: '위치 권한이 꺼져 있습니다.', fix: 'loc'));
  }
  if (perms.bluetooth == 'deny') {
    faults.add(const Fault(code: 'BT-05', msg: '블루투스가 꺼져 있습니다.', fix: 'bt'));
  }
  if (env.network == 'err') {
    faults.add(const Fault(code: 'NET-02', msg: '네트워크 연결에 실패했습니다.'));
  }
  if (env.server == 'err') {
    faults.add(const Fault(code: 'SRV-04', msg: '서버가 응답하지 않습니다.'));
  }
  if (faults.isNotEmpty) return EvalResult('error', faults: faults);

  return EvalResult(remainingMs > 0 ? 'present' : 'late');
}
