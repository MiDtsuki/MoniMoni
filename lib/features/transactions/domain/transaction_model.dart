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

  TransactionModel copyWith({
    String? id,
    String? category,
    String? account,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      category: category ?? this.category,
      account: account ?? this.account,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
