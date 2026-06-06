/// 공용 UI 빌딩블록 — 프로토타입 index.html 의 .card/.pill/.seg/.btn/.lbl 대응.
library;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 소문자→대문자 라벨 (CSS .lbl)
class Lbl extends StatelessWidget {
  final String text;
  const Lbl(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 0.4,
            color: AppColors.mut,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

/// 카드 (.card / .card.em / .card.dash / .card.warn)
class AppCard extends StatelessWidget {
  final Widget child;
  final bool emphasized; // 2px 검정 테두리
  final bool dashed; // 점선 톤(연한 회색)
  final bool warn; // 노랑 경고
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double opacity;

  const AppCard({
    super.key,
    required this.child,
    this.emphasized = false,
    this.dashed = false,
    this.warn = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.margin,
    this.onTap,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.cardBorder;
    double borderW = 1;
    Color bg = AppColors.paper;
    double radius = 14;
    if (emphasized) {
      border = AppColors.ink;
      borderW = 2;
      radius = 16;
    }
    if (dashed) border = const Color(0xFFBBBBBB);
    if (warn) {
      bg = AppColors.warnBg;
      border = AppColors.warnBorder;
    }
    Widget box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: borderW),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    if (opacity < 1) box = Opacity(opacity: opacity, child: box);
    if (onTap != null) {
      box = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: box,
      );
    }
    if (margin != null) box = Padding(padding: margin!, child: box);
    return box;
  }
}

/// 상태 Pill (.pill att/late/abs/none/err/warn)
class Pill extends StatelessWidget {
  final String kind;
  final String label;
  const Pill(this.kind, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    Color fg = Colors.white;
    switch (kind) {
      case 'att':
        bg = AppColors.green;
        break;
      case 'late':
      case 'warn':
        bg = AppColors.yellow;
        fg = AppColors.onYellow;
        break;
      case 'abs':
      case 'err':
        bg = AppColors.red;
        break;
      case 'none':
      default:
        bg = AppColors.gray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// 세그먼트 토글 (.seg) — 값/라벨은 문자열
class Seg extends StatelessWidget {
  final String value;
  final List<(String value, String label)> options;
  final ValueChanged<String> onChanged;
  const Seg({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.chipBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final on = o.$1 == value;
          return GestureDetector(
            onTap: () => onChanged(o.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              color: on ? AppColors.ink : Colors.transparent,
              child: Text(
                o.$2,
                style: TextStyle(
                  fontSize: 13,
                  color: on ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 칩 (.chip) — 선택 시 검정
class AppChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const AppChip({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.paper,
            border: Border.all(color: on ? AppColors.ink : AppColors.chipBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: on ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      );
}

enum AppBtn { pri, blue, ghost, danger }

/// 버튼 (.btn pri/blue/ghost/danger)
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppBtn kind;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  const AppButton(
    this.label, {
    super.key,
    this.onTap,
    this.kind = AppBtn.pri,
    this.padding = const EdgeInsets.all(14),
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    late Color bg, fg, border;
    switch (kind) {
      case AppBtn.pri:
        bg = AppColors.ink;
        fg = Colors.white;
        border = AppColors.ink;
        break;
      case AppBtn.blue:
        bg = AppColors.blue;
        fg = Colors.white;
        border = AppColors.blue;
        break;
      case AppBtn.danger:
        bg = AppColors.red;
        fg = Colors.white;
        border = AppColors.red;
        break;
      case AppBtn.ghost:
        bg = AppColors.paper;
        fg = AppColors.ink;
        border = AppColors.ink;
        break;
    }
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// 행 사이 분리선 (CSS hr)
class HLine extends StatelessWidget {
  const HLine({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1, thickness: 1, color: AppColors.line),
      );
}
