import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../../credit_score/presentation/credit_score_card.dart';
import '../application/debt_controller.dart';
import '../application/friends_controller.dart';
import '../domain/debt_model.dart';
import 'widgets/debt_tile.dart';

class DebtDetailPage extends ConsumerStatefulWidget {
  const DebtDetailPage({required this.friendId, super.key});

  final String friendId;

  @override
  ConsumerState<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends ConsumerState<DebtDetailPage> {
  bool _settling = false;
  bool _settleAllSent = false;
  final Set<String> _settlingDebtIds = {};
  final Set<String> _sentSettlementDebtIds = {};

  Future<void> _settleAll(String friendId) async {
    setState(() => _settling = true);
    try {
      await ref
          .read(debtControllerProvider.notifier)
          .createSettleAllRequest(friendId);
      if (mounted) {
        setState(() => _settleAllSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settlement request sent — check your inbox.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  Future<void> _settleOne(String debtId) async {
    setState(() => _settlingDebtIds.add(debtId));
    try {
      await ref
          .read(debtControllerProvider.notifier)
          .createSettlementRequest(debtId);
      if (mounted) {
        setState(() => _sentSettlementDebtIds.add(debtId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settlement request sent — check your inbox.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _settlingDebtIds.remove(debtId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = ref
        .watch(friendsControllerProvider)
        .friends
        .firstWhere((item) => item.id == widget.friendId);
    final debtState = ref.watch(debtControllerProvider);
    final debts = debtsForFriend(debtState, widget.friendId);
    final lent = lentToFriend(debts);
    final borrowed = borrowedFromFriend(debts);
    final net = lent - borrowed;
    final activeDebts = debts.where((d) => d.status == DebtStatus.active);

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
            CreditScoreCard(score: friend.creditScore, compact: true),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth > 760
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(label: 'Lent to friend', value: lent, width: width),
                    _MetricCard(label: 'Borrowed from friend', value: borrowed, width: width),
                    _MetricCard(label: 'Final net amount', value: net, width: width),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: activeDebts.isEmpty || _settling || _settleAllSent
                    ? null
                    : () => _settleAll(widget.friendId),
                child: _settling
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_settleAllSent ? 'Request sent' : 'Settle All'),
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
                      settling: _settlingDebtIds.contains(debt.id),
                      onSettle: _sentSettlementDebtIds.contains(debt.id) || _settleAllSent
                          ? null
                          : () => _settleOne(debt.id),
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
