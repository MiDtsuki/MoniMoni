import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../application/transaction_controller.dart';
import '../domain/transaction_model.dart';

enum _TransactionMode { income, expense, transfer }

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.transactionId});

  final String? transactionId;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _dateTime = DateTime.now();
  String? _category;
  String? _account;
  var _transactionMissing = false;

  bool get _isEditing => widget.transactionId != null;

  _TransactionMode get _mode {
    return _type == TransactionType.income
        ? _TransactionMode.income
        : _TransactionMode.expense;
  }

  @override
  void initState() {
    super.initState();
    final transactionId = widget.transactionId;
    if (transactionId == null) {
      return;
    }
    final transaction = _findTransaction(transactionId);
    if (transaction == null) {
      _transactionMissing = true;
      return;
    }
    _type = transaction.type;
    _dateTime = transaction.date;
    _category = transaction.category;
    _account = transaction.account;
    _amountController.text = _formatAmount(transaction.amount);
    _noteController.text = transaction.note ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_transactionMissing) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      LucideIcons.receiptText,
                      color: MoniTheme.primaryGreen,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Transaction not found',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This log entry is no longer available.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MoniTheme.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => context.go('/logs'),
                      child: const Text('Back to logs'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final options = ref.watch(transactionOptionsProvider);
    final categories = options.categoriesFor(_type);
    _category ??= categories.first;
    if (!categories.contains(_category)) {
      _category = categories.first;
    }
    _account ??= options.accounts.first;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    sliver: SliverToBoxAdapter(
                      child: _FormHeader(
                        title: _isEditing
                            ? 'Edit transaction'
                            : _type == TransactionType.income
                            ? 'Income'
                            : 'Expense',
                        onBack: () => context.go('/logs'),
                        onSave: _save,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ModeSelector(
                            mode: _mode,
                            onChanged: (mode) {
                              if (mode == _TransactionMode.transfer) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Transfer will be available when account transfers are added.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                _type = mode == _TransactionMode.income
                                    ? TransactionType.income
                                    : TransactionType.expense;
                                _category = null;
                              });
                            },
                          ),
                          const SizedBox(height: 28),
                          _UnderlineActionRow(
                            label: 'Date',
                            value: DateFormat(
                              'dd/MM/yyyy (E)   h:mm a',
                            ).format(_dateTime),
                            onTap: _pickDateTime,
                          ),
                          _UnderlineInputRow(
                            label: 'Amount',
                            controller: _amountController,
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
                                return 'Enter the transaction amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Amount must be greater than zero';
                              }
                              return null;
                            },
                          ),
                          _UnderlineActionRow(
                            label: 'Category',
                            value: _category ?? 'Choose category',
                            onTap: _showCategoryPicker,
                          ),
                          _UnderlineActionRow(
                            label: 'Account',
                            value: _account ?? 'Choose account',
                            onTap: _showAccountPicker,
                          ),
                          _UnderlineInputRow(
                            label: 'Note',
                            controller: _noteController,
                            minLines: 1,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: _save,
                            child: Text(
                              _isEditing ? 'Save changes' : 'Save transaction',
                            ),
                          ),
                          if (_isEditing) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _confirmDelete,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade200),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete transaction'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _showCategoryPicker() async {
    final options = ref.read(transactionOptionsProvider);
    final categories = options.categoriesFor(_type);
    final result = await _showAdaptivePicker<_CategoryPickerResult>(
      child: _CategoryPicker(
        title: 'Category',
        categories: categories,
        selectedCategory: _category,
      ),
    );
    if (result == null) {
      return;
    }
    switch (result.action) {
      case _CategoryPickerAction.select:
        setState(() => _category = result.value);
      case _CategoryPickerAction.add:
        await _addCategory(_type);
      case _CategoryPickerAction.edit:
        await _editCategory(_type, result.value);
    }
  }

  Future<void> _showAccountPicker() async {
    final result = await _showAdaptivePicker<_AccountPickerResult>(
      child: _AccountPicker(selectedAccount: _account),
    );
    if (result == null) {
      return;
    }
    switch (result.action) {
      case _AccountPickerAction.select:
        setState(() => _account = result.value);
      case _AccountPickerAction.add:
        await _addAccount();
      case _AccountPickerAction.edit:
        await _editAccount(result.value);
    }
  }

  Future<T?> _showAdaptivePicker<T>({required Widget child}) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    if (isWide) {
      return showDialog<T>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
            child: child,
          ),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(child: child),
    );
  }

  Future<void> _addCategory(TransactionType type) async {
    final value = await _showCategoryPrompt(
      title: 'Custom category',
      actionLabel: 'Add category',
    );
    if (value == null || value.trim().isEmpty) {
      return;
    }
    ref.read(transactionOptionsProvider.notifier).addCategory(type, value);
    setState(() => _category = value.trim());
  }

  Future<void> _editCategory(TransactionType type, String oldValue) async {
    final value = await _showCategoryPrompt(
      title: 'Edit category',
      actionLabel: 'Save category',
      initialValue: oldValue,
    );
    if (value == null || value.trim().isEmpty) {
      return;
    }
    ref
        .read(transactionOptionsProvider.notifier)
        .editCategory(type, oldValue, value);
    setState(() => _category = value.trim());
  }

  Future<void> _addAccount() async {
    final value = await _showNamePrompt(
      title: 'New account',
      label: 'Account name',
      actionLabel: 'Add account',
    );
    if (value == null || value.trim().isEmpty) {
      return;
    }
    ref.read(transactionOptionsProvider.notifier).addAccount(value);
    setState(() => _account = value.trim());
  }

  Future<void> _editAccount(String oldValue) async {
    final value = await _showNamePrompt(
      title: 'Edit account',
      label: 'Account name',
      actionLabel: 'Save account',
      initialValue: oldValue,
    );
    if (value == null || value.trim().isEmpty) {
      return;
    }
    ref.read(transactionOptionsProvider.notifier).editAccount(oldValue, value);
    setState(() => _account = value.trim());
  }

  Future<String?> _showNamePrompt({
    required String title,
    required String label,
    required String actionLabel,
    String? initialValue,
  }) {
    return _showAdaptivePicker<String>(
      child: _NameSheet(
        title: title,
        label: label,
        actionLabel: actionLabel,
        initialValue: initialValue,
      ),
    );
  }

  Future<String?> _showCategoryPrompt({
    required String title,
    required String actionLabel,
    String? initialValue,
  }) {
    return _showAdaptivePicker<String>(
      child: _CategorySheet(
        title: title,
        actionLabel: actionLabel,
        initialValue: initialValue,
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final note = _noteController.text.trim();
    if (_isEditing) {
      ref
          .read(transactionControllerProvider.notifier)
          .updateTransaction(
            TransactionModel(
              id: widget.transactionId!,
              category: _category!,
              account: _account!,
              amount: double.parse(_amountController.text),
              type: _type,
              date: _dateTime,
              note: note.isEmpty ? null : note,
            ),
          );
    } else {
      ref
          .read(transactionControllerProvider.notifier)
          .addTransaction(
            category: _category!,
            account: _account!,
            amount: double.parse(_amountController.text),
            type: _type,
            date: _dateTime,
            note: note,
          );
    }
    context.go('/logs');
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This log entry will be removed from memory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) {
      return;
    }
    ref
        .read(transactionControllerProvider.notifier)
        .deleteTransaction(widget.transactionId!);
    context.go('/logs');
  }

  TransactionModel? _findTransaction(String id) {
    for (final transaction in ref.read(transactionControllerProvider)) {
      if (transaction.id == id) {
        return transaction;
      }
    }
    return null;
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.title,
    required this.onBack,
    required this.onSave,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        IconButton.filledTonal(
          tooltip: 'Save transaction',
          onPressed: onSave,
          icon: const Icon(LucideIcons.check),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final _TransactionMode mode;
  final ValueChanged<_TransactionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            label: 'Income',
            selected: mode == _TransactionMode.income,
            onTap: () => onChanged(_TransactionMode.income),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeButton(
            label: 'Expense',
            selected: mode == _TransactionMode.expense,
            onTap: () => onChanged(_TransactionMode.expense),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeButton(
            label: 'Transfer',
            selected: mode == _TransactionMode.transfer,
            onTap: () => onChanged(_TransactionMode.transfer),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? MoniTheme.softGreen : Colors.white,
        side: BorderSide(
          color: selected ? MoniTheme.primaryGreen : MoniTheme.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: FittedBox(child: Text(label)),
    );
  }
}

class _UnderlineActionRow extends StatelessWidget {
  const _UnderlineActionRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: _UnderlineShell(
        label: label,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: MoniTheme.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _UnderlineInputRow extends StatelessWidget {
  const _UnderlineInputRow({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return _UnderlineShell(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        minLines: minLines,
        maxLines: maxLines,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _UnderlineShell extends StatelessWidget {
  const _UnderlineShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MoniTheme.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: MoniTheme.muted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

enum _CategoryPickerAction { select, add, edit }

class _CategoryPickerResult {
  const _CategoryPickerResult(this.action, this.value);

  final _CategoryPickerAction action;
  final String value;
}

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({
    required this.title,
    required this.categories,
    required this.selectedCategory,
  });

  final String title;
  final List<String> categories;
  final String? selectedCategory;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  var _editing = false;

  @override
  Widget build(BuildContext context) {
    return _PickerScaffold(
      title: widget.title,
      leadingAction: IconButton(
        tooltip: _editing ? 'Done editing' : 'Edit categories',
        onPressed: () => setState(() => _editing = !_editing),
        icon: Icon(_editing ? LucideIcons.check : Icons.edit_outlined),
      ),
      trailing: IconButton(
        tooltip: 'Add category',
        onPressed: () => Navigator.of(
          context,
        ).pop(const _CategoryPickerResult(_CategoryPickerAction.add, '')),
        icon: const Icon(LucideIcons.plus),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 640
              ? 5
              : constraints.maxWidth >= 480
              ? 4
              : 3;
          return GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: widget.categories.length + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 1.28,
            ),
            itemBuilder: (context, index) {
              if (index == widget.categories.length) {
                return _PickerTile(
                  emoji: '+',
                  label: 'Custom',
                  selected: false,
                  editing: false,
                  onTap: () => Navigator.of(context).pop(
                    const _CategoryPickerResult(_CategoryPickerAction.add, ''),
                  ),
                );
              }
              final category = widget.categories[index];
              return _PickerTile(
                emoji: _categoryEmoji(category),
                label: _categoryName(category),
                selected: category == widget.selectedCategory,
                editing: _editing,
                onTap: () => Navigator.of(context).pop(
                  _CategoryPickerResult(
                    _editing
                        ? _CategoryPickerAction.edit
                        : _CategoryPickerAction.select,
                    category,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _AccountPickerAction { select, add, edit }

class _AccountPickerResult {
  const _AccountPickerResult(this.action, this.value);

  final _AccountPickerAction action;
  final String value;
}

class _AccountPicker extends ConsumerWidget {
  const _AccountPicker({required this.selectedAccount});

  final String? selectedAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(transactionOptionsProvider).accounts;

    return _PickerScaffold(
      title: 'Account',
      trailing: IconButton(
        tooltip: 'Add account',
        onPressed: () => Navigator.of(
          context,
        ).pop(const _AccountPickerResult(_AccountPickerAction.add, '')),
        icon: const Icon(LucideIcons.plus),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: accounts.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final account = accounts[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              account == selectedAccount
                  ? LucideIcons.check
                  : LucideIcons.wallet,
              color: MoniTheme.primaryGreen,
            ),
            title: Text(account),
            onTap: () => Navigator.of(
              context,
            ).pop(_AccountPickerResult(_AccountPickerAction.select, account)),
            trailing: IconButton(
              tooltip: 'Edit account',
              onPressed: () => Navigator.of(
                context,
              ).pop(_AccountPickerResult(_AccountPickerAction.edit, account)),
              icon: const Icon(Icons.edit_outlined),
            ),
          );
        },
      ),
    );
  }
}

class _PickerScaffold extends StatelessWidget {
  const _PickerScaffold({
    required this.title,
    required this.child,
    this.leadingAction,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? leadingAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ?leadingAction,
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ?trailing,
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.editing,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? MoniTheme.softGreen : Colors.white,
          border: Border.all(color: MoniTheme.line),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            if (editing)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.edit_outlined, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({
    required this.title,
    required this.actionLabel,
    this.initialValue,
  });

  final String title;
  final String actionLabel;
  final String? initialValue;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _emojiController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _emojiController.text = initial == null ? '💵' : _categoryEmoji(initial);
    _nameController.text = initial == null ? '' : _categoryName(initial);
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 84,
                child: TextField(
                  controller: _emojiController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Emoji'),
                  textAlign: TextAlign.center,
                  maxLength: 2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submit, child: Text(widget.actionLabel)),
        ],
      ),
    );
  }

  void _submit() {
    final emoji = _emojiController.text.trim().isEmpty
        ? '💵'
        : _emojiController.text.trim();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop('$emoji $name');
  }
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({
    required this.title,
    required this.label,
    required this.actionLabel,
    this.initialValue,
  });

  final String title;
  final String label;
  final String actionLabel;
  final String? initialValue;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.label),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submit, child: Text(widget.actionLabel)),
        ],
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }
}

String _categoryEmoji(String category) {
  final defaultEmoji = switch (category) {
    'Salary' => '💼',
    'Allowance' => '💵',
    'Freelance' => '💻',
    'Gift' => '🎁',
    'Food' => '🍜',
    'Transport' => '🚕',
    'Shopping' => '🛍️',
    'Bills' => '🧾',
    'Education' => '📚',
    'Health' => '💊',
    'Entertainment' => '🎟️',
    'Other' => '💡',
    _ => null,
  };
  if (defaultEmoji != null) {
    return defaultEmoji;
  }
  final trimmed = category.trim();
  if (trimmed.isEmpty) {
    return '💵';
  }
  final first = trimmed.characters.first;
  return RegExp(r'[A-Za-z0-9]').hasMatch(first) ? '💵' : first;
}

String _categoryName(String category) {
  final trimmed = category.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final emoji = _categoryEmoji(trimmed);
  if (trimmed.startsWith(emoji)) {
    return trimmed.substring(emoji.length).trim();
  }
  return trimmed;
}
