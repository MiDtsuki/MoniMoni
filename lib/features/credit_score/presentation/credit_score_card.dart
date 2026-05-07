import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';

class CreditScoreCard extends StatelessWidget {
  const CreditScoreCard({required this.score, this.compact = false, super.key});

  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalizedScore = score.clamp(0, 100);
    final accent = creditScoreColor(normalizedScore);
    final progress = normalizedScore / 100;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: progress),
      builder: (context, animatedProgress, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(Colors.white, accent, 0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Color.lerp(MoniTheme.line, accent, 0.7)!),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.13),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: compact ? 20 : 24,
                      backgroundColor: accent.withValues(alpha: 0.14),
                      child: Icon(
                        LucideIcons.gauge,
                        color: accent,
                        size: compact ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Credit score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '$normalizedScore',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: accent),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: compact ? 9 : 11,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: accent.withValues(alpha: 0.14)),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: animatedProgress,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(accent, Colors.white, 0.08)!,
                                  accent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Color creditScoreColor(int score) {
  final clamped = score.clamp(0, 100);
  const red = Color(0xFFC74D4D);
  const yellow = Color(0xFFE5B844);
  const green = MoniTheme.primaryGreen;

  if (clamped <= 50) {
    return Color.lerp(red, yellow, clamped / 50)!;
  }
  return Color.lerp(yellow, green, (clamped - 50) / 50)!;
}
