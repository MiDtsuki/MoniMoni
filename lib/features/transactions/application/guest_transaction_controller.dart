import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_provider.dart';
import '../../../data/local/drift_db.dart';
import '../domain/transaction_model.dart';
import 'transaction_controller.dart';

class GuestTransactionController extends BaseTransactionController {
  GuestTransactionController(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;
  static const _uuid = Uuid();

  LocalTransactionDao get _dao => _ref.read(localTransactionDaoProvider);

  Future<void> _load() async {
    try {
      final rows = await _dao.getAllActive();
      if (mounted) {
        state = rows.map(_fromRow).toList();
      }
    } catch (_) {}
  }

  @override
  Future<void> addTransaction({
    required String category,
    required String account,
    required double amount,
    required TransactionType type,
    DateTime? date,
    String? note,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(),
      category: category,
      account: account,
      amount: amount,
      type: type,
      date: date ?? DateTime.now(),
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
    );
    state = [tx, ...state];
    try {
      await _dao.upsert(_toCompanion(tx));
    } catch (e) {
      if (mounted) state = state.where((item) => item.id != tx.id).toList();
      rethrow;
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final prev = state.firstWhere((item) => item.id == transaction.id);
    state = [
      for (final item in state)
        if (item.id == transaction.id) transaction else item,
    ];
    try {
      await _dao.updateEntry(_toCompanion(transaction));
    } catch (e) {
      if (mounted) {
        state = [
          for (final item in state)
            if (item.id == prev.id) prev else item,
        ];
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final prev = state.firstWhere((item) => item.id == id);
    state = state.where((item) => item.id != id).toList();
    try {
      await _dao.softDelete(id);
    } catch (e) {
      if (mounted) state = [prev, ...state];
      rethrow;
    }
  }

  static TransactionModel _fromRow(LocalTransaction row) {
    return TransactionModel(
      id: row.id,
      category: row.category,
      account: row.account,
      amount: row.amount,
      type: row.type == 'income' ? TransactionType.income : TransactionType.expense,
      date: row.date,
      note: row.note,
    );
  }

  static LocalTransactionsCompanion _toCompanion(TransactionModel tx) {
    return LocalTransactionsCompanion(
      id: Value(tx.id),
      category: Value(tx.category),
      account: Value(tx.account),
      amount: Value(tx.amount),
      type: Value(tx.type == TransactionType.income ? 'income' : 'expense'),
      date: Value(tx.date),
      note: Value(tx.note),
    );
  }
}
