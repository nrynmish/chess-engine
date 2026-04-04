import 'package:flutter/material.dart';

/// Evaluation bar — safe with any parent constraints.
///
/// [evaluation]   : float, positive = white advantage (e.g. +3.2, -1.5)
/// [isHorizontal] : true on mobile (renders left-white / right-black)
///                  false on tablet/desktop (renders top-black / bottom-white)
class EvaluationBar extends StatelessWidget {
  final double evaluation;
  final bool isHorizontal;

  const EvaluationBar({
    super.key,
    required this.evaluation,
    this.isHorizontal = false,
  });

  /// 0.0 = full black advantage, 1.0 = full white advantage
  double get _whiteFraction {
    final clamped = evaluation.clamp(-10.0, 10.0);
    return (clamped + 10.0) / 20.0;
  }

  String get _evalLabel {
    final abs = evaluation.abs();
    if (abs >= 100) return '#';
    if (abs < 0.05) return '0.0';
    return (evaluation > 0 ? '+' : '') + evaluation.toStringAsFixed(1);
  }

  Color _advantageColor(bool isDark) {
    final e = evaluation;
    if (e > 3.0) return const Color(0xFF22C55E);
    if (e > 0.5) return const Color(0xFF86EFAC);
    if (e < -3.0) return const Color(0xFFEF4444);
    if (e < -0.5) return const Color(0xFFFCA5A5);
    return isDark ? Colors.white38 : Colors.black38;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _advantageColor(isDark);

    return isHorizontal
        ? _HorizontalEvalBar(
            whiteFraction: _whiteFraction,
            evalLabel: _evalLabel,
            advantageColor: color,
            isDark: isDark,
          )
        : _VerticalEvalBar(
            whiteFraction: _whiteFraction,
            evalLabel: _evalLabel,
            advantageColor: color,
            isDark: isDark,
          );
  }
}

// ─────────────────────────────────────────────
// VERTICAL  (tablet / desktop)
// Uses LayoutBuilder so it never needs Expanded or unbounded height.
// ─────────────────────────────────────────────

class _VerticalEvalBar extends StatelessWidget {
  final double whiteFraction;
  final String evalLabel;
  final Color advantageColor;
  final bool isDark;

  const _VerticalEvalBar({
    required this.whiteFraction,
    required this.evalLabel,
    required this.advantageColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Fall back to 200 if parent gives us unbounded height
      final totalH = constraints.maxHeight.isInfinite ? 200.0 : constraints.maxHeight;
      final totalW = constraints.maxWidth.isInfinite ? 36.0 : constraints.maxWidth;

      const labelH = 20.0;
      final usableH = totalH - labelH;
      final blackH = (usableH * (1 - whiteFraction)).clamp(0.0, totalH);
      final whiteH = (usableH * whiteFraction).clamp(0.0, totalH);
      final labelTop = blackH.clamp(0.0, totalH - labelH);

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: totalW,
          height: totalH,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              // Black fill (top)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: blackH,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF141414), Color(0xFF2A2A2A)],
                    ),
                  ),
                ),
              ),

              // White fill (bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: whiteH,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE4E4E4), Color(0xFFF8F8F8)],
                    ),
                  ),
                ),
              ),

              // Score label pill (slides with evaluation)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                top: labelTop,
                left: 0,
                right: 0,
                height: labelH,
                child: _ScorePill(
                  label: evalLabel,
                  color: advantageColor,
                  isDark: isDark,
                  horizontal: false,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// HORIZONTAL  (mobile)
// ─────────────────────────────────────────────

class _HorizontalEvalBar extends StatelessWidget {
  final double whiteFraction;
  final String evalLabel;
  final Color advantageColor;
  final bool isDark;

  const _HorizontalEvalBar({
    required this.whiteFraction,
    required this.evalLabel,
    required this.advantageColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalW = constraints.maxWidth.isInfinite ? 300.0 : constraints.maxWidth;
      // Height is fixed — we always wrap this in a SizedBox on mobile
      const totalH = 36.0;
      const labelW = 40.0;

      final usableW = totalW - labelW;
      final whiteW = (usableW * whiteFraction).clamp(0.0, totalW);
      final blackW = (usableW * (1 - whiteFraction)).clamp(0.0, totalW);
      final labelLeft = whiteW.clamp(0.0, totalW - labelW);

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: totalW,
          height: totalH,
          child: Stack(
            children: [
              // White fill (left)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: whiteW,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF8F8F8), Color(0xFFE4E4E4)],
                    ),
                  ),
                ),
              ),

              // Black fill (right)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: blackW,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2A2A2A), Color(0xFF141414)],
                    ),
                  ),
                ),
              ),

              // Score pill (slides horizontally)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                top: 0,
                bottom: 0,
                left: labelLeft,
                width: labelW,
                child: _ScorePill(
                  label: evalLabel,
                  color: advantageColor,
                  isDark: isDark,
                  horizontal: true,
                ),
              ),

              // Border drawn on top so it's always crisp
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// SCORE PILL
// ─────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final bool horizontal;

  const _ScorePill({
    required this.label,
    required this.color,
    required this.isDark,
    required this.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        border: horizontal
            ? Border(
                left: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                right: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              )
            : Border(
                top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              ),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: color,
          fontFamily: 'monospace',
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
