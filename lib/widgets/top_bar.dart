/// 상단바 — 좌상단 타이틀 5탭(1.2초 내) 시 디버그 진입(§3.1). 뒤로/우측 슬롯 지원.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/store.dart';
import '../theme/colors.dart';

class TopBar extends StatefulWidget {
  final String title;
  final VoidCallback? onBack;
  final String? right;
  const TopBar({super.key, required this.title, this.onBack, this.right});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  int _taps = 0;
  Timer? _timer;

  void _hit() {
    _taps++;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1200), () => _taps = 0);
    if (_taps >= 5) {
      _taps = 0;
      _timer?.cancel();
      context.read<AppStore>().enterDebug();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          if (widget.onBack != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onBack,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_back_ios_new,
                    size: 20, color: AppColors.ink),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _hit,
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),
          if (widget.right != null)
            Text(
              widget.right!,
              style: const TextStyle(fontSize: 13, color: AppColors.mut),
            ),
        ],
      ),
    );
  }
}
