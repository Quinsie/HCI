/// 앱 스토어 — 프로토타입 core.jsx 의 useStore(useReducer + Context) 단일 스토어를
/// ChangeNotifier 로 1:1 이식. preset/runtime 변경 시 자동으로 기기에 영속 저장한다.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'constants.dart';
import 'models.dart';
import 'persistence.dart';
import 'time_utils.dart';

/// 새 런타임 — 진입 시점 잔여로부터 deadline 계산 (core.jsx freshRuntime).
Runtime freshRuntime(Preset preset) => Runtime(
      firstAttemptAt: null,
      firstRemMs: null,
      subjectStates: <String, SubjectState>{},
      deadline: nowMs() + preset.remainingSec * 1000,
    );

class AppStore extends ChangeNotifier {
  final Persistence _persistence;

  // ----- 내비게이션 / UI 상태 (영속 안 함) -----
  String screen = 'splash';
  String navTab = 'home'; // home | history | settings
  int logoTaps = 0;
  String toast = '';

  // ----- 영속 상태 -----
  late Preset preset;
  late Runtime runtime;

  // ----- 디버그 작성중 프리셋 -----
  Preset? draft;

  // ----- 교수 세션 (영속 안 함) -----
  int profAccept = 5;
  int? profStartedAt;
  RosterStudent? editTarget;
  List<RosterStudent>? prof;

  // ----- 사후확인 내비게이션 (영속 안 함) -----
  String? histSubject;
  WeekDetail? detail;

  Timer? _toastTimer;

  AppStore(this._persistence) {
    _loadInitial();
    _persist(); // 마운트 시 현재 상태를 저장 (프로토타입 useEffect 초기 실행과 동일)
  }

  void _loadInitial() {
    final p = _persistence.load();
    final Preset preset0 = p != null
        ? Preset.fromJson(Map<String, dynamic>.from(p['preset'] as Map))
        : defaultPreset();
    Runtime runtime0 = p != null
        ? Runtime.fromJson(Map<String, dynamic>.from(p['runtime'] as Map))
        : freshRuntime(preset0);

    // 아직 출결을 시도하지 않았는데 deadline이 과거면(재시작으로 시간 경과) 갱신.
    if (runtime0.firstAttemptAt == null && runtime0.deadline < nowMs()) {
      runtime0 = runtime0.copyWith(
        deadline: nowMs() + preset0.remainingSec * 1000,
      );
    }
    preset = preset0;
    runtime = runtime0;
  }

  void _persist() {
    unawaited(_persistence.save({
      'preset': preset.toJson(),
      'runtime': runtime.toJson(),
    }));
  }

  // ===== 내비게이션 =====
  void setScreen(String s, {String? navTab}) {
    screen = s;
    if (navTab != null) this.navTab = navTab;
    notifyListeners();
  }

  /// 학생 하단탭 이동 (home→home, history→history, settings→settings)
  void tabNavigate(String tab) {
    navTab = tab;
    screen = tab == 'home' ? 'home' : tab;
    notifyListeners();
  }

  void showToast(String msg) {
    toast = msg;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      toast = '';
      notifyListeners();
    });
  }

  // ===== 디버그 진입 =====
  /// 스플래시 로고 탭 — 5회 누적 시 디버그.
  void tapLogo() {
    final n = logoTaps + 1;
    if (n >= 5) {
      logoTaps = 0;
      enterDebug();
    } else {
      logoTaps = n;
      notifyListeners();
    }
  }

  /// 디버그 진입 — 현재 프리셋을 draft 로 복사해 OP1 로.
  void enterDebug() {
    draft = preset; // Preset 은 불변이라 복사 불필요
    screen = 'debug1';
    notifyListeners();
  }

  void setDraft(Preset d) {
    draft = d;
    notifyListeners();
  }

  // ===== 로그인 =====
  void login() {
    screen = preset.persona == 'prof' ? 'profHome' : 'home';
    navTab = 'home';
    notifyListeners();
  }

  // ===== 프리셋 적용 / 초기화 =====
  /// [적용 & 핸드오프] — 프리셋 영속 저장 후 스플래시 재시작.
  void applyPreset(Preset p) {
    preset = p;
    runtime = freshRuntime(p);
    draft = null;
    screen = 'splash';
    logoTaps = 0;
    navTab = 'home';
    _persist();
    notifyListeners();
  }

  /// 전체 초기화 — 저장 삭제 후 기본 프리셋으로 스플래시부터 (§11.1).
  void resetAll() {
    unawaited(_persistence.clear());
    preset = defaultPreset();
    runtime = freshRuntime(preset);
    draft = null;
    prof = null;
    profStartedAt = null;
    editTarget = null;
    histSubject = null;
    detail = null;
    screen = 'splash';
    logoTaps = 0;
    navTab = 'home';
    _persist(); // 기본값을 즉시 기록 (프로토타입 removeItem→reload→mount 저장과 동일 결과)
    notifyListeners();
  }

  // ===== 영속 상태 갱신 =====
  void setPreset(Preset p) {
    preset = p;
    _persist();
    notifyListeners();
  }

  void setRuntime(Runtime r) {
    runtime = r;
    _persist();
    notifyListeners();
  }

  // ===== 사후확인 내비게이션 =====
  void goWeeks(String subjectId) {
    histSubject = subjectId;
    screen = 'weeks';
    notifyListeners();
  }

  void goDetail(WeekDetail d) {
    detail = d;
    screen = 'detail';
    notifyListeners();
  }

  // ===== 교수 세션 =====
  /// 출석 시작 — 전원 미처리 로스터로 시뮬 세션 시작.
  void startProf(int accept) {
    prof = buildRoster();
    profAccept = accept;
    profStartedAt = nowMs();
    screen = 'profDash';
    notifyListeners();
  }

  void setProf(List<RosterStudent> list) {
    prof = list;
    notifyListeners();
  }

  void goEdit(RosterStudent s) {
    editTarget = s;
    screen = 'profEdit';
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
