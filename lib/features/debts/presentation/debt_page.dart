import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../application/debt_controller.dart';
import '../application/friends_controller.dart';
import '../domain/debt_model.dart';
import '../domain/friend_model.dart';

class DebtPage extends ConsumerWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtState = ref.watch(debtControllerProvider);
    final friendsState = ref.watch(friendsControllerProvider);
    final totalLent = ref.watch(totalLentProvider);
    final totalBorrowed = ref.watch(totalBorrowedProvider);
    final netDebt = ref.watch(netDebtProvider);

    return AppPage(
      title: 'Debts',
      subtitle: 'Track money shared with friends.',
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
                  _SummaryCard(
                    label: 'Total lent',
                    value: totalLent,
                    width: width,
                  ),
                  _SummaryCard(
                    label: 'Total borrowed',
                    value: totalBorrowed,
                    width: width,
                  ),
                  _SummaryCard(
                    label: 'True net balance',
                    value: netDebt,
                    width: width,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _AddFriendDialog(),
                  ),
                  icon: const Icon(LucideIcons.userRoundPlus),
                  label: const Text('Add friend'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: friendsState.friends.isEmpty
                      ? null
                      : () => context.go('/debts/new'),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Add debt'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Friends', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (friendsState.friends.isEmpty)
            EmptyState(
              title: 'No friends yet',
              message:
                  'Search by username and send a friend request to start tracking shared money.',
              icon: LucideIcons.userRoundPlus,
              action: OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _AddFriendDialog(),
                ),
                icon: const Icon(LucideIcons.search),
                label: const Text('Find friends'),
              ),
            )
          else
            Column(
              children: [
                for (final friend in friendsState.friends) ...[
                  _FriendCard(
                    friend: friend,
                    debts: debtsForFriend(debtState, friend.id),
                    onTap: () => context.go('/debts/${friend.id}'),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.debts,
    required this.onTap,
  });

  final FriendModel friend;
  final List<DebtModel> debts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lent = lentToFriend(debts);
    final borrowed = borrowedFromFriend(debts);
    final net = lent - borrowed;
    final label = net >= 0 ? 'They owe me' : 'I owe them';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: MoniCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: MoniTheme.softGreen,
              child: Text(
                friend.name.characters.first,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(friend.username),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.compact(net.abs()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFriendDialog extends ConsumerStatefulWidget {
  const _AddFriendDialog();

  @override
  ConsumerState<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<_AddFriendDialog> {
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
    return AlertDialog(
      title: const Text('Add friend'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search username',
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
                  title: Text(user.name),
                  subtitle: Text(user.username),
                  trailing: TextButton(
                    onPressed: () {
                      ref
                          .read(friendsControllerProvider.notifier)
                          .sendFriendRequest(user);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Send'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
