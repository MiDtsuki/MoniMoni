import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/transaction_controller.dart';
import '../domain/transaction_model.dart';

class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() =>
      _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionControllerProvider);
    final monthTransactions = transactions.where((item) {
      return item.date.year == _selectedMonth.year &&
          item.date.month == _selectedMonth.month;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final income = _sum(monthTransactions, TransactionType.income);
    final expenses = _sum(monthTransactions, TransactionType.expense);
    final grouped = _groupByDay(monthTransactions);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/logs/new'),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      children: [
                        _MonthBar(
                          month: _selectedMonth,
                          onPrevious: () => _moveMonth(-1),
                          onNext: () => _moveMonth(1),
                          onTapMonth: _pickMonth,
                        ),
                        const SizedBox(height: 14),
                        const _DailyTab(),
                        const SizedBox(height: 14),
                        _SummaryRow(
                          income: income,
                          expenses: expenses,
                          total: income - expenses,
                        ),
                      ],
                    ),
                  ),
                ),
                if (grouped.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(18),
                    sliver: SliverToBoxAdapter(
                      child: EmptyState(
                        title: 'No transactions this month',
                        message:
                            'Add income or expenses to build a daily log for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
                        icon: LucideIcons.receiptText,
                        action: ElevatedButton.icon(
                          onPressed: () => context.go('/logs/new'),
                          icon: const Icon(LucideIcons.plus),
                          label: const Text('Add transaction'),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                    sliver: SliverList.builder(
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final entry = grouped.entries.elementAt(index);
                        return _DaySection(
                          date: entry.key,
                          transactions: entry.value,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _moveMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  Future<void> _pickMonth() async {
    final picked = await _showAdaptiveMonthPicker();
    if (picked == null) {
      return;
    }
    setState(() => _selectedMonth = picked);
  }

  Future<DateTime?> _showAdaptiveMonthPicker() {
    final picker = _MonthPicker(initialMonth: _selectedMonth);
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    if (isWide) {
      return showDialog<DateTime>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: picker,
          ),
        ),
      );
    }
    return showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: picker),
    );
  }

  double _sum(List<TransactionModel> transactions, TransactionType type) {
    return transactions
        .where((item) => item.type == type)
        .fold(0, (sum, item) => sum + item.amount);
  }

  Map<DateTime, List<TransactionModel>> _groupByDay(
    List<TransactionModel> transactions,
  ) {
    final grouped = <DateTime, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final key = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      grouped.putIfAbsent(key, () => []).add(transaction);
    }
    return grouped;
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onTapMonth,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTapMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: InkWell(
              onTap: onTapMonth,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM yyyy').format(month),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _DailyTab extends StatelessWidget {
  const _DailyTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Daily',
            style: TextStyle(
              color: MoniTheme.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 52,
            height: 3,
            decoration: BoxDecoration(
              color: MoniTheme.primaryGreen,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPicker extends StatefulWidget {
  const _MonthPicker({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
    _month = widget.initialMonth.month;
  }

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
              IconButton(
                tooltip: 'Previous year',
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_year',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next year',
                onPressed: () => setState(() => _year++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final month = index + 1;
              final selected = month == _month;
              return OutlinedButton(
                onPressed: () => setState(() => _month = month),
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected
                      ? MoniTheme.softGreen
                      : Colors.white,
                  side: BorderSide(
                    color: selected ? MoniTheme.primaryGreen : MoniTheme.line,
                  ),
                ),
                child: Text(DateFormat.MMM().format(DateTime(_year, month))),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(DateTime(_year, _month)),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.income,
    required this.expenses,
    required this.total,
  });

  final double income;
  final double expenses;
  final double total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MoniTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _SummaryItem(
              label: 'Income',
              value: income,
              color: MoniTheme.primaryGreen,
            ),
            _SummaryItem(
              label: 'Expenses',
              value: expenses,
              color: MoniTheme.deepGreen,
            ),
            _SummaryItem(label: 'Total', value: total, color: MoniTheme.ink),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              CurrencyFormatter.compact(value),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.date, required this.transactions});

  final DateTime date;
  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final income = transactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenses = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDE7E0)),
        ),
        child: Column(
          children: [
            _DayHeader(date: date, income: income, expenses: expenses),
            const Divider(height: 2, color: Color(0xFFC9DDD1)),
            for (var i = 0; i < transactions.length; i++) ...[
              _TransactionCompactRow(
                transaction: transactions[i],
                onTap: () => context.go('/logs/${transactions[i].id}'),
              ),
              if (i != transactions.length - 1)
                const Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: Color(0xFFEAF0EC),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.income,
    required this.expenses,
  });

  final DateTime date;
  final double income;
  final double expenses;

  @override
  Widget build(BuildContext context) {
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFDDEDE4),
        border: Border(
          top: BorderSide(color: Color(0xFFC8DDCF)),
          bottom: BorderSide(color: Color(0xFFC8DDCF)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                DateFormat('d').format(date),
                style: const TextStyle(
                  color: MoniTheme.ink,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: isWeekend ? MoniTheme.softGreen : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MoniTheme.line),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  DateFormat('E').format(date),
                  style: TextStyle(
                    color: isWeekend ? MoniTheme.primaryGreen : MoniTheme.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('MM.yyyy').format(date),
              style: const TextStyle(
                color: MoniTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            _DailyAmount(value: income, color: MoniTheme.primaryGreen),
            const SizedBox(width: 18),
            _DailyAmount(value: expenses, color: MoniTheme.deepGreen),
          ],
        ),
      ),
    );
  }
}

class _DailyAmount extends StatelessWidget {
  const _DailyAmount({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: FittedBox(
        child: Text(
          CurrencyFormatter.compact(value),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TransactionCompactRow extends StatelessWidget {
  const _TransactionCompactRow({
    required this.transaction,
    required this.onTap,
  });

  final TransactionModel transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? MoniTheme.primaryGreen : MoniTheme.deepGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  _categoryEmoji(transaction.category),
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  _categoryName(transaction.category),
                  style: const TextStyle(
                    color: MoniTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  transaction.account,
                  style: const TextStyle(
                    color: MoniTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: FittedBox(
                  child: Text(
                    CurrencyFormatter.compact(transaction.amount),
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
