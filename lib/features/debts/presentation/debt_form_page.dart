import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../application/debt_controller.dart';
import '../application/friends_controller.dart';
import '../domain/debt_model.dart';

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
  DateTime? _deadline;
  String? _friendId;

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsControllerProvider).friends;
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
        child: friends.isEmpty
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
                              child: Text('${friend.name} ${friend.username}'),
                            ),
                        ],
                        onChanged: (value) => setState(() => _friendId = value),
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
                        keyboardType: const TextInputType.numberWithOptions(
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
                        value: _deadline == null
                            ? 'Optional'
                            : DateFormat('MMM d, yyyy').format(_deadline!),
                        icon: LucideIcons.calendar,
                        onTap: _pickDeadline,
                        trailing: _deadline == null
                            ? null
                            : IconButton(
                                onPressed: () =>
                                    setState(() => _deadline = null),
                                icon: const Icon(LucideIcons.x),
                              ),
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
                        onPressed: _save,
                        child: const Text('Send request'),
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
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_createdAt),
    );
    if (time == null) {
      return;
    }
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
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) {
      return;
    }
    setState(() => _deadline = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    ref
        .read(debtControllerProvider.notifier)
        .createDebtRequest(
          friendId: _friendId!,
          amount: double.parse(_amountController.text),
          direction: _direction,
          createdAt: _createdAt,
          deadline: _deadline,
          note: _noteController.text,
        );
    context.go('/profile/inbox');
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
