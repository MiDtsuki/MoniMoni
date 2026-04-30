import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/debt_model.dart';

final debtControllerProvider = StateNotifierProvider<DebtController, DebtState>(
  (ref) {
    return DebtController();
  },
);

class DebtState {
  const DebtState({required this.debts, required this.requests});

  final List<DebtModel> debts;
  final List<DebtRequestModel> requests;

  List<DebtRequestModel> get pendingRequests => requests;

  DebtState copyWith({
    List<DebtModel>? debts,
    List<DebtRequestModel>? requests,
  }) {
    return DebtState(
      debts: debts ?? this.debts,
      requests: requests ?? this.requests,
    );
  }
}

class DebtController extends StateNotifier<DebtState> {
  DebtController()
    : super(DebtState(debts: _mockDebts, requests: _mockRequests));

  static const _uuid = Uuid();

  void createDebtRequest({
    required String friendId,
    required double amount,
    required DebtDirection direction,
    required DateTime createdAt,
    DateTime? deadline,
    String? note,
  }) {
    final debt = DebtModel(
      id: _uuid.v4(),
      friendId: friendId,
      amount: amount,
      direction: direction,
      status: DebtStatus.pending,
      createdAt: createdAt,
      deadline: deadline,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
    );
    state = state.copyWith(
      requests: [
        DebtRequestModel(
          id: _uuid.v4(),
          type: DebtRequestType.debt,
          friendId: friendId,
          createdAt: DateTime.now(),
          title: direction == DebtDirection.owedToMe
              ? 'Lend request'
              : 'Borrow request',
          description: direction == DebtDirection.owedToMe
              ? 'Approve money lent to this friend.'
              : 'Approve money borrowed from this friend.',
          debt: debt,
        ),
        ...state.requests,
      ],
    );
  }

  void acceptDebtRequest(String requestId) {
    final request = state.requests.firstWhere((item) => item.id == requestId);
    final debt = request.debt;
    if (debt == null) {
      return;
    }
    state = state.copyWith(
      debts: [
        debt.copyWith(status: DebtStatus.active),
        ...state.debts,
      ],
      requests: state.requests.where((item) => item.id != requestId).toList(),
    );
  }

  void declineDebtRequest(String requestId) {
    state = state.copyWith(
      requests: state.requests.where((item) => item.id != requestId).toList(),
    );
  }

  void createSettlementRequest(String debtId) {
    final debt = state.debts.firstWhere((item) => item.id == debtId);
    state = state.copyWith(
      requests: [
        DebtRequestModel(
          id: _uuid.v4(),
          type: DebtRequestType.settlement,
          friendId: debt.friendId,
          createdAt: DateTime.now(),
          title: 'Settlement request',
          description: 'Approve settlement for one debt transaction.',
          debtIds: [debtId],
        ),
        ...state.requests,
      ],
    );
  }

  void createSettleAllRequest(String friendId) {
    final debtIds = state.debts
        .where(
          (debt) =>
              debt.friendId == friendId && debt.status == DebtStatus.active,
        )
        .map((debt) => debt.id)
        .toList();
    if (debtIds.isEmpty) {
      return;
    }
    state = state.copyWith(
      requests: [
        DebtRequestModel(
          id: _uuid.v4(),
          type: DebtRequestType.settlement,
          friendId: friendId,
          createdAt: DateTime.now(),
          title: 'Settle all request',
          description:
              'Approve settlement for all active debts with this friend.',
          debtIds: debtIds,
        ),
        ...state.requests,
      ],
    );
  }

  void acceptSettlementRequest(String requestId) {
    final request = state.requests.firstWhere((item) => item.id == requestId);
    final targetIds = request.debtIds.toSet();
    state = state.copyWith(
      debts: [
        for (final debt in state.debts)
          targetIds.contains(debt.id)
              ? debt.copyWith(status: DebtStatus.settled)
              : debt,
      ],
      requests: state.requests.where((item) => item.id != requestId).toList(),
    );
  }

  void declineSettlementRequest(String requestId) {
    state = state.copyWith(
      requests: state.requests.where((item) => item.id != requestId).toList(),
    );
  }
}

final totalLentProvider = Provider<double>((ref) {
  return ref
      .watch(debtControllerProvider)
      .debts
      .where((debt) => debt.status == DebtStatus.active && debt.isLent)
      .fold(0, (sum, debt) => sum + debt.amount);
});

final totalBorrowedProvider = Provider<double>((ref) {
  return ref
      .watch(debtControllerProvider)
      .debts
      .where((debt) => debt.status == DebtStatus.active && !debt.isLent)
      .fold(0, (sum, debt) => sum + debt.amount);
});

final netDebtProvider = Provider<double>((ref) {
  return ref.watch(totalLentProvider) - ref.watch(totalBorrowedProvider);
});

List<DebtModel> debtsForFriend(DebtState state, String friendId) {
  return state.debts.where((debt) => debt.friendId == friendId).toList();
}

double lentToFriend(Iterable<DebtModel> debts) {
  return debts
      .where((debt) => debt.status == DebtStatus.active && debt.isLent)
      .fold(0, (sum, debt) => sum + debt.amount);
}

double borrowedFromFriend(Iterable<DebtModel> debts) {
  return debts
      .where((debt) => debt.status == DebtStatus.active && !debt.isLent)
      .fold(0, (sum, debt) => sum + debt.amount);
}

final _mockDebts = [
  DebtModel(
    id: 'debt-1',
    friendId: 'friend-1',
    note: 'Dinner split',
    amount: 42.50,
    direction: DebtDirection.owedToMe,
    status: DebtStatus.active,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    deadline: DateTime.now().add(const Duration(days: 3)),
  ),
  DebtModel(
    id: 'debt-2',
    friendId: 'friend-2',
    note: 'Concert tickets',
    amount: 76,
    direction: DebtDirection.iOwe,
    status: DebtStatus.active,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    deadline: DateTime.now().add(const Duration(days: 7)),
  ),
  DebtModel(
    id: 'debt-3',
    friendId: 'friend-3',
    note: 'Coffee run',
    amount: 18.25,
    direction: DebtDirection.owedToMe,
    status: DebtStatus.settled,
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
  ),
];

final _mockRequests = [
  DebtRequestModel(
    id: 'debt-request-1',
    type: DebtRequestType.debt,
    friendId: 'friend-1',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    title: 'Lend request',
    description: 'Approve money lent to this friend.',
    debt: DebtModel(
      id: 'debt-pending-1',
      friendId: 'friend-1',
      note: 'Shared lunch',
      amount: 24.75,
      direction: DebtDirection.owedToMe,
      status: DebtStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      deadline: DateTime.now().add(const Duration(days: 5)),
    ),
  ),
  DebtRequestModel(
    id: 'settlement-request-1',
    type: DebtRequestType.settlement,
    friendId: 'friend-2',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    title: 'Settlement request',
    description: 'Approve settlement for one debt transaction.',
    debtIds: ['debt-2'],
  ),
  DebtRequestModel(
    id: 'settlement-request-2',
    type: DebtRequestType.settlement,
    friendId: 'friend-1',
    createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    title: 'Settle all request',
    description: 'Approve settlement for all active debts with this friend.',
    debtIds: ['debt-1'],
  ),
];
