/// S08 — 인증번호 입력(fallback). 오류 후에만 진입. 고정 7301.
/// 명세 §7.2/§8.6: 포커스 시 기기 기본 숫자 키패드가 즉시 뜨도록 네이티브 키보드 사용.
/// 성공 시 최초 시도 시각 기준으로 출석(S13)/지각(S14) 판정.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/time_utils.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() {});
    if (v.length >= 4) _submit(v);
  }

  void _submit(String v) {
    final store = context.read<AppStore>();
    if (v != kAuthCode) {
      store.showToast('인증번호가 올바르지 않습니다');
      _controller.clear();
      setState(() {});
      _focus.requestFocus();
      return;
    }
    // 최초 시도 시각 기준 판정 (§7.1)
    final firstRem = store.runtime.firstRemMs ?? 0;
    final type = firstRem > 0 ? 'present' : 'late';
    final o = SubjectState(state: type, method: '인증번호', at: fmtClockMs(nowMs()));
    final subjId = subjectById(store.preset.subject).id;
    store.setRuntime(store.runtime.copyWith(
      subjectStates: {...store.runtime.subjectStates, subjId: o},
    ));
    HapticFeedback.mediumImpact();
    store.setScreen('attend');
    store.showToast(type == 'present' ? '출석 처리되었습니다' : '지각 처리되었습니다');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final firstAt = store.runtime.firstAttemptAt;
    final v = _controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(title: '인증번호 출결', onBack: () => store.setScreen('attend')),
        AppCard(
          warn: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('최초 시도 시각',
                      style: TextStyle(fontSize: 13, color: AppColors.mut)),
                  Text(firstAt != null ? fmtClockMs(firstAt) : '—',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const Text('이 시각 기준으로 출석/지각 자동 판정',
                  style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
        const Spacer(),
        const Center(
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13),
              children: [
                TextSpan(text: '교수자가 칠판에 적은 '),
                TextSpan(
                    text: '4자리 인증번호',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: '를 입력하세요.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 14),
        // 4핀 표시 + 그 위에 투명한 네이티브 입력 필드(시스템 키패드)
        Center(
          child: GestureDetector(
            onTap: () => _focus.requestFocus(),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 4 * 46 + 3 * 10,
              height: 56,
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < v.length;
                      return Container(
                        width: 46,
                        height: 56,
                        margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCCCCCC)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          filled ? v[i] : '_',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: filled ? AppColors.ink : const Color(0xFFCCCCCC),
                          ),
                        ),
                      );
                    }),
                  ),
                  // 투명 입력 필드 (시스템 숫자 키패드 유발)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        showCursor: false,
                        enableInteractiveSelection: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onChanged: _onChanged,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('숫자 4자리를 입력하면 자동으로 판정됩니다.',
                style: TextStyle(fontSize: 11, color: AppColors.mut)),
          ),
        ),
      ],
    );
  }
}
