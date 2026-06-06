/// 상수 · 고정 데이터 — 프로토타입 core.jsx 와 동일한 수치/값을 그대로 고정한다.
library;

import 'models.dart';

// ===== 타이밍/수치 상수 (프로토타입 core.jsx) =====
const int kAcceptMin = 5; // 인정 시간 고정(분)
const int kQueueStart = 7; // 대기 큐 시작 번호
const Duration kQueueTick = Duration(milliseconds: 470); // 큐 1감소 간격
const Duration kSplash = Duration(milliseconds: 3000); // 스플래시 정지
const String kAuthCode = '7301'; // 고정 인증번호
const Duration kSimTick = Duration(milliseconds: 1100); // 교수 대시보드 시뮬 갱신

// ===== 고정 계정 (§2) =====
class Account {
  final String id;
  final String pw;
  const Account(this.id, this.pw);
}

const Account kStudentAcc = Account('202600001', '1q2w3e');
const Account kProfAcc = Account('50001', '1a2s3d');

// ===== 영속 저장 키 =====
const String kStorageKey = 'eatt_proto_v1';

// ===== 과목 (§10 · core.jsx SUBJECTS) =====
const List<Subject> kSubjects = [
  Subject(
    id: 'hci',
    name: '인간-컴퓨터 상호작용',
    room: '공대 7호관 301호',
    per: 2,
    total: 30,
    hist: Hist(att: 7, late: 1, abs: 1, risk: '주의'),
  ),
  Subject(
    id: 'ux',
    name: '사용자 경험 디자인',
    room: '공대 6호관 210호',
    per: 1,
    total: 15,
    hist: Hist(att: 9, late: 0, abs: 0, risk: '정상'),
  ),
  Subject(
    id: 'dr',
    name: '디자인 리서치',
    room: '공대 7호관 415호',
    per: 1,
    total: 15,
    hist: Hist(att: 7, late: 2, abs: 0, risk: '정상'),
  ),
];

Subject subjectById(String id) =>
    kSubjects.firstWhere((s) => s.id == id, orElse: () => kSubjects[0]);

// ===== 더미 학생 명단 40명 (§12.1) — 학번 202600001~202600040 =====
const List<String> _rosterNames = [
  '김민준', '이서연', '정우진', '최예은', '강하윤', '조현우', '윤지우', '임도윤', '한서준', '오지민', //
  '서준영', '신유나', '권태현', '황민서', '송재윤', '안소율', '류하은', '배성민', '전지안', '홍시우', //
  '고은채', '문준호', '양다은', '백지원', '허윤서', '남기훈', '심예진', '노건우', '하지율', '곽도현', //
  '성민재', '박지호', '차예린', '주한결', '우지호', '구나윤', '마동현', '진서아', '표은지', '명재훈', //
];

/// 고정 더미 로스터 (state 없는 기본형) — id: 2026 + 5자리 zero-pad
List<RosterStudent> buildRoster() => List.generate(
      _rosterNames.length,
      (i) => RosterStudent(
        id: '2026${(i + 1).toString().padLeft(5, '0')}',
        name: _rosterNames[i],
      ),
    );

// ===== 기본 프리셋 (core.jsx DEFAULT_PRESET) =====
Preset defaultPreset() => const Preset(
      persona: 'student',
      name: '홍길동',
      subject: 'hci',
      acceptMin: kAcceptMin,
      remainingSec: 150, // 2:30
      perms: Perms(location: 'allow', bluetooth: 'allow'),
      env: Env(classroom: 'in', network: 'ok', server: 'ok'),
    );
