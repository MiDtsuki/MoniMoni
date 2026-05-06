import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../domain/debt_model.dart';

final debtControllerProvider = StateNotifierProvider<DebtController, DebtState>(
  (ref) => DebtController(ref),
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
  DebtController(this._ref)
      : super(const DebtState(debts: [], requests: [])) {
    _load();
  }

  final Ref _ref;

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String get _userId => _ref.read(currentUserIdProvider);

  Future<void> _load() async {
    try {
      final userId = _userId;

      final debtRows = await _client
          .from('debts')
          .select()
          .or('owner_id.eq.$userId,counterpart_id.eq.$userId')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final debts = (debtRows as List)
          .map((r) => DebtModel.fromJson(r as Map<String, dynamic>, userId))
          .toList();
      final debtsById = {for (final d in debts) d.id: d};

      final inboxRows = await _client
          .from('inbox_items')
          .select()
          .eq('recipient_id', userId)
          .eq('status', 'pending')
          .inFilter('type', ['debt_request', 'settlement_request'])
          .order('created_at', ascending: false);

      final requests = <DebtRequestModel>[];
      for (final row in (inboxRows as List)) {
        final r = row as Map<String, dynamic>;
        final type = r['type'] as String;
        final payload = r['payload'] as Map<String, dynamic>;
        final senderId = r['sender_id'] as String;
        final createdAt = DateTime.parse(r['created_at'] as String);

        if (type == 'debt_request') {
          final debtId = payload['debt_id'] as String?;
          final debt = debtId != null ? debtsById[debtId] : null;
          requests.add(DebtRequestModel(
            id: r['id'] as String,
            type: DebtRequestType.debt,
            friendId: senderId,
            createdAt: createdAt,
            title: debt?.isLent == true ? 'Lend request' : 'Borrow request',
            description: debt?.isLent == true
                ? 'Approve money lent to this friend.'
                : 'Approve money borrowed from this friend.',
            debt: debt,
          ));
        } else if (type == 'settlement_request') {
          final debtIds =
              (payload['debt_ids'] as List<dynamic>? ?? []).cast<String>();
          requests.add(DebtRequestModel(
            id: r['id'] as String,
            type: DebtRequestType.settlement,
            friendId: senderId,
            createdAt: createdAt,
            title:
                debtIds.length > 1 ? 'Settle all request' : 'Settlement request',
            description: debtIds.length > 1
                ? 'Approve settlement for all active debts with this friend.'
                : 'Approve settlement for one debt transaction.',
            debtIds: debtIds,
          ));
        }
      }

      if (mounted) {
        state = DebtState(debts: debts, requests: requests);
      }
    } catch (_) {}
  }

  Future<void> createDebtRequest({
    required String friendId,
    required double amount,
    required DebtDirection direction,
    required DateTime createdAt,
    DateTime? deadline,
    String? note,
  }) async {
    final userId = _userId;
    final dbDirection =
        direction == DebtDirection.owedToMe ? 'lend' : 'borrow';

    final debtRow = <String, dynamic>{
      'owner_id': userId,
      'counterpart_id': friendId,
      'direction': dbDirection,
      'amount': amount,
      'description': note?.trim().isEmpty ?? true ? null : note?.trim(),
      'status': 'pending',
      if (deadline != null)
        'deadline':
            '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
      'created_at': createdAt.toIso8601String(),
    };

    try {
      final inserted =
          await _client.from('debts').insert(debtRow).select().single();
      final debt = DebtModel.fromJson(inserted, userId);

      await _client.from('inbox_items').insert({
        'recipient_id': friendId,
        'sender_id': userId,
        'type': 'debt_request',
        'payload': {'debt_id': debt.id},
      });

      if (mounted) {
        state = state.copyWith(debts: [debt, ...state.debts]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptDebtRequest(String requestId) async {
    final request = state.requests.firstWhere((item) => item.id == requestId);
    final debt = request.debt;
    if (debt == null) return;

    try {
      await _client
          .from('debts')
          .update({'status': 'active'})
          .eq('id', debt.id);
      await _client
          .from('inbox_items')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      if (mounted) {
        state = state.copyWith(
          debts: [
            for (final d in state.debts)
              d.id == debt.id ? d.copyWith(status: DebtStatus.active) : d,
          ],
          requests:
              state.requests.where((item) => item.id != requestId).toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> declineDebtRequest(String requestId) async {
    try {
      await _client
          .from('inbox_items')
          .update({'status': 'declined'})
          .eq('id', requestId);
      if (mounted) {
        state = state.copyWith(
          requests:
              state.requests.where((item) => item.id != requestId).toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> createSettlementRequest(String debtId) async {
    final debt = state.debts.firstWhere((item) => item.id == debtId);
    try {
      await _client.from('inbox_items').insert({
        'recipient_id': debt.friendId,
        'sender_id': _userId,
        'type': 'settlement_request',
        'payload': {
          'debt_ids': [debtId],
        },
      });
    } catch (_) {}
  }

  Future<void> createSettleAllRequest(String friendId) async {
    final debtIds = state.debts
        .where((d) => d.friendId == friendId && d.status == DebtStatus.active)
        .map((d) => d.id)
        .toList();
    if (debtIds.isEmpty) return;
    try {
      await _client.from('inbox_items').insert({
        'recipient_id': friendId,
        'sender_id': _userId,
        'type': 'settlement_request',
        'payload': {'debt_ids': debtIds},
      });
    } catch (_) {}
  }

  Future<void> acceptSettlementRequest(String requestId) async {
    final request = state.requests.firstWhere((item) => item.id == requestId);
    final targetIds = request.debtIds.toSet();

    try {
      for (final id in targetIds) {
        await _client
            .from('debts')
            .update({'status': 'settled'})
            .eq('id', id);
      }
      await _client
          .from('inbox_items')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      if (mounted) {
        state = state.copyWith(
          debts: [
            for (final d in state.debts)
              targetIds.contains(d.id)
                  ? d.copyWith(status: DebtStatus.settled)
                  : d,
          ],
          requests:
              state.requests.where((item) => item.id != requestId).toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> declineSettlementRequest(String requestId) async {
    try {
      await _client
          .from('inbox_items')
          .update({'status': 'declined'})
          .eq('id', requestId);
      if (mounted) {
        state = state.copyWith(
          requests:
              state.requests.where((item) => item.id != requestId).toList(),
        );
      }
    } catch (_) {}
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
