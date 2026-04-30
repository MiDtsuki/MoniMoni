import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../../debts/application/debt_controller.dart';
import '../../debts/application/friends_controller.dart';
import '../../debts/domain/friend_model.dart';
import '../../transactions/application/transaction_controller.dart';
import '../application/notification_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpense = ref.watch(monthlyExpenseProvider);
    final monthlyBalance = ref.watch(monthlyBalanceProvider);
    final totalLent = ref.watch(totalLentProvider);
    final totalBorrowed = ref.watch(totalBorrowedProvider);
    final debtNet = ref.watch(netDebtProvider);
    final notificationCount = ref.watch(pendingNotificationCountProvider);
    final finalSummary = monthlyIncome - monthlyExpense + debtNet;

    return AppPage(
      title: 'Profile',
      subtitle: 'Financial dashboard for this month.',
      action: IconButton.filledTonal(
        onPressed: () => context.go('/profile/inbox'),
        icon: notificationCount == 0
            ? const Icon(LucideIcons.bell)
            : Badge.count(
                count: notificationCount,
                child: const Icon(LucideIcons.bell),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserHeader(notificationCount: notificationCount),
          const SizedBox(height: 16),
          _FinalSummaryCard(value: finalSummary),
          const SizedBox(height: 16),
          _DashboardGrid(
            cards: [
              _DashboardMetric(
                label: 'Current month income',
                value: monthlyIncome,
                icon: LucideIcons.arrowDownLeft,
              ),
              _DashboardMetric(
                label: 'Current month expenses',
                value: monthlyExpense,
                icon: LucideIcons.arrowUpRight,
              ),
              _DashboardMetric(
                label: 'Current month balance',
                value: monthlyBalance,
                icon: LucideIcons.wallet,
              ),
              _DashboardMetric(
                label: 'Total lent',
                value: totalLent,
                icon: LucideIcons.handCoins,
              ),
              _DashboardMetric(
                label: 'Total borrowed',
                value: totalBorrowed,
                icon: LucideIcons.banknoteArrowDown,
              ),
              _DashboardMetric(
                label: 'True debt net total',
                value: debtNet,
                icon: LucideIcons.scale,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _AddFriendSection(),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.notificationCount});

  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return MoniCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: MoniTheme.softGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              LucideIcons.userRound,
              size: 34,
              color: MoniTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alex Morgan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text('@alex'),
              ],
            ),
          ),
          if (notificationCount > 0)
            DecoratedBox(
              decoration: BoxDecoration(
                color: MoniTheme.softGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  '$notificationCount pending',
                  style: const TextStyle(
                    color: MoniTheme.primaryGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FinalSummaryCard extends StatelessWidget {
  const _FinalSummaryCard({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return MoniCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: MoniTheme.softGreen,
            child: Icon(
              LucideIcons.chartNoAxesColumn,
              color: MoniTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall financial summary'),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.compact(value),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                const Text('Income - expenses + debt net'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.cards});

  final List<_DashboardMetric> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 620
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _MetricCard(metric: card),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return MoniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: MoniTheme.primaryGreen),
          const SizedBox(height: 12),
          Text(metric.label),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.compact(metric.value),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _AddFriendSection extends ConsumerStatefulWidget {
  const _AddFriendSection();

  @override
  ConsumerState<_AddFriendSection> createState() => _AddFriendSectionState();
}

class _AddFriendSectionState extends ConsumerState<_AddFriendSection> {
  final _controller = TextEditingController();
  var _results = <FriendModel>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MoniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add friend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            'Search a mock user by username and send a friend request.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: '@sofia',
              prefixIcon: Icon(LucideIcons.search),
            ),
            onChanged: (value) {
              setState(() {
                _results = ref
                    .read(friendsControllerProvider.notifier)
                    .searchUsers(value);
              });
            },
          ),
          const SizedBox(height: 12),
          if (_controller.text.isNotEmpty && _results.isEmpty)
            const EmptyState(
              title: 'No users found',
              message: 'Try @sofia, @ethan, or @lina from the mock user list.',
              icon: LucideIcons.search,
            )
          else
            for (final user in _results)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: MoniTheme.softGreen,
                  child: Icon(LucideIcons.userRoundPlus),
                ),
                title: Text(user.name),
                subtitle: Text(user.username),
                trailing: TextButton(
                  onPressed: () {
                    ref
                        .read(friendsControllerProvider.notifier)
                        .sendFriendRequest(user);
                    setState(() {
                      _controller.clear();
                      _results = [];
                    });
                  },
                  child: const Text('Send'),
                ),
              ),
        ],
      ),
    );
  }
}
