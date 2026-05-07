import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../../debts/application/debt_controller.dart';
import '../../debts/application/friends_controller.dart';
import '../../debts/domain/debt_model.dart';
import '../../debts/domain/friend_model.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(friendsControllerProvider);
    final debtState = ref.watch(debtControllerProvider);
    final friendRequests = friendsState.pendingRequests;
    final debtRequests = debtState.pendingRequests;
    final hasRequests = friendRequests.isNotEmpty || debtRequests.isNotEmpty;

    return Scaffold(
      body: AppPage(
        title: 'Inbox',
        subtitle: 'Friend, debt, and settlement requests.',
        action: TextButton(
          onPressed: () => context.go('/profile'),
          child: const Text('Close'),
        ),
        child: hasRequests
            ? Column(
                children: [
                  for (final request in friendRequests) ...[
                    _FriendRequestCard(request: request),
                    const SizedBox(height: 12),
                  ],
                  for (final request in debtRequests) ...[
                    _DebtRequestCard(request: request),
                    const SizedBox(height: 12),
                  ],
                ],
              )
            : const EmptyState(
                title: 'Inbox is clear',
                message:
                    'Friend, debt, and settlement requests will appear here.',
                icon: LucideIcons.bell,
              ),
      ),
    );
  }
}

class _FriendRequestCard extends ConsumerStatefulWidget {
  const _FriendRequestCard({required this.request});

  final FriendRequestModel request;

  @override
  ConsumerState<_FriendRequestCard> createState() => _FriendRequestCardState();
}

class _FriendRequestCardState extends ConsumerState<_FriendRequestCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(friendsControllerProvider.notifier)
          .acceptFriendRequest(widget.request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are now friends with ${widget.request.user.name}!',
            ),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(friendsControllerProvider.notifier)
          .declineFriendRequest(widget.request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MoniCard(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: MoniTheme.softGreen,
            child: Icon(
              LucideIcons.userRoundPlus,
              color: MoniTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.request.user.name} sent a friend request',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(widget.request.user.username),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            TextButton(onPressed: _accept, child: const Text('Accept')),
            TextButton(onPressed: _decline, child: const Text('Decline')),
          ],
        ],
      ),
    );
  }
}

class _DebtRequestCard extends ConsumerStatefulWidget {
  const _DebtRequestCard({required this.request});

  final DebtRequestModel request;

  @override
  ConsumerState<_DebtRequestCard> createState() => _DebtRequestCardState();
}

class _DebtRequestCardState extends ConsumerState<_DebtRequestCard> {
  bool _loading = false;

  Future<void> _accept(bool isSettlement) async {
    setState(() => _loading = true);
    try {
      final controller = ref.read(debtControllerProvider.notifier);
      if (isSettlement) {
        await controller.acceptSettlementRequest(widget.request.id);
      } else {
        await controller.acceptDebtRequest(widget.request.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSettlement ? 'Settlement accepted!' : 'Debt request accepted!',
            ),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline(bool isSettlement) async {
    setState(() => _loading = true);
    try {
      final controller = ref.read(debtControllerProvider.notifier);
      if (isSettlement) {
        await controller.declineSettlementRequest(widget.request.id);
      } else {
        await controller.declineDebtRequest(widget.request.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSettlement ? 'Settlement declined.' : 'Debt request declined.',
            ),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsControllerProvider).friends;
    final friend = friends.firstWhere(
      (item) => item.id == widget.request.friendId,
      orElse: () => FriendModel(
        id: widget.request.friendId,
        name: 'Friend',
        username: '@unknown',
      ),
    );
    final debt = widget.request.debt;
    final isSettlement = widget.request.type == DebtRequestType.settlement;
    final debtState = ref.watch(debtControllerProvider);
    final settlementDebts = widget.request.debtIds
        .map((id) => debtState.debts.where((item) => item.id == id).firstOrNull)
        .whereType<DebtModel>()
        .toList();
    final settlementTotal = settlementDebts.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final isSettleAll =
        isSettlement && widget.request.debtIds.length > 1 ||
        widget.request.title.toLowerCase().contains('all');

    return MoniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: MoniTheme.softGreen,
                child: Icon(
                  isSettlement ? LucideIcons.check : LucideIcons.handCoins,
                  color: MoniTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSettlement
                          ? isSettleAll
                                ? 'Settle all request'
                                : 'Settlement request'
                          : widget.request.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text('${friend.name} ${friend.username}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSettlement
                ? isSettleAll
                      ? 'Settle all active transactions with this friend.'
                      : 'Settle one active debt transaction.'
                : widget.request.description,
          ),
          if (debt != null) ...[
            const SizedBox(height: 12),
            _DetailRow(label: 'Type', value: debt.isLent ? 'Lend' : 'Borrow'),
            _DetailRow(
              label: 'Amount',
              value: CurrencyFormatter.compact(debt.amount),
            ),
            if (debt.deadline != null)
              _DetailRow(
                label: 'Deadline',
                value: DateFormat('MMM d, yyyy').format(debt.deadline!),
              ),
            if (debt.note != null) _DetailRow(label: 'Note', value: debt.note!),
          ],
          if (isSettlement) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Transactions',
              value: '${settlementDebts.length}',
            ),
            _DetailRow(
              label: 'Amount',
              value: CurrencyFormatter.compact(settlementTotal),
            ),
          ],
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decline(isSettlement),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _accept(isSettlement),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
