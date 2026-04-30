import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../application/debt_controller.dart';
import '../application/friends_controller.dart';
import '../domain/debt_model.dart';
import 'widgets/debt_tile.dart';

class DebtDetailPage extends ConsumerWidget {
  const DebtDetailPage({required this.friendId, super.key});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friend = ref
        .watch(friendsControllerProvider)
        .friends
        .firstWhere((item) => item.id == friendId);
    final debtState = ref.watch(debtControllerProvider);
    final debts = debtsForFriend(debtState, friendId);
    final lent = lentToFriend(debts);
    final borrowed = borrowedFromFriend(debts);
    final net = lent - borrowed;
    final activeDebts = debts.where((debt) => debt.status == DebtStatus.active);

    return Scaffold(
      body: AppPage(
        title: friend.name,
        subtitle: friend.username,
        action: TextButton(
          onPressed: () => context.go('/debts'),
          child: const Text('Close'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth > 760
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      label: 'Lent to friend',
                      value: lent,
                      width: width,
                    ),
                    _MetricCard(
                      label: 'Borrowed from friend',
                      value: borrowed,
                      width: width,
                    ),
                    _MetricCard(
                      label: 'Final net amount',
                      value: net,
                      width: width,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: activeDebts.isEmpty
                    ? null
                    : () {
                        ref
                            .read(debtControllerProvider.notifier)
                            .createSettleAllRequest(friendId);
                        context.go('/profile/inbox');
                      },
                child: const Text('Settle All'),
              ),
            ),
            const SizedBox(height: 24),
            Text('History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (debts.isEmpty)
              const EmptyState(
                title: 'No history yet',
                message:
                    'Borrow or lend money with this friend to build a shared history.',
                icon: LucideIcons.handCoins,
              )
            else
              Column(
                children: [
                  for (final debt in debts) ...[
                    DebtTransactionCard(
                      debt: debt,
                      onSettle: () {
                        ref
                            .read(debtControllerProvider.notifier)
                            .createSettlementRequest(debt.id);
                        context.go('/profile/inbox');
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final double value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: MoniCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.compact(value),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
