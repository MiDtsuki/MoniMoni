import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/debts/domain/guest_debt_note_model.dart';
import '../../features/transactions/domain/transaction_model.dart';

final guestStoreProvider = Provider<GuestStore>((_) => GuestStore());

class GuestStore {
  static const _transactionsKey = 'guest_transactions';
  static const _debtNotesKey = 'guest_debt_notes';

  Future<List<TransactionModel>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    if (raw == null || raw.isEmpty) return [];
    final items = jsonDecode(raw) as List<dynamic>;
    return items
        .map((item) => _transactionFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _transactionsKey,
      jsonEncode(transactions.map(_transactionToJson).toList()),
    );
  }

  Future<List<GuestDebtNoteModel>> loadDebtNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_debtNotesKey);
    if (raw == null || raw.isEmpty) return [];
    final items = jsonDecode(raw) as List<dynamic>;
    return items
        .map(
          (item) => GuestDebtNoteModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveDebtNotes(List<GuestDebtNoteModel> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _debtNotesKey,
      jsonEncode(notes.map((note) => note.toJson()).toList()),
    );
  }
}

Map<String, dynamic> _transactionToJson(TransactionModel transaction) {
  return {
    'id': transaction.id,
    'category': transaction.category,
    'account': transaction.account,
    'amount': transaction.amount,
    'type': transaction.type == TransactionType.income ? 'income' : 'expense',
    'date': transaction.date.toIso8601String(),
    'note': transaction.note,
  };
}

TransactionModel _transactionFromJson(Map<String, dynamic> json) {
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
