import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';

class CreditScoreCard extends StatefulWidget {
  const CreditScoreCard({required this.score, this.compact = false, super.key});

  final int score;
  final bool compact;

  @override
  State<CreditScoreCard> createState() => _CreditScoreCardState();
}

class _CreditScoreCardState extends State<CreditScoreCard>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final AnimationController _pulseCtrl;
  late Animation<double> _ringAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _ringAnim = Tween<double>(
      begin: 0,
      end: widget.score.clamp(0, 100) / 100.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic));

    _pulseAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _ringCtrl.forward();
  }

  @override
  void didUpdateWidget(CreditScoreCard old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _ringAnim = Tween<double>(
        begin: _ringAnim.value,
        end: widget.score.clamp(0, 100) / 100.0,
      ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic));
      _ringCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _accent(int score) {
    if (score >= 90) return MoniTheme.primaryGreen;
    if (score >= 70) return const Color(0xFF4CAF7D);
    if (score >= 60) return const Color(0xFFE5973A);
    return const Color(0xFFC74D4D);
  }

  String _tier(int score) {
    if (score >= 90) return 'EXCELLENT';
    if (score >= 70) return 'GOOD';
    if (score >= 60) return 'WARNING';
    return 'RESTRICTED';
  }

  void _showPerks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score Perks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text('How to earn and lose credit score points.'),
              const SizedBox(height: 20),
              _PerkSection(
                label: 'Rewards',
                icon: LucideIcons.trendingUp,
                color: MoniTheme.primaryGreen,
              ),
              const SizedBox(height: 10),
              _PerkRow(
                label: 'Settle debt before deadline',
                value: '+3 pts',
                color: MoniTheme.primaryGreen,
              ),
              _PerkRow(
                label: 'Complete debt on time',
                value: '+1 pt',
                color: MoniTheme.primaryGreen,
              ),
              _PerkRow(
                label: 'No violations for 7 days',
                value: '+10 pts',
                color: MoniTheme.primaryGreen,
              ),
              const SizedBox(height: 18),
              _PerkSection(
                label: 'Penalties',
                icon: LucideIcons.trendingDown,
                color: const Color(0xFFC74D4D),
              ),
              const SizedBox(height: 10),
              _PerkRow(
                label: 'Missed debt deadline',
                value: '−5 pts',
                color: const Color(0xFFC74D4D),
              ),
              _PerkRow(
                label: 'Each overdue day',
                value: '−1 pt/day',
                color: const Color(0xFFC74D4D),
              ),
              const SizedBox(height: 18),
              _PerkSection(
                label: 'Access Levels',
                icon: LucideIcons.shieldCheck,
                color: MoniTheme.muted,
              ),
              const SizedBox(height: 10),
              _AccessRow(
                range: '90 – 100',
                label: 'All features unlocked',
                color: MoniTheme.primaryGreen,
              ),
              _AccessRow(
                range: '70 – 89',
                label: 'Normal access',
                color: const Color(0xFF4CAF7D),
              ),
              _AccessRow(
                range: '60 – 69',
                label: 'Warning state',
                color: const Color(0xFFE5973A),
              ),
              _AccessRow(
                range: '0 – 59',
                label: 'Debt creation restricted',
                color: const Color(0xFFC74D4D),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.score.clamp(0, 100);
    final accent = _accent(score);
    final tier = _tier(score);
    final violationRate = ((100 - score) * 0.3).round();
    final dailyRecovery = score >= 90
        ? '+3 pts'
        : score >= 70
        ? '+2 pts'
        : '+1 pt';

    return AnimatedBuilder(
      animation: Listenable.merge([_ringAnim, _pulseAnim]),
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: MoniTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Color.lerp(MoniTheme.line, accent, 0.45)!),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.07 + 0.05 * _pulseAnim.value),
              blurRadius: 18 + 6 * _pulseAnim.value,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ScoreRing(
                progress: _ringAnim.value,
                pulse: _pulseAnim.value,
                score: score,
                accent: accent,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.gauge, color: accent, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          'CREDIT SCORE',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        tier,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StatLine(
                      label: 'Violation Rate',
                      value: '$violationRate%',
                      accent: accent,
                    ),
                    const SizedBox(height: 6),
                    _StatLine(
                      label: 'Daily Recovery',
                      value: dailyRecovery,
                      accent: accent,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _PerksButton(
                          accent: accent,
                          onTap: () => _showPerks(context),
                        ),
                        const SizedBox(width: 8),
                        _HistoryBtn(accent: accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ring ─────────────────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.progress,
    required this.pulse,
    required this.score,
    required this.accent,
  });

  final double progress;
  final double pulse;
  final int score;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 78 + 5 * pulse,
            height: 78 + 5 * pulse,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14 * pulse),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(110, 110),
            painter: _RingPainter(progress: progress, accent: accent),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: MoniTheme.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  shadows: [
                    Shadow(color: accent.withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  color: accent.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = -math.pi / 2;
    const strokeWidth = 10.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi,
      false,
      Paint()
        ..color = MoniTheme.softGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Soft glow
    canvas.drawArc(
      rect,
      startAngle,
      sweep,
      false,
      Paint()
        ..color = accent.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main arc
    canvas.drawArc(
      rect,
      startAngle,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + 2 * math.pi,
          colors: [accent.withValues(alpha: 0.4), accent],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.accent != accent;
}

// ── Stat line ─────────────────────────────────────────────────────────────────

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: MoniTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _PerksButton extends StatelessWidget {
  const _PerksButton({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.gift, size: 11, color: accent),
            const SizedBox(width: 4),
            Text(
              'Perks',
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryBtn extends StatelessWidget {
  const _HistoryBtn({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Icon(LucideIcons.history, size: 13, color: accent),
      ),
    );
  }
}

// ── Perks sheet helpers ───────────────────────────────────────────────────────

class _PerkSection extends StatelessWidget {
  const _PerkSection({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: MoniTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.range,
    required this.label,
    required this.color,
  });

  final String range;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: MoniTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Color creditScoreColor(int score) {
  final clamped = score.clamp(0, 100);
  const low = Color(0xFFC74D4D);
  const mid = Color(0xFFE5973A);
  const high = MoniTheme.primaryGreen;
  if (clamped <= 60) return Color.lerp(low, mid, clamped / 60)!;
  return Color.lerp(mid, high, (clamped - 60) / 40)!;
}
