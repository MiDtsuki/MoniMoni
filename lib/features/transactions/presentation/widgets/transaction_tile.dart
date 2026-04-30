import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/moni_card.dart';
import '../../domain/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, super.key});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? MoniTheme.primaryGreen : const Color(0xFF202722);

    return MoniCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isIncome
                ? MoniTheme.softGreen
                : const Color(0xFFF0F2EF),
            child: Icon(
              isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.category,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}${CurrencyFormatter.compact(transaction.amount)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      label: isIncome ? 'Income' : 'Expense',
                      icon: isIncome
                          ? LucideIcons.arrowDownLeft
                          : LucideIcons.arrowUpRight,
                    ),
                    _Chip(label: transaction.account, icon: LucideIcons.wallet),
                    _Chip(
                      label: DateFormat(
                        'MMM d, yyyy h:mm a',
                      ).format(transaction.date),
                      icon: LucideIcons.calendarClock,
                    ),
                  ],
                ),
                if (transaction.note != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    transaction.note!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: MoniTheme.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: MoniTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
