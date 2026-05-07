import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../../credit_score/presentation/credit_score_card.dart';
import '../../debts/application/debt_controller.dart';
import '../../debts/application/friends_controller.dart';
import '../../debts/domain/friend_model.dart';
import '../../transactions/application/transaction_controller.dart';
import '../application/notification_controller.dart';
import '../application/profile_settings_controller.dart';

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
    final settings = ref.watch(profileSettingsProvider);
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
          const _UserHeader(),
          const SizedBox(height: 16),
          CreditScoreCard(score: settings.creditScore),
          const SizedBox(height: 16),
          _FinalSummaryCard(
            value: finalSummary,
            symbol: settings.currency.symbol,
          ),
          const SizedBox(height: 16),
          _CompactSummaryGrid(
            monthlyItems: [
              _SummaryItem(
                label: 'Income',
                value: monthlyIncome,
                icon: LucideIcons.arrowDownLeft,
              ),
              _SummaryItem(
                label: 'Expenses',
                value: monthlyExpense,
                icon: LucideIcons.arrowUpRight,
              ),
              _SummaryItem(
                label: 'Balance',
                value: monthlyBalance,
                icon: LucideIcons.wallet,
              ),
            ],
            debtItems: [
              _SummaryItem(
                label: 'Lent',
                value: totalLent,
                icon: LucideIcons.handCoins,
              ),
              _SummaryItem(
                label: 'Borrowed',
                value: totalBorrowed,
                icon: LucideIcons.banknoteArrowDown,
              ),
              _SummaryItem(
                label: 'Net debt',
                value: debtNet,
                icon: LucideIcons.scale,
              ),
            ],
            symbol: settings.currency.symbol,
          ),
          const SizedBox(height: 18),
          _SettingsSection(currency: settings.currency),
          const SizedBox(height: 18),
          const _AddFriendSection(),
          const SizedBox(height: 18),
          _SignOutButton(),
        ],
      ),
    );
  }
}

class _UserHeader extends ConsumerWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(profileSettingsProvider);
    final displayName = settings.displayName.isNotEmpty
        ? settings.displayName
        : 'Loading…';
    final username = settings.username.isNotEmpty
        ? '@${settings.username}'
        : '';

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
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(username),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) context.go('/login');
        },
        icon: const Icon(LucideIcons.logOut),
        label: const Text('Sign out'),
      ),
    );
  }
}

class _FinalSummaryCard extends StatelessWidget {
  const _FinalSummaryCard({required this.value, required this.symbol});

  final double value;
  final String symbol;

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
                  CurrencyFormatter.withSymbol(value, symbol),
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

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;
}

class _CompactSummaryGrid extends StatelessWidget {
  const _CompactSummaryGrid({
    required this.monthlyItems,
    required this.debtItems,
    required this.symbol,
  });

  final List<_SummaryItem> monthlyItems;
  final List<_SummaryItem> debtItems;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final cardWidth = wide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryGroupCard(
                title: 'This month',
                icon: LucideIcons.calendarDays,
                items: monthlyItems,
                symbol: symbol,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryGroupCard(
                title: 'Debts',
                icon: LucideIcons.handCoins,
                items: debtItems,
                symbol: symbol,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryGroupCard extends StatelessWidget {
  const _SummaryGroupCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.symbol,
  });

  final String title;
  final IconData icon;
  final List<_SummaryItem> items;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return MoniCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: MoniTheme.softGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: MoniTheme.primaryGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            _SummaryRow(item: items[i], symbol: symbol),
            if (i != items.length - 1)
              const Divider(height: 16, color: MoniTheme.line),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.item, required this.symbol});

  final _SummaryItem item;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon, size: 18, color: MoniTheme.primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(
              color: MoniTheme.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            CurrencyFormatter.withSymbol(item.value, symbol),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection({required this.currency});

  final CurrencyOption currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MoniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.settings, color: MoniTheme.primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Configure',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: MoniTheme.softGreen,
              child: Icon(
                LucideIcons.circleDollarSign,
                color: MoniTheme.primaryGreen,
              ),
            ),
            title: const Text('Currency'),
            subtitle: Text('${currency.code} · ${currency.name}'),
            trailing: Text(
              currency.symbol,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            onTap: () => _showCurrencyPicker(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<CurrencyOption>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose currency',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (final option in supportedCurrencies)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: option.code == currency.code
                            ? MoniTheme.softGreen
                            : const Color(0xFFF0F2EF),
                        child: Text(
                          option.symbol,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      title: Text('${option.code} · ${option.name}'),
                      trailing: option.code == currency.code
                          ? const Icon(
                              LucideIcons.check,
                              color: MoniTheme.primaryGreen,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(option),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (selected == null) return;
    ref.read(profileSettingsProvider.notifier).setCurrency(selected);
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

  Future<void> _search(String value) async {
    final results = await ref
        .read(friendsControllerProvider.notifier)
        .searchUsers(value);
    if (mounted) setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return MoniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add friend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('Search by username and send a friend request.'),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(LucideIcons.search),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 12),
          if (_controller.text.isNotEmpty && _results.isEmpty)
            const EmptyState(
              title: 'No users found',
              message: 'Try searching by username.',
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
