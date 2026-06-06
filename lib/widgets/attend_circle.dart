/// 중앙 원 — 핵심 UI 불변 원칙(§8.6): 항상 같은 위치·같은 크기(200),
/// 색과 텍스트만 바뀐다. 로딩은 링만 회전하고 글씨는 정지.
library;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class AttendCircle extends StatefulWidget {
  final String state; // idle | load | green | yellow | red | block
  final String title;
  final String? sub;
  final VoidCallback? onTap;
  const AttendCircle({
    super.key,
    required this.state,
    required this.title,
    this.sub,
    this.onTap,
  });

  @override
  State<AttendCircle> createState() => _AttendCircleState();
}

class _AttendCircleState extends State<AttendCircle> {
  static const double _size = 200;
  bool _down = false;

  (Color bg, Color fg, Color border) _colors(String s) {
    switch (s) {
      case 'green':
        return (AppColors.green, Colors.white, AppColors.green);
      case 'yellow':
        return (AppColors.yellow, AppColors.onYellow, AppColors.yellow);
      case 'red':
        return (AppColors.red, Colors.white, AppColors.red);
      case 'block':
        return (AppColors.block, Colors.white, AppColors.blockBorder);
      case 'idle':
      default:
        return (AppColors.blue, Colors.white, AppColors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoad = widget.state == 'load';
    Widget content;

    if (isLoad) {
      content = SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 흰 원 바탕
            Container(
              width: _size,
              height: _size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            // 회전하는 링 (트랙 회색 + 파란 호)
            const SizedBox(
              width: _size,
              height: _size,
              child: CircularProgressIndicator(
                strokeWidth: 9,
                color: AppColors.blue,
                backgroundColor: AppColors.loadTrack,
              ),
            ),
            // 정지 텍스트
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final (bg, fg, border) = _colors(widget.state);
      content = AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: border, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: fg,
              ),
            ),
            if (widget.sub != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  widget.sub!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.92),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final tappable = widget.onTap != null;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: tappable ? (_) => setState(() => _down = true) : null,
      onTapUp: tappable ? (_) => setState(() => _down = false) : null,
      onTapCancel: tappable ? () => setState(() => _down = false) : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 80),
        child: content,
      ),
    );
  }
}
