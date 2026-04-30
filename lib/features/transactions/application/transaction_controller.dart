import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/transaction_model.dart';

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, List<TransactionModel>>((ref) {
      return TransactionController();
    });

class TransactionController extends StateNotifier<List<TransactionModel>> {
  TransactionController() : super(_mockTransactions);

  static const _uuid = Uuid();

  void addTransaction({
    required String category,
    required String account,
    required double amount,
    required TransactionType type,
    DateTime? date,
    String? note,
  }) {
    state = [
      TransactionModel(
        id: _uuid.v4(),
        category: category,
        account: account,
        amount: amount,
        type: type,
        date: date ?? DateTime.now(),
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      ),
      ...state,
    ];
  }

  void updateTransaction(TransactionModel transaction) {
    state = [
      for (final item in state)
        if (item.id == transaction.id) transaction else item,
    ];
  }

  void deleteTransaction(String id) {
    state = state.where((item) => item.id != id).toList();
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
    if (category.isEmpty) {
      return;
    }
    if (type == TransactionType.income) {
      if (state.incomeCategories.contains(category)) {
        return;
      }
      state = state.copyWith(
        incomeCategories: [...state.incomeCategories, category],
      );
      return;
    }
    if (state.expenseCategories.contains(category)) {
      return;
    }
    state = state.copyWith(
      expenseCategories: [...state.expenseCategories, category],
    );
  }

  void editCategory(TransactionType type, String oldValue, String newValue) {
    final category = newValue.trim();
    if (category.isEmpty) {
      return;
    }
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
    if (account.isEmpty || state.accounts.contains(account)) {
      return;
    }
    state = state.copyWith(accounts: [...state.accounts, account]);
  }

  void editAccount(String oldValue, String newValue) {
    final account = newValue.trim();
    if (account.isEmpty) {
      return;
    }
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

final _mockTransactions = [
  TransactionModel(
    id: 'tx-1',
    category: 'Salary',
    account: 'Bank Account',
    amount: 4200,
    type: TransactionType.income,
    date: DateTime.now().subtract(const Duration(days: 1)),
    note: 'April payroll',
  ),
  TransactionModel(
    id: 'tx-2',
    category: 'Food',
    account: 'Card',
    amount: 86.40,
    type: TransactionType.expense,
    date: DateTime.now().subtract(const Duration(days: 2)),
    note: 'Weekly groceries',
  ),
  TransactionModel(
    id: 'tx-3',
    category: 'Transport',
    account: 'Cash',
    amount: 34,
    type: TransactionType.expense,
    date: DateTime.now().subtract(const Duration(days: 4)),
  ),
  TransactionModel(
    id: 'tx-4',
    category: 'Freelance',
    account: 'Bank Account',
    amount: 620,
    type: TransactionType.income,
    date: DateTime.now().subtract(const Duration(days: 6)),
    note: 'Landing page mockups',
  ),
];
