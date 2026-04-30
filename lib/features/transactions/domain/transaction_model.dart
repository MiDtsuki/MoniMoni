import 'package:flutter/foundation.dart';

enum TransactionType { income, expense }

@immutable
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.category,
    required this.account,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
  });

  final String id;
  final String category;
  final String account;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? note;

  bool get isIncome => type == TransactionType.income;
}
