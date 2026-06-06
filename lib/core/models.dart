/// 데이터 모델 — 프로토타입 core.jsx / student.jsx 의 상태 구조를 1:1 이식.
///
/// 권한/환경 값은 프로토타입과 동일한 문자열 리터럴을 그대로 사용한다
/// (영속 JSON 직렬화가 단순해지고 판정 로직이 프로토타입과 동일해진다).
///   perms.location / perms.bluetooth : 'allow' | 'deny'
///   env.classroom                    : 'in' | 'out'
///   env.network / env.server         : 'ok' | 'err'
library;

/// 권한 — 위치 · 블루투스 (피험자 변경 가능, §4.1)
class Perms {
  final String location; // 'allow' | 'deny'
  final String bluetooth; // 'allow' | 'deny'
  const Perms({required this.location, required this.bluetooth});

  Perms copyWith({String? location, String? bluetooth}) => Perms(
        location: location ?? this.location,
        bluetooth: bluetooth ?? this.bluetooth,
      );

  Map<String, dynamic> toJson() => {'location': location, 'bluetooth': bluetooth};
  factory Perms.fromJson(Map<String, dynamic> j) => Perms(
        location: j['location'] as String? ?? 'allow',
        bluetooth: j['bluetooth'] as String? ?? 'allow',
      );
}

/// 환경 — 강의실 · 네트워크 · 서버 (피험자 변경 불가, §4.2)
class Env {
  final String classroom; // 'in' | 'out'
  final String network; // 'ok' | 'err'
  final String server; // 'ok' | 'err'
  const Env({required this.classroom, required this.network, required this.server});

  Env copyWith({String? classroom, String? network, String? server}) => Env(
        classroom: classroom ?? this.classroom,
        network: network ?? this.network,
        server: server ?? this.server,
      );

  Map<String, dynamic> toJson() =>
      {'classroom': classroom, 'network': network, 'server': server};
  factory Env.fromJson(Map<String, dynamic> j) => Env(
        classroom: j['classroom'] as String? ?? 'in',
        network: j['network'] as String? ?? 'ok',
        server: j['server'] as String? ?? 'ok',
      );
}

/// 운영자 프리셋 (§3, §12) — 기기에 영속 저장
class Preset {
  final String persona; // 'student' | 'prof'
  final String name; // 운영자 자유 입력
  final String subject; // subject id (학생 전용)
  final int acceptMin; // 인정시간 5분 고정
  final int remainingSec; // 진입 시점 잔여(학생)
  final Perms perms;
  final Env env;

  const Preset({
    required this.persona,
    required this.name,
    required this.subject,
    required this.acceptMin,
    required this.remainingSec,
    required this.perms,
    required this.env,
  });

  Preset copyWith({
    String? persona,
    String? name,
    String? subject,
    int? acceptMin,
    int? remainingSec,
    Perms? perms,
    Env? env,
  }) =>
      Preset(
        persona: persona ?? this.persona,
        name: name ?? this.name,
        subject: subject ?? this.subject,
        acceptMin: acceptMin ?? this.acceptMin,
        remainingSec: remainingSec ?? this.remainingSec,
        perms: perms ?? this.perms,
        env: env ?? this.env,
      );

  Map<String, dynamic> toJson() => {
        'persona': persona,
        'name': name,
        'subject': subject,
        'acceptMin': acceptMin,
        'remainingSec': remainingSec,
        'perms': perms.toJson(),
        'env': env.toJson(),
      };

  factory Preset.fromJson(Map<String, dynamic> j) => Preset(
        persona: j['persona'] as String? ?? 'student',
        name: j['name'] as String? ?? '',
        subject: j['subject'] as String? ?? 'hci',
        acceptMin: j['acceptMin'] as int? ?? 5,
        remainingSec: j['remainingSec'] as int? ?? 150,
        perms: Perms.fromJson(Map<String, dynamic>.from(j['perms'] as Map)),
        env: Env.fromJson(Map<String, dynamic>.from(j['env'] as Map)),
      );
}

/// 출결 결함 한 건 (§6)
class Fault {
  final String code; // PERM-03 · BT-05 · NET-02 · SRV-04
  final String msg;
  final String? fix; // 'loc' | 'bt' | null (피험자가 설정에서 고칠 수 있는 권한)
  const Fault({required this.code, required this.msg, this.fix});

  Map<String, dynamic> toJson() => {'code': code, 'msg': msg, 'fix': fix};
  factory Fault.fromJson(Map<String, dynamic> j) => Fault(
        code: j['code'] as String,
        msg: j['msg'] as String,
        fix: j['fix'] as String?,
      );
}

/// 과목별 출결 처리 결과 (영속 — 오류 상태 복원의 근거, §8.4 / §12)
class SubjectState {
  final String state; // 'present' | 'late' | 'error'
  final List<Fault>? faults; // error일 때 감지된 모든 결함
  final String? method; // '자동' | '인증번호'
  final String? at; // 처리 시각 'HH:MM'
  const SubjectState({required this.state, this.faults, this.method, this.at});

  Map<String, dynamic> toJson() => {
        'state': state,
        if (faults != null) 'faults': faults!.map((f) => f.toJson()).toList(),
        if (method != null) 'method': method,
        if (at != null) 'at': at,
      };

  factory SubjectState.fromJson(Map<String, dynamic> j) => SubjectState(
        state: j['state'] as String,
        faults: (j['faults'] as List?)
            ?.map((e) => Fault.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        method: j['method'] as String?,
        at: j['at'] as String?,
      );
}

/// 런타임 진행 상태 (§12) — preset과 함께 영속 저장
class Runtime {
  int? firstAttemptAt; // 최초 시도 시각(epoch ms)
  int? firstRemMs; // 최초 시도 시점의 잔여(ms)
  Map<String, SubjectState> subjectStates; // 과목별 상태
  int deadline; // 인정 마감 시각(epoch ms)

  Runtime({
    this.firstAttemptAt,
    this.firstRemMs,
    required this.subjectStates,
    required this.deadline,
  });

  Runtime copyWith({
    int? firstAttemptAt,
    int? firstRemMs,
    Map<String, SubjectState>? subjectStates,
    int? deadline,
    bool resetFirstAttempt = false,
  }) =>
      Runtime(
        firstAttemptAt:
            resetFirstAttempt ? null : (firstAttemptAt ?? this.firstAttemptAt),
        firstRemMs: resetFirstAttempt ? null : (firstRemMs ?? this.firstRemMs),
        subjectStates: subjectStates ?? this.subjectStates,
        deadline: deadline ?? this.deadline,
      );

  Map<String, dynamic> toJson() => {
        'firstAttemptAt': firstAttemptAt,
        'firstRemMs': firstRemMs,
        'subjectStates':
            subjectStates.map((k, v) => MapEntry(k, v.toJson())),
        'deadline': deadline,
      };

  factory Runtime.fromJson(Map<String, dynamic> j) => Runtime(
        firstAttemptAt: j['firstAttemptAt'] as int?,
        firstRemMs: j['firstRemMs'] as int?,
        subjectStates: (j['subjectStates'] as Map?)?.map(
              (k, v) => MapEntry(
                k as String,
                SubjectState.fromJson(Map<String, dynamic>.from(v as Map)),
              ),
            ) ??
            <String, SubjectState>{},
        deadline: j['deadline'] as int,
      );
}

/// 과목 메타 (상수 데이터)
class Subject {
  final String id;
  final String name;
  final String room;
  final int per; // 주당 차시 (1 또는 2)
  final int total; // 총 차시 (15주 기준): per*15
  final Hist hist; // 사후확인 누계
  const Subject({
    required this.id,
    required this.name,
    required this.room,
    required this.per,
    required this.total,
    required this.hist,
  });
}

/// 사후확인 과목 누계 (§10)
class Hist {
  final int att;
  final int late;
  final int abs;
  final String risk; // '정상' | '주의'
  const Hist({
    required this.att,
    required this.late,
    required this.abs,
    required this.risk,
  });
}

/// 교수 대시보드 더미 학생 (세션 전용 — 영속하지 않음)
class RosterStudent {
  final String id;
  final String name;
  final String state; // 'none' | 'att' | 'late' | 'err' | 'abs'
  const RosterStudent({required this.id, required this.name, this.state = 'none'});

  RosterStudent copyWith({String? state}) =>
      RosterStudent(id: id, name: name, state: state ?? this.state);
}

/// 사후확인 차시 (§10) — 주차 상세
class Session {
  final int n; // 차시 번호
  final String d; // 날짜 라벨 (예: '2026.03.04' / '예정')
  final String s; // 'att' | 'late' | 'abs' | 'none'
  final String? first; // 최초 시도 시각
  final String? proc; // 처리 시각
  final String? via; // 처리 방식
  final String? err; // 오류 코드
  const Session({
    required this.n,
    required this.d,
    required this.s,
    this.first,
    this.proc,
    this.via,
    this.err,
  });
}

/// 사후확인 주차
class Week {
  final int w;
  final List<Session> sess;
  const Week({required this.w, required this.sess});
}

/// 차시 상세 화면(S12)으로 넘길 주차 데이터
class WeekDetail {
  final int w;
  final List<Session> sess;
  const WeekDetail({required this.w, required this.sess});
}
