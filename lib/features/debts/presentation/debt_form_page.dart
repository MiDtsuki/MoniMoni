import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../../../features/profile/application/profile_settings_controller.dart';
import '../application/debt_controller.dart';
import '../application/friends_controller.dart';
import '../domain/debt_model.dart';

const _kMinCreditScore = 70;

class DebtFormPage extends ConsumerStatefulWidget {
  const DebtFormPage({super.key});

  @override
  ConsumerState<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  DebtDirection _direction = DebtDirection.owedToMe;
  DateTime _createdAt = DateTime.now();
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  String? _friendId;
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsControllerProvider).friends;
    final creditScore = ref.watch(profileSettingsProvider).creditScore;

    if (friends.isNotEmpty && _friendId == null) {
      _friendId = friends.first.id;
    }

    return Scaffold(
      body: AppPage(
        title: 'Add debt',
        subtitle: 'Creates a pending request before it becomes active.',
        action: TextButton(
          onPressed: () => context.go('/debts'),
          child: const Text('Close'),
        ),
        child: creditScore < _kMinCreditScore
            ? _CreditBlockedBody(score: creditScore)
            : friends.isEmpty
                ? const EmptyState(
                    title: 'Add a friend first',
                    message:
                        'Debt transactions can only be created with existing friends.',
                    icon: LucideIcons.userRoundPlus,
                  )
                : MoniCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<DebtDirection>(
                            segments: const [
                              ButtonSegment(
                                value: DebtDirection.owedToMe,
                                label: Text('Lend'),
                              ),
                              ButtonSegment(
                                value: DebtDirection.iOwe,
                                label: Text('Borrow'),
                              ),
                            ],
                            selected: {_direction},
                            onSelectionChanged: (value) {
                              setState(() => _direction = value.first);
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _friendId,
                            items: [
                              for (final friend in friends)
                                DropdownMenuItem(
                                  value: friend.id,
                                  child: Text(
                                      '${friend.name} ${friend.username}'),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _friendId = value),
                            decoration: const InputDecoration(
                              labelText: 'Friend',
                              prefixIcon: Icon(LucideIcons.userRound),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PickerField(
                            label: 'Time',
                            value: DateFormat(
                              'MMM d, yyyy h:mm a',
                            ).format(_createdAt),
                            icon: LucideIcons.calendarClock,
                            onTap: _pickCreatedAt,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              prefixIcon: Icon(LucideIcons.circleDollarSign),
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter the debt amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Amount must be greater than zero';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _PickerField(
                            label: 'Deadline',
                            value: DateFormat('MMM d, yyyy').format(_deadline),
                            icon: LucideIcons.calendar,
                            onTap: _pickDeadline,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _noteController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(LucideIcons.receiptText),
                            ),
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Send request'),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Future<void> _pickCreatedAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _createdAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_createdAt),
    );
    if (time == null) return;
    setState(() {
      _createdAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickDeadline() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() => _deadline = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(debtControllerProvider.notifier).createDebtRequest(
            friendId: _friendId!,
            amount: double.parse(_amountController.text),
            direction: _direction,
            createdAt: _createdAt,
            deadline: _deadline,
            note: _noteController.text,
          );
      if (mounted) context.go('/profile/inbox');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not send request: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Credit blocked state ─────────────────────────────────────────────────────

class _CreditBlockedBody extends StatelessWidget {
  const _CreditBlockedBody({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return MoniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldAlert,
                    color: Color(0xFFEF4444), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Credit score too low',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB91C1C)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your score is $score/100. You need at least $_kMinCreditScore to lend or borrow.',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF991B1B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('How to recover',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _RecoveryTask(
            icon: LucideIcons.circleAlert,
            title: 'Settle overdue debts',
            description: 'Stops the −1 pt/day penalty immediately.',
            badge: 'Stop loss',
            badgeColor: Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          const _RecoveryTask(
            icon: LucideIcons.calendarCheck,
            title: 'Settle before the deadline',
            description: 'Each on-time settlement earns +3 pts.',
            badge: '+3 pts',
            badgeColor: Color(0xFF4CAF7D),
          ),
          const SizedBox(height: 8),
          const _RecoveryTask(
            icon: LucideIcons.ban,
            title: 'Avoid missing deadlines',
            description: 'Missing a deadline costs −5 pts + −1 pt/day.',
            badge: '−5 pts',
            badgeColor: Color(0xFFF97316),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go('/debts'),
            icon: const Icon(LucideIcons.handCoins),
            label: const Text('View my debts'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryTask extends StatelessWidget {
  const _RecoveryTask({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: badgeColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Text(description,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(badge,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor)),
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        child: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
