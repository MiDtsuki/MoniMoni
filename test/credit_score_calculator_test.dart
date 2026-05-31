import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moni/app/theme.dart';
import 'package:moni/features/credit_score/domain/credit_score_calculator.dart';
import 'package:moni/features/credit_score/presentation/credit_score_card.dart';
import 'package:moni/features/debts/domain/friend_model.dart';
import 'package:moni/features/profile/application/profile_settings_controller.dart';

void main() {
  group('CreditScoreCalculator', () {
    test('clamps score between 0 and 100', () {
      expect(CreditScoreCalculator.clamp(120), 100);
      expect(CreditScoreCalculator.clamp(-12), 0);
      expect(CreditScoreCalculator.clamp(62), 62);
    });

    test('treats date-only deadline as end-of-day UTC', () {
      final deadline = DateTime.utc(2026, 5, 7);

      expect(
        CreditScoreCalculator.isOverdue(
          deadline: deadline,
          now: DateTime.utc(2026, 5, 7, 23, 59),
        ),
        isFalse,
      );
      expect(
        CreditScoreCalculator.isOverdue(
          deadline: deadline,
          now: DateTime.utc(2026, 5, 8),
        ),
        isTrue,
      );
    });

    test('applies missed deadline penalty once before daily penalties', () {
      final deadline = DateTime.utc(2026, 5, 7);

      expect(
        CreditScoreCalculator.overduePenalty(
          deadline: deadline,
          now: DateTime.utc(2026, 5, 8),
        ),
        -5,
      );
      expect(
        CreditScoreCalculator.overduePenalty(
          deadline: deadline,
          now: DateTime.utc(2026, 5, 8, 23, 59),
        ),
        -5,
      );
    });

    test('deducts one point for each full unpaid day after deadline', () {
      final deadline = DateTime.utc(2026, 5, 7);

      expect(
        CreditScoreCalculator.fullUnpaidDaysAfterDeadline(
          deadline: deadline,
          now: DateTime.utc(2026, 5, 9),
        ),
        1,
      );
      expect(
        CreditScoreCalculator.overduePenalty(
          deadline: deadline,
          now: DateTime.utc(2026, 5, 11, 12),
        ),
        -8,
      );
    });

    test('rewards settlement before deadline end and caps at 100', () {
      final deadline = DateTime.utc(2026, 5, 7);

      expect(
        CreditScoreCalculator.isOnTimeSettlement(
          deadline: deadline,
          settledAt: DateTime.utc(2026, 5, 7, 15),
        ),
        isTrue,
      );
      expect(
        CreditScoreCalculator.applyDelta(
          99,
          CreditScoreCalculator.onTimeSettlementReward,
        ),
        100,
      );
    });
  });

  group('credit score models', () {
    test('profile settings default to 100', () {
      const settings = ProfileSettings(currency: defaultCurrency);

      expect(settings.creditScore, 100);
    });

    test('friend model reads public profile json', () {
      final friend = FriendModel.fromMap('friend-1', {
        'display_name': 'Mia',
        'username': 'mia',
      });

      expect(friend.name, 'Mia');
      expect(friend.username, 'mia');
    });
  });

  group('credit score UI color', () {
    test('maps score range to red, yellow, and green', () {
      expect(creditScoreColor(0), const Color(0xFFC74D4D));
      expect(
        creditScoreColor(50),
        Color.lerp(const Color(0xFFC74D4D), const Color(0xFFE5973A), 50 / 60),
      );
      expect(creditScoreColor(100), MoniTheme.primaryGreen);
    });

    testWidgets('renders clamped score and compact label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditScoreCard(score: 140))),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('CREDIT SCORE'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });
  });
}
