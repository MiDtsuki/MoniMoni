import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../transactions/application/transaction_controller.dart';
import '../../transactions/domain/transaction_model.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  late DateTime _selectedMonth;
  var _selectedType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionControllerProvider);
    final monthTransactions = transactions.where((transaction) {
      return transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month;
    }).toList();
    final incomeGroups = _categoryTotals(
      monthTransactions,
      TransactionType.income,
    );
    final expenseGroups = _categoryTotals(
      monthTransactions,
      TransactionType.expense,
    );
    final totalIncome = _sum(incomeGroups);
    final totalExpense = _sum(expenseGroups);
    final selectedGroups = _selectedType == TransactionType.income
        ? incomeGroups
        : expenseGroups;
    final selectedTotal = _selectedType == TransactionType.income
        ? totalIncome
        : totalExpense;
    final colors = _chartColors;
    final entries = selectedGroups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _MonthBar(
                          month: _selectedMonth,
                          onPrevious: () => _moveMonth(-1),
                          onNext: () => _moveMonth(1),
                        ),
                        const SizedBox(height: 22),
                        _StatsTabs(
                          selectedType: _selectedType,
                          incomeTotal: totalIncome,
                          expenseTotal: totalExpense,
                          onChanged: (type) {
                            setState(() => _selectedType = type);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  sliver: SliverToBoxAdapter(
                    child: entries.isEmpty
                        ? EmptyState(
                            title:
                                'No ${_selectedType == TransactionType.income ? 'income' : 'expenses'} this month',
                            message:
                                'Add transactions in ${DateFormat('MMMM yyyy').format(_selectedMonth)} to see category statistics.',
                            icon: LucideIcons.chartPie,
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 860;
                              final chart = _LargePiePanel(
                                entries: entries,
                                total: selectedTotal,
                                colors: colors,
                              );
                              final list = _BreakdownList(
                                entries: entries,
                                total: selectedTotal,
                                colors: colors,
                              );

                              if (wide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 5, child: chart),
                                    const SizedBox(width: 18),
                                    Expanded(flex: 4, child: list),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  chart,
                                  const SizedBox(height: 16),
                                  list,
                                ],
                              );
                            },
                          ),
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

  Map<String, double> _categoryTotals(
    List<TransactionModel> transactions,
    TransactionType type,
  ) {
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type != type) {
        continue;
      }
      totals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return totals;
  }

  double _sum(Map<String, double> groups) {
    return groups.values.fold(0, (sum, value) => sum + value);
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

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
          child: Text(
            DateFormat('MMM yyyy').format(month),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: MoniTheme.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text('Monthly', style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, size: 18),
              ],
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

class _StatsTabs extends StatelessWidget {
  const _StatsTabs({
    required this.selectedType,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.onChanged,
  });

  final TransactionType selectedType;
  final double incomeTotal;
  final double expenseTotal;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MoniTheme.line)),
      ),
      child: Row(
        children: [
          _StatsTab(
            label: 'Income',
            total: incomeTotal,
            selected: selectedType == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
          ),
          _StatsTab(
            label: 'Expenses',
            total: expenseTotal,
            selected: selectedType == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({
    required this.label,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FittedBox(
                child: Text(
                  selected
                      ? '$label ${CurrencyFormatter.compact(total)}'
                      : label,
                  style: TextStyle(
                    color: selected ? MoniTheme.ink : MoniTheme.muted,
                    fontSize: 18,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 4,
              width: selected ? double.infinity : 0,
              decoration: BoxDecoration(
                color: MoniTheme.primaryGreen,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LargePiePanel extends StatelessWidget {
  const _LargePiePanel({
    required this.entries,
    required this.total,
    required this.colors,
  });

  final List<MapEntry<String, double>> entries;
  final double total;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MoniTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F174936),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            SizedBox(
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 0,
                      sectionsSpace: 2,
                      sections: [
                        for (var i = 0; i < entries.length; i++)
                          PieChartSectionData(
                            value: entries[i].value,
                            title: '',
                            radius: 118,
                            color: colors[i % colors.length],
                          ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: _FloatingLabels(
                      entries: entries.take(3).toList(),
                      total: total,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _FloatingLabels(
                      entries: entries.skip(3).take(3).toList(),
                      total: total,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingLabels extends StatelessWidget {
  const _FloatingLabels({
    required this.entries,
    required this.total,
    this.alignEnd = false,
  });

  final List<MapEntry<String, double>> entries;
  final double total;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_categoryEmoji(entry.key)} ${_categoryName(entry.key)} ${NumberFormat.percentPattern().format(total == 0 ? 0 : entry.value / total)}',
              style: const TextStyle(
                color: MoniTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _BreakdownList extends StatelessWidget {
  const _BreakdownList({
    required this.entries,
    required this.total,
    required this.colors,
  });

  final List<MapEntry<String, double>> entries;
  final double total;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MoniTheme.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _BreakdownRow(
              entry: entries[i],
              total: total,
              color: colors[i % colors.length],
            ),
            if (i != entries.length - 1)
              const Divider(height: 1, color: MoniTheme.line),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.entry,
    required this.total,
    required this.color,
  });

  final MapEntry<String, double> entry;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : entry.value / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 56,
              height: 36,
              child: Center(
                child: Text(
                  NumberFormat.percentPattern().format(percent),
                  style: TextStyle(
                    color: _readableTextOn(color),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(_categoryEmoji(entry.key), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _categoryName(entry.key),
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.compact(entry.value),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
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

const _chartColors = [
  Color(0xFFFF6B64), // coral
  Color(0xFFFF944D), // orange
  Color(0xFFFFD24A), // yellow
  Color(0xFFC7E84D), // lime
  Color(0xFF65D56E), // green
  Color(0xFF58D8CF), // teal
  Color(0xFF5CB7E5), // sky blue
  Color(0xFF7E8CE8), // indigo
  Color(0xFFA879D6), // purple
  Color(0xFFE56AA6), // pink
  Color(0xFFFF7F8C), // rose
];

Color _readableTextOn(Color color) {
  return color.computeLuminance() > 0.55 ? MoniTheme.ink : Colors.white;
}
