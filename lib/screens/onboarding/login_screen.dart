/// S01 — 로그인. 스플래시 3초 후 노출. 프리셋 계정 자동 입력, ID 범위로 역할 분기(§2).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/store.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _id;
  late final TextEditingController _pw;

  @override
  void initState() {
    super.initState();
    final preset = context.read<AppStore>().preset;
    final acc = preset.persona == 'prof' ? kProfAcc : kStudentAcc;
    _id = TextEditingController(text: acc.id);
    _pw = TextEditingController(text: acc.pw);
  }

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isProf = store.preset.persona == 'prof';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TopBar(title: '로그인'),
        const Spacer(),
        Center(
          child: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ink, width: 1.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Text('로고',
                    style: TextStyle(fontSize: 12, color: AppColors.mut)),
              ),
              const SizedBox(height: 10),
              const Text('전자출결',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const Spacer(flex: 2),
        _field('학번 / 사번', _id),
        _field('비밀번호', _pw, obscure: true),
        const SizedBox(height: 4),
        AppButton('로그인', onTap: () => context.read<AppStore>().login()),
        const SizedBox(height: 8),
        Center(
          child: Text('프리셋 계정 자동 입력 · ${isProf ? '교수' : '학생'}',
              style: const TextStyle(fontSize: 11, color: AppColors.mut)),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _field(String label, TextEditingController c, {bool obscure = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.fieldBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Lbl(label),
          TextField(
            controller: c,
            obscureText: obscure,
            style: const TextStyle(fontSize: 15, color: AppColors.ink),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
