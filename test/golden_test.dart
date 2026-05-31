import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moni/app/theme.dart';
import 'package:moni/core/widgets/empty_state.dart';
import 'package:moni/core/widgets/moni_card.dart';
import 'package:moni/core/widgets/section_header.dart';
import 'package:moni/features/credit_score/presentation/credit_score_card.dart';
import 'package:moni/features/debts/domain/debt_model.dart';
import 'package:moni/features/debts/presentation/widgets/debt_tile.dart';
import 'package:moni/features/profile/application/profile_settings_controller.dart';
import 'package:moni/features/transactions/domain/transaction_model.dart';
import 'package:moni/features/transactions/presentation/widgets/transaction_tile.dart';

// Wraps a widget in MaterialApp with the Moni theme and a padded scaffold.
Widget _wrap(Widget child) => MaterialApp(
  theme: MoniTheme.light,
  home: Scaffold(
    backgroundColor: MoniTheme.background,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Align(alignment: Alignment.topCenter, child: child),
    ),
  ),
);

// Same as _wrap but includes a ProviderScope that stubs currencySymbolProvider
// so Riverpod ConsumerWidgets don't need Firebase.
Widget _wrapProviders(Widget child) => ProviderScope(
  overrides: [currencySymbolProvider.overrideWithValue('฿')],
  child: _wrap(child),
);

void main() {
  // ── MoniCard ───────────────────────────────────────────────────────────────

  testWidgets('moni_card', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MoniCard(
          child: Text('Card content goes here'),
        ),
      ),
    );
    // Advance past the 220 ms scale animation.
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MoniCard),
      matchesGoldenFile('goldens/moni_card.png'),
    );
  });

  // ── EmptyState ─────────────────────────────────────────────────────────────

  testWidgets('empty_state_no_action', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EmptyState(
          title: 'Nothing here yet',
          message: 'Add your first transaction to get started.',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(EmptyState),
      matchesGoldenFile('goldens/empty_state_no_action.png'),
    );
  });

  testWidgets('empty_state_with_action', (tester) async {
    await tester.pumpWidget(
      _wrap(
        EmptyState(
          title: 'No friends yet',
          message: 'Search for people to add as friends.',
          action: ElevatedButton(
            onPressed: () {},
            child: const Text('Add Friend'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(EmptyState),
      matchesGoldenFile('goldens/empty_state_with_action.png'),
    );
  });

  // ── SectionHeader ──────────────────────────────────────────────────────────

  testWidgets('section_header_no_trailing', (tester) async {
    await tester.pumpWidget(
      _wrap(const SectionHeader(title: 'Recent Transactions')),
    );
    await expectLater(
      find.byType(SectionHeader),
      matchesGoldenFile('goldens/section_header_no_trailing.png'),
    );
  });

  testWidgets('section_header_with_trailing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SectionHeader(
          title: 'Recent Transactions',
          trailing: Icon(Icons.more_horiz),
        ),
      ),
    );
    await expectLater(
      find.byType(SectionHeader),
      matchesGoldenFile('goldens/section_header_with_trailing.png'),
    );
  });

  // ── CreditScoreCard ────────────────────────────────────────────────────────
  // CreditScoreCard has a repeating pulse animation, so we use pump() with a
  // fixed duration instead of pumpAndSettle() which would time out.

  testWidgets('credit_score_card_excellent', (tester) async {
    await tester.pumpWidget(_wrap(const CreditScoreCard(score: 95)));
    // Wait for the 1400 ms ring fill animation to complete.
    await tester.pump(const Duration(milliseconds: 1500));
    await expectLater(
      find.byType(CreditScoreCard),
      matchesGoldenFile('goldens/credit_score_card_excellent.png'),
    );
  });

  testWidgets('credit_score_card_good', (tester) async {
    await tester.pumpWidget(_wrap(const CreditScoreCard(score: 75)));
    await tester.pump(const Duration(milliseconds: 1500));
    await expectLater(
      find.byType(CreditScoreCard),
      matchesGoldenFile('goldens/credit_score_card_good.png'),
    );
  });

  testWidgets('credit_score_card_warning', (tester) async {
    await tester.pumpWidget(_wrap(const CreditScoreCard(score: 62)));
    await tester.pump(const Duration(milliseconds: 1500));
    await expectLater(
      find.byType(CreditScoreCard),
      matchesGoldenFile('goldens/credit_score_card_warning.png'),
    );
  });

  testWidgets('credit_score_card_restricted', (tester) async {
    await tester.pumpWidget(_wrap(const CreditScoreCard(score: 35)));
    await tester.pump(const Duration(milliseconds: 1500));
    await expectLater(
      find.byType(CreditScoreCard),
      matchesGoldenFile('goldens/credit_score_card_restricted.png'),
    );
  });

  // ── TransactionTile ────────────────────────────────────────────────────────

  testWidgets('transaction_tile_income', (tester) async {
    final tx = TransactionModel(
      id: 'tx1',
      category: 'Salary',
      account: 'Bank Account',
      amount: 50000.0,
      type: TransactionType.income,
      date: DateTime(2024, 1, 15, 14, 30),
    );
    await tester.pumpWidget(_wrapProviders(TransactionTile(transaction: tx)));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(TransactionTile),
      matchesGoldenFile('goldens/transaction_tile_income.png'),
    );
  });

  testWidgets('transaction_tile_expense_with_note', (tester) async {
    final tx = TransactionModel(
      id: 'tx2',
      category: 'Food & Drinks',
      account: 'Cash',
      amount: 350.0,
      type: TransactionType.expense,
      date: DateTime(2024, 1, 15, 12, 0),
      note: 'Lunch at the office with the team',
    );
    await tester.pumpWidget(_wrapProviders(TransactionTile(transaction: tx)));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(TransactionTile),
      matchesGoldenFile('goldens/transaction_tile_expense_with_note.png'),
    );
  });

  // ── DebtTransactionCard ────────────────────────────────────────────────────

  testWidgets('debt_tile_lend_active', (tester) async {
    final debt = DebtModel(
      id: 'debt1',
      friendId: 'friend123',
      amount: 1500.0,
      direction: DebtDirection.owedToMe,
      status: DebtStatus.active,
      createdAt: DateTime(2024, 1, 10),
      deadline: DateTime(2024, 2, 10),
      note: 'Borrowed for trip expenses',
    );
    await tester.pumpWidget(
      _wrapProviders(DebtTransactionCard(debt: debt)),
    );
    await expectLater(
      find.byType(DebtTransactionCard),
      matchesGoldenFile('goldens/debt_tile_lend_active.png'),
    );
  });

  testWidgets('debt_tile_borrow_pending', (tester) async {
    final debt = DebtModel(
      id: 'debt2',
      friendId: 'friend456',
      amount: 800.0,
      direction: DebtDirection.iOwe,
      status: DebtStatus.pending,
      createdAt: DateTime(2024, 1, 5),
    );
    await tester.pumpWidget(
      _wrapProviders(DebtTransactionCard(debt: debt)),
    );
    await expectLater(
      find.byType(DebtTransactionCard),
      matchesGoldenFile('goldens/debt_tile_borrow_pending.png'),
    );
  });

  testWidgets('debt_tile_borrow_settled', (tester) async {
    final debt = DebtModel(
      id: 'debt3',
      friendId: 'friend789',
      amount: 200.0,
      direction: DebtDirection.iOwe,
      status: DebtStatus.settled,
      createdAt: DateTime(2024, 1, 1),
      settledAt: DateTime(2024, 1, 20),
    );
    await tester.pumpWidget(
      _wrapProviders(DebtTransactionCard(debt: debt)),
    );
    await expectLater(
      find.byType(DebtTransactionCard),
      matchesGoldenFile('goldens/debt_tile_borrow_settled.png'),
    );
  });
}
