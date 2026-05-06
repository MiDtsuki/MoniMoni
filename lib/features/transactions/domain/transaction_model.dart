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

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      category: json['category'] as String,
      account: json['account'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  final String id;
  final String category;
  final String account;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? note;

  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toJson(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category,
      'account': account,
      'amount': amount,
      'note': note,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };
  }

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
