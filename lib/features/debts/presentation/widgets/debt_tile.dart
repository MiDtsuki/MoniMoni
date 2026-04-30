import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/debt_model.dart';

class DebtTransactionCard extends StatelessWidget {
  const DebtTransactionCard({
    required this.debt,
    required this.onSettle,
    super.key,
  });

  final DebtModel debt;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final isLent = debt.isLent;
    final color = isLent ? MoniTheme.primaryGreen : const Color(0xFF202722);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isLent
                      ? MoniTheme.softGreen
                      : const Color(0xFFF0F2EF),
                  child: Icon(
                    isLent
                        ? LucideIcons.arrowDownLeft
                        : LucideIcons.arrowUpRight,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLent ? 'Lend' : 'Borrow',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        DateFormat('MMM d, yyyy h:mm a').format(debt.createdAt),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.compact(debt.amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (debt.deadline != null) ...[
              const SizedBox(height: 10),
              Text(
                'Deadline ${DateFormat('MMM d, yyyy').format(debt.deadline!)}',
              ),
            ],
            if (debt.note != null) ...[
              const SizedBox(height: 8),
              Text(debt.note!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _StatusPill(status: debt.status),
                const Spacer(),
                if (debt.status == DebtStatus.active)
                  TextButton(
                    onPressed: onSettle,
                    child: const Text('Mark settled'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final DebtStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      DebtStatus.pending => 'Pending',
      DebtStatus.active => 'Active',
      DebtStatus.settled => 'Settled',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
