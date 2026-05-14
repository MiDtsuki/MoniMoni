import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/guest_store.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/providers/session_providers.dart';
import '../domain/transaction_model.dart';

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, List<TransactionModel>>((ref) {
      final isGuest = ref.watch(isGuestModeProvider);
      if (isGuest) {
        return TransactionController.guest(ref);
      }
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return TransactionController.signedOut(ref);
      }
      return TransactionController.remote(ref, user.id);
    });

class TransactionController extends StateNotifier<List<TransactionModel>> {
  TransactionController.remote(this._ref, this._userId)
    : _isGuest = false,
      super(const []) {
    _load();
  }

  TransactionController.guest(this._ref)
    : _userId = null,
      _isGuest = true,
      super(const []) {
    _load();
  }

  TransactionController.signedOut(this._ref)
    : _userId = null,
      _isGuest = false,
      super(const []);

  final Ref _ref;
  final String? _userId;
  final bool _isGuest;
  static const _uuid = Uuid();

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  GuestStore get _guestStore => _ref.read(guestStoreProvider);

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      if (_isGuest) {
        final rows = await _guestStore.loadTransactions();
        rows.sort((a, b) => b.date.compareTo(a.date));
        if (mounted) state = rows;
        return;
      }
      final rows = await _client
          .from('transactions')
          .select()
          .eq('user_id', _userId!)
          .isFilter('deleted_at', null)
          .order('date', ascending: false)
          .order('created_at', ascending: false);
      if (mounted) {
        state = (rows as List)
            .map((r) => TransactionModel.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

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
      if (_isGuest) {
        await _guestStore.saveTransactions(state);
      } else {
        await _client.from('transactions').insert(tx.toJson(_userId!));
      }
    } catch (e) {
      if (mounted) state = state.where((item) => item.id != tx.id).toList();
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final prev = state.firstWhere((item) => item.id == transaction.id);
    state = [
      for (final item in state)
        if (item.id == transaction.id) transaction else item,
    ];
    try {
      if (_isGuest) {
        await _guestStore.saveTransactions(state);
      } else {
        await _client
            .from('transactions')
            .update(transaction.toJson(_userId!))
            .eq('id', transaction.id);
      }
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

  Future<void> deleteTransaction(String id) async {
    final prev = state.firstWhere((item) => item.id == id);
    state = state.where((item) => item.id != id).toList();
    try {
      if (_isGuest) {
        await _guestStore.saveTransactions(state);
      } else {
        await _client
            .from('transactions')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', id);
      }
    } catch (e) {
      if (mounted) state = [prev, ...state];
      rethrow;
    }
  }
}

final transactionOptionsProvider =
    StateNotifierProvider<TransactionOptionsController, TransactionOptions>(
      (ref) => TransactionOptionsController(),
    );

class TransactionOptions {
  const TransactionOptions({
    required this.expenseCategories,
    required this.incomeCategories,
    required this.accounts,
  });

  final List<String> expenseCategories;
  final List<String> incomeCategories;
  final List<String> accounts;

  List<String> categoriesFor(TransactionType type) {
    return type == TransactionType.income
        ? incomeCategories
        : expenseCategories;
  }

  TransactionOptions copyWith({
    List<String>? expenseCategories,
    List<String>? incomeCategories,
    List<String>? accounts,
  }) {
    return TransactionOptions(
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      accounts: accounts ?? this.accounts,
    );
  }
}

class TransactionOptionsController extends StateNotifier<TransactionOptions> {
  TransactionOptionsController()
    : super(
        const TransactionOptions(
          expenseCategories: [
            'Food',
            'Transport',
            'Shopping',
            'Bills',
            'Education',
            'Health',
            'Entertainment',
            'Other',
          ],
          incomeCategories: [
            'Salary',
            'Allowance',
            'Freelance',
            'Gift',
            'Other',
          ],
          accounts: ['Cash', 'Bank Account', 'Card'],
        ),
      );

  void addCategory(TransactionType type, String value) {
    final category = value.trim();
    if (category.isEmpty) return;
    if (type == TransactionType.income) {
      if (state.incomeCategories.contains(category)) return;
      state = state.copyWith(
        incomeCategories: [...state.incomeCategories, category],
      );
      return;
    }
    if (state.expenseCategories.contains(category)) return;
    state = state.copyWith(
      expenseCategories: [...state.expenseCategories, category],
    );
  }

  void editCategory(TransactionType type, String oldValue, String newValue) {
    final category = newValue.trim();
    if (category.isEmpty) return;
    if (type == TransactionType.income) {
      state = state.copyWith(
        incomeCategories: [
          for (final item in state.incomeCategories)
            item == oldValue ? category : item,
        ],
      );
      return;
    }
    state = state.copyWith(
      expenseCategories: [
        for (final item in state.expenseCategories)
          item == oldValue ? category : item,
      ],
    );
  }

  void addAccount(String value) {
    final account = value.trim();
    if (account.isEmpty || state.accounts.contains(account)) return;
    state = state.copyWith(accounts: [...state.accounts, account]);
  }

  void editAccount(String oldValue, String newValue) {
    final account = newValue.trim();
    if (account.isEmpty) return;
    state = state.copyWith(
      accounts: [
        for (final item in state.accounts) item == oldValue ? account : item,
      ],
    );
  }
}

final totalIncomeProvider = Provider<double>((ref) {
  return ref
      .watch(transactionControllerProvider)
      .where((item) => item.type == TransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  return ref
      .watch(transactionControllerProvider)
      .where((item) => item.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);
});

final balanceProvider = Provider<double>((ref) {
  return ref.watch(totalIncomeProvider) - ref.watch(totalExpenseProvider);
});

final monthlyTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final now = DateTime.now();
  return ref.watch(transactionControllerProvider).where((item) {
    return item.date.year == now.year && item.date.month == now.month;
  }).toList();
});

final monthlyIncomeProvider = Provider<double>((ref) {
  return ref
      .watch(monthlyTransactionsProvider)
      .where((item) => item.type == TransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);
});

final monthlyExpenseProvider = Provider<double>((ref) {
  return ref
      .watch(monthlyTransactionsProvider)
      .where((item) => item.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);
});

final monthlyBalanceProvider = Provider<double>((ref) {
  return ref.watch(monthlyIncomeProvider) - ref.watch(monthlyExpenseProvider);
});
