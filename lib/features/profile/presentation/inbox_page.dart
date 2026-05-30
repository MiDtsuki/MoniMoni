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
import '../../debts/domain/settlement_payment_info.dart';
import '../application/profile_settings_controller.dart';

enum InboxFilter { all, friends, lend, borrow, settlement }

extension on InboxFilter {
  String get label {
    switch (this) {
      case InboxFilter.all:
        return 'All';
      case InboxFilter.friends:
        return 'Friends';
      case InboxFilter.lend:
        return 'Lend';
      case InboxFilter.borrow:
        return 'Borrow';
      case InboxFilter.settlement:
        return 'Settlement';
    }
  }
}

final inboxFilterProvider = StateProvider.autoDispose<InboxFilter>(
  (ref) => InboxFilter.all,
);

bool _debtRequestMatchesFilter(DebtRequestModel request, InboxFilter filter) {
  if (filter == InboxFilter.all) return true;
  if (filter == InboxFilter.friends) return false;
  switch (request.type) {
    case DebtRequestType.debt:
    case DebtRequestType.debtAccepted:
    case DebtRequestType.debtDeclined:
      final debt = request.debt;
      if (debt == null) return false;
      if (filter == InboxFilter.lend) return debt.isLent;
      if (filter == InboxFilter.borrow) return !debt.isLent;
      return false;
    case DebtRequestType.settlement:
    case DebtRequestType.settlementAccepted:
      return filter == InboxFilter.settlement;
  }
}

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(friendsControllerProvider);
    final debtState = ref.watch(debtControllerProvider);
    final filter = ref.watch(inboxFilterProvider);

    final friendRequests = friendsState.pendingRequests;
    final outgoingFriendRequests = friendsState.outgoingRequests;
    final acceptedNotifications = friendsState.acceptedNotifications;
    final debtRequests = debtState.pendingRequests;
    final outgoingDebtRequests = debtState.outgoingRequests;
    final hasRequests =
        friendRequests.isNotEmpty ||
        outgoingFriendRequests.isNotEmpty ||
        acceptedNotifications.isNotEmpty ||
        debtRequests.isNotEmpty ||
        outgoingDebtRequests.isNotEmpty;

    final showFriends =
        filter == InboxFilter.all || filter == InboxFilter.friends;
    final visibleOutgoingFriendRequests = showFriends
        ? outgoingFriendRequests
        : const [];
    final visibleFriendRequests = showFriends ? friendRequests : const [];
    final visibleAcceptedNotifications = showFriends
        ? acceptedNotifications
        : const [];
    final visibleOutgoingDebtRequests = outgoingDebtRequests
        .where((r) => _debtRequestMatchesFilter(r, filter))
        .toList();
    final visibleDebtRequests = debtRequests
        .where((r) => _debtRequestMatchesFilter(r, filter))
        .toList();

    final visibleAny =
        visibleOutgoingFriendRequests.isNotEmpty ||
        visibleFriendRequests.isNotEmpty ||
        visibleAcceptedNotifications.isNotEmpty ||
        visibleOutgoingDebtRequests.isNotEmpty ||
        visibleDebtRequests.isNotEmpty;

    return Scaffold(
      body: AppPage(
        title: 'Inbox',
        subtitle: 'Friend, debt, and settlement requests.',
        onRefresh: () async {
          await Future.wait([
            ref.read(debtControllerProvider.notifier).refresh(),
            ref.read(friendsControllerProvider.notifier).refresh(),
          ]);
        },
        action: TextButton(
          onPressed: () => context.go('/profile'),
          child: const Text('Close'),
        ),
        child: hasRequests
            ? Column(
                children: [
                  const _InboxFilterBar(),
                  const SizedBox(height: 16),
                  if (!visibleAny)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text(
                        'No items match this filter.',
                        style: TextStyle(color: MoniTheme.muted),
                      ),
                    )
                  else ...[
                    for (final request in visibleOutgoingFriendRequests) ...[
                      _FriendRequestCard(request: request),
                      const SizedBox(height: 12),
                    ],
                    for (final request in visibleOutgoingDebtRequests) ...[
                      _DebtRequestCard(request: request),
                      const SizedBox(height: 12),
                    ],
                    for (final notification
                        in visibleAcceptedNotifications) ...[
                      _FriendAcceptedCard(notification: notification),
                      const SizedBox(height: 12),
                    ],
                    for (final request in visibleFriendRequests) ...[
                      _FriendRequestCard(request: request),
                      const SizedBox(height: 12),
                    ],
                    for (final request in visibleDebtRequests) ...[
                      _DebtRequestCard(request: request),
                      const SizedBox(height: 12),
                    ],
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

class _InboxFilterBar extends ConsumerWidget {
  const _InboxFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(inboxFilterProvider);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: InboxFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = InboxFilter.values[index];
          final isSelected = value == selected;
          return ChoiceChip(
            label: Text(value.label),
            selected: isSelected,
            onSelected: (_) =>
                ref.read(inboxFilterProvider.notifier).state = value,
            selectedColor: MoniTheme.softGreen,
            labelStyle: TextStyle(
              color: isSelected ? MoniTheme.primaryGreen : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? MoniTheme.primaryGreen
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            backgroundColor: Colors.white,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _FriendAcceptedCard extends ConsumerStatefulWidget {
  const _FriendAcceptedCard({required this.notification});

  final FriendRequestModel notification;

  @override
  ConsumerState<_FriendAcceptedCard> createState() =>
      _FriendAcceptedCardState();
}

class _FriendAcceptedCardState extends ConsumerState<_FriendAcceptedCard> {
  bool _loading = false;

  Future<void> _dismiss() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(friendsControllerProvider.notifier)
          .dismissAcceptedNotification(widget.notification.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              LucideIcons.userRoundCheck,
              color: MoniTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.notification.user.name} accepted your friend request',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text('@${widget.notification.user.username}'),
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
          else
            TextButton(onPressed: _dismiss, child: const Text('Dismiss')),
        ],
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  widget.request.isOutgoing
                      ? 'Friend request sent to ${widget.request.user.name}'
                      : '${widget.request.user.name} sent a friend request',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text('@${widget.request.user.username}'),
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
          else if (widget.request.isOutgoing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Pending',
                style: TextStyle(
                  color: MoniTheme.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(debtControllerProvider.notifier)
          .dismissDebtNotification(widget.request.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
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
    final isNotification =
        widget.request.type == DebtRequestType.debtAccepted ||
        widget.request.type == DebtRequestType.debtDeclined ||
        widget.request.type == DebtRequestType.settlementAccepted;
    final isAcceptedNotification =
        widget.request.type == DebtRequestType.debtAccepted ||
        widget.request.type == DebtRequestType.settlementAccepted;
    final isOutgoing = widget.request.isOutgoing;
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
    final paymentInfo = widget.request.paymentInfo;

    return MoniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isNotification
                    ? isAcceptedNotification
                          ? MoniTheme.softGreen
                          : const Color(0xFFFFE5E5)
                    : MoniTheme.softGreen,
                child: Icon(
                  isNotification
                      ? isAcceptedNotification
                            ? LucideIcons.circleCheck
                            : LucideIcons.circleX
                      : isSettlement
                      ? LucideIcons.check
                      : LucideIcons.handCoins,
                  color: isNotification
                      ? isAcceptedNotification
                            ? MoniTheme.primaryGreen
                            : const Color(0xFFEF4444)
                      : MoniTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOutgoing
                          ? widget.request.title
                          : isSettlement
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
                      ? _settlementDescription(paymentInfo, true)
                      : _settlementDescription(paymentInfo, false)
                : widget.request.description,
          ),
          if (debt != null) ...[
            const SizedBox(height: 12),
            _DetailRow(label: 'Type', value: debt.isLent ? 'Lend' : 'Borrow'),
            _DetailRow(
              label: 'Amount',
              value: CurrencyFormatter.compact(debt.amount, symbol),
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
              label: 'Payment',
              value: paymentInfo.isTransfer
                  ? 'Verified transfer'
                  : 'Cash settlement',
            ),
            _DetailRow(
              label: 'Transactions',
              value: '${settlementDebts.length}',
            ),
            _DetailRow(
              label: 'Amount',
              value: CurrencyFormatter.compact(settlementTotal, symbol),
            ),
            if (paymentInfo.isTransfer && paymentInfo.amountInSlip != null)
              _DetailRow(
                label: 'Verified',
                value: CurrencyFormatter.compact(
                  paymentInfo.amountInSlip!,
                  symbol,
                ),
              ),
          ],
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (isNotification)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _dismiss,
                child: const Text('Dismiss'),
              ),
            )
          else if (isOutgoing)
            const SizedBox(
              width: double.infinity,
              child: Center(
                child: Text(
                  'Pending',
                  style: TextStyle(
                    color: MoniTheme.primaryGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
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

String _settlementDescription(
  SettlementPaymentInfo paymentInfo,
  bool isSettleAll,
) {
  final scope = isSettleAll
      ? 'all active transactions'
      : 'one active debt transaction';
  if (paymentInfo.isTransfer && paymentInfo.verified) {
    return 'This user settled $scope through a verified bank transfer.';
  }
  return isSettleAll
      ? 'Settle all active transactions with this friend.'
      : 'Settle one active debt transaction.';
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
