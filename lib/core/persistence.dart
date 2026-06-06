/// 영속 저장 — shared_preferences 에 {preset, runtime} JSON 1키 저장.
/// 프로토타입의 localStorage(key 'eatt_proto_v1')와 1:1 대응(§3.4 / §12).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class Persistence {
  final SharedPreferences _prefs;
  Persistence(this._prefs);

  static Future<Persistence> create() async {
    final prefs = await SharedPreferences.getInstance();
    return Persistence(prefs);
  }

  /// 저장된 {preset, runtime} 로드. 없거나 손상되면 null.
  Map<String, dynamic>? load() {
    final s = _prefs.getString(kStorageKey);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    await _prefs.setString(kStorageKey, jsonEncode(data));
  }

  /// 전체 초기화(저장 삭제) — 운영자 디버그 전용.
  Future<void> clear() async {
    await _prefs.remove(kStorageKey);
  }
}
