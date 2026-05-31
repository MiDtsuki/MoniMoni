import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory TransactionModel.fromMap(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      category: data['category'] as String? ?? '',
      account: data['account'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: data['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      date: _readDate(data['date']),
      note: data['note'] as String?,
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

  Map<String, dynamic> toMap() {
    return {
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category,
      'account': account,
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day)),
      'updated_at': FieldValue.serverTimestamp(),
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

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }
}
