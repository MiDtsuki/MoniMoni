import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../../../features/profile/application/profile_settings_controller.dart';
import '../application/debt_controller.dart';
import '../application/friends_controller.dart';
import '../application/guest_debt_note_controller.dart';
import '../domain/debt_model.dart';
import '../domain/friend_model.dart';
import '../domain/guest_debt_note_model.dart';

const _kMinCreditScore = 70;
const _kCreditScoreWarning = 80;

class DebtPage extends ConsumerWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);
    if (isGuest) {
      return const _GuestDebtNotesPage();
    }

    final debtState = ref.watch(debtControllerProvider);
    final friendsState = ref.watch(friendsControllerProvider);
    final totalLent = ref.watch(totalLentProvider);
    final totalBorrowed = ref.watch(totalBorrowedProvider);
    final netDebt = ref.watch(netDebtProvider);
    final creditScore = ref.watch(profileSettingsProvider).creditScore;
    final blocked = creditScore < _kMinCreditScore;

    return AppPage(
      title: 'Debts',
      subtitle: 'Track money shared with friends.',
      onRefresh: () async {
        await Future.wait([
          ref.read(debtControllerProvider.notifier).refresh(),
          ref.read(friendsControllerProvider.notifier).refresh(),
        ]);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (creditScore < _kCreditScoreWarning) ...[
            _CreditScoreBanner(score: creditScore, blocked: blocked),
            const SizedBox(height: 16),
          ],
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
                  onPressed: (friendsState.friends.isEmpty || blocked)
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

class _GuestDebtNotesPage extends ConsumerWidget {
  const _GuestDebtNotesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(guestDebtNoteControllerProvider);
    final lent = notes
        .where((note) => note.type == GuestDebtNoteType.lent)
        .fold<double>(0, (sum, note) => sum + note.amount);
    final borrowed = notes
        .where((note) => note.type == GuestDebtNoteType.borrowed)
        .fold<double>(0, (sum, note) => sum + note.amount);

    return AppPage(
      title: 'Debt notes',
      subtitle:
          'Offline notes only. Friend requests are disabled in guest mode.',
      onRefresh: () =>
          ref.read(guestDebtNoteControllerProvider.notifier).refresh(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 760
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(label: 'Lent notes', value: lent, width: width),
                  _SummaryCard(
                    label: 'Borrowed notes',
                    value: borrowed,
                    width: width,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const _GuestDebtNoteSheet(),
              ),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add debt note'),
            ),
          ),
          const SizedBox(height: 18),
          if (notes.isEmpty)
            const EmptyState(
              title: 'No debt notes',
              message:
                  'Use guest debt notes for simple offline reminders. They are not shared with other users.',
              icon: LucideIcons.notebookPen,
            )
          else
            Column(
              children: [
                for (final note in notes) ...[
                  _GuestDebtNoteCard(note: note),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _GuestDebtNoteCard extends ConsumerWidget {
  const _GuestDebtNoteCard({required this.note});

  final GuestDebtNoteModel note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLent = note.type == GuestDebtNoteType.lent;
    return MoniCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: MoniTheme.softGreen,
            child: Icon(
              isLent ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
              color: MoniTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(isLent ? 'I lent this' : 'I borrowed this'),
                if (note.deadline != null)
                  Text(
                    'Deadline ${note.deadline!.month}/${note.deadline!.day}/${note.deadline!.year}',
                  ),
                if (note.note != null) Text(note.note!),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.compact(note.amount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                tooltip: 'Delete note',
                onPressed: () => ref
                    .read(guestDebtNoteControllerProvider.notifier)
                    .deleteNote(note.id),
                icon: const Icon(LucideIcons.trash2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestDebtNoteSheet extends ConsumerStatefulWidget {
  const _GuestDebtNoteSheet();

  @override
  ConsumerState<_GuestDebtNoteSheet> createState() =>
      _GuestDebtNoteSheetState();
}

class _GuestDebtNoteSheetState extends ConsumerState<_GuestDebtNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  GuestDebtNoteType _type = GuestDebtNoteType.lent;
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Debt note', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              SegmentedButton<GuestDebtNoteType>(
                segments: const [
                  ButtonSegment(
                    value: GuestDebtNoteType.lent,
                    label: Text('Lent'),
                  ),
                  ButtonSegment(
                    value: GuestDebtNoteType.borrowed,
                    label: Text('Borrowed'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (value) =>
                    setState(() => _type = value.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Person or note title',
                  prefixIcon: Icon(LucideIcons.userRound),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(LucideIcons.circleDollarSign),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter an amount greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDeadline,
                icon: const Icon(LucideIcons.calendar),
                label: Text(
                  _deadline == null
                      ? 'Optional deadline'
                      : '${_deadline!.month}/${_deadline!.day}/${_deadline!.year}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: const Text('Save note')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _deadline = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(guestDebtNoteControllerProvider.notifier)
        .addNote(
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          type: _type,
          deadline: _deadline,
          note: _noteController.text,
        );
    if (mounted) Navigator.of(context).pop();
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

// ─── Credit score banner ──────────────────────────────────────────────────────

class _CreditScoreBanner extends StatelessWidget {
  const _CreditScoreBanner({required this.score, required this.blocked});
  final int score;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final isBlocked = blocked;
    final bg = isBlocked ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final border =
        isBlocked ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D);
    final icon = isBlocked ? LucideIcons.shieldAlert : LucideIcons.triangleAlert;
    final iconColor =
        isBlocked ? const Color(0xFFEF4444) : const Color(0xFFD97706);
    final textColor =
        isBlocked ? const Color(0xFF991B1B) : const Color(0xFF92400E);
    final message = isBlocked
        ? 'Score $score/100 — too low to add debts. Settle overdue debts to recover.'
        : 'Score $score/100 — settle debts on time to avoid being blocked.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, color: textColor)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
