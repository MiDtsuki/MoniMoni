import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/session_providers.dart';
import '../../../features/profile/application/profile_settings_controller.dart';
import '../domain/debt_model.dart';
import '../domain/settlement_payment_info.dart';

// Watch user?.uid (a String) instead of the full User object so the controller
// only rebuilds when the logged-in account actually changes.
final debtControllerProvider = StateNotifierProvider<DebtController, DebtState>(
  (ref) {
    final isGuest = ref.watch(isGuestModeProvider);
    if (isGuest) {
      return DebtController.guest(ref);
    }
    final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
    if (uid == null) {
      return DebtController.guest(ref);
    }
    return DebtController.remote(ref, uid);
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
  DebtController.remote(this._ref, this._userId)
    : _isGuest = false,
      super(const DebtState(debts: [], requests: [])) {
    _load();
    _subscribeToRemoteChanges();
  }

  DebtController.guest(this._ref)
    : _userId = null,
      _isGuest = true,
      super(const DebtState(debts: [], requests: []));

  final Ref _ref;
  final String? _userId;
  final bool _isGuest;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  int _loadGeneration = 0;

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> refresh() => _load();

  void _subscribeToRemoteChanges() {
    if (_isGuest || _userId == null) return;
    _subscriptions.add(
      _db
          .collection('inbox_items')
          .where('recipient_id', isEqualTo: _userId)
          .snapshots()
          .listen((_) => _load()),
    );
    _subscriptions.add(
      _db
          .collection('debts')
          .where('participants', arrayContains: _userId)
          .snapshots()
          .listen((_) => _load()),
    );
  }

  Future<void> _load() async {
    final gen = ++_loadGeneration;

    try {
      await _applyOverdueCreditPenalties();
      _ref.read(profileSettingsProvider.notifier).refresh();
    } catch (_) {}

    try {
      final userId = _userId;
      if (userId == null) return;

      final debtSnapshot = await _db
          .collection('debts')
          .where('participants', arrayContains: userId)
          .get();

      final debts = debtSnapshot.docs
          .map((doc) => DebtModel.fromMap(doc.id, doc.data(), userId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final debtsById = {for (final d in debts) d.id: d};

      // Single-field query avoids composite index requirements. Status and type
      // filtering is done in Dart below.
      final inboxSnapshot = await _db
          .collection('inbox_items')
          .where('recipient_id', isEqualTo: userId)
          .get();

      final requests = <DebtRequestModel>[];
      for (final doc in inboxSnapshot.docs) {
        final data = doc.data();
        if ((data['status'] as String?) != 'pending') continue;
        final type = data['type'] as String? ?? '';
        if (type != 'debt_request' &&
            type != 'settlement_request' &&
            type != 'debt_accepted' &&
            type != 'debt_declined') {
          continue;
        }

        final payload = (data['payload'] as Map<String, dynamic>? ??
                const <String, dynamic>{})
            .cast<String, dynamic>();
        final senderId = data['sender_id'] as String? ?? '';
        final createdAt = _readDate(data['created_at']);

        if (type == 'debt_request') {
          final debtId = payload['debt_id'] as String?;
          final debt = debtId != null ? debtsById[debtId] : null;
          requests.add(
            DebtRequestModel(
              id: doc.id,
              type: DebtRequestType.debt,
              friendId: senderId,
              createdAt: createdAt,
              title: debt?.isLent == true ? 'Lend request' : 'Borrow request',
              description: debt?.isLent == true
                  ? 'Approve money lent to this friend.'
                  : 'Approve money borrowed from this friend.',
              debt: debt,
            ),
          );
        } else if (type == 'settlement_request') {
          final debtIds =
              (payload['debt_ids'] as List<dynamic>? ?? []).cast<String>();
          requests.add(
            DebtRequestModel(
              id: doc.id,
              type: DebtRequestType.settlement,
              friendId: senderId,
              createdAt: createdAt,
              title: debtIds.length > 1
                  ? 'Settle all request'
                  : 'Settlement request',
              description: debtIds.length > 1
                  ? 'Approve settlement for all active debts with this friend.'
                  : 'Approve settlement for one debt transaction.',
              debtIds: debtIds,
              paymentInfo: SettlementPaymentInfo.fromJson(
                payload['payment'] as Map<String, dynamic>?,
              ),
            ),
          );
        } else {
          // debt_accepted or debt_declined — notification back to the sender.
          final debtId = payload['debt_id'] as String?;
          final debt = debtId != null ? debtsById[debtId] : null;
          requests.add(
            DebtRequestModel(
              id: doc.id,
              type: type == 'debt_accepted'
                  ? DebtRequestType.debtAccepted
                  : DebtRequestType.debtDeclined,
              friendId: senderId,
              createdAt: createdAt,
              title: type == 'debt_accepted'
                  ? 'Debt request accepted'
                  : 'Debt request declined',
              description: type == 'debt_accepted'
                  ? 'Your friend accepted your debt request.'
                  : 'Your friend declined your debt request.',
              debt: debt,
            ),
          );
        }
      }

      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted && gen == _loadGeneration) {
        state = DebtState(debts: debts, requests: requests);
      }
    } catch (error, stackTrace) {
      debugPrint('DebtController load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> createDebtRequest({
    required String friendId,
    required double amount,
    required DebtDirection direction,
    required DateTime createdAt,
    required DateTime deadline,
    String? note,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not signed in');
    final dbDirection = direction == DebtDirection.owedToMe ? 'lend' : 'borrow';
    final debtRef = _db.collection('debts').doc();
    final inboxRef = _db.collection('inbox_items').doc();

    final debtData = <String, dynamic>{
      'owner_id': userId,
      'counterpart_id': friendId,
      'participants': [userId, friendId],
      'direction': dbDirection,
      'amount': amount,
      'description': note?.trim().isEmpty ?? true ? null : note?.trim(),
      'status': 'pending',
      'deadline': Timestamp.fromDate(
        DateTime.utc(deadline.year, deadline.month, deadline.day),
      ),
      'created_at': Timestamp.fromDate(createdAt.toUtc()),
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Batch the debt doc and the inbox notification so they land
    // atomically — prevents the recipient's _load() from running
    // before the inbox item exists (which left request.debt == null).
    final batch = _db.batch();
    batch.set(debtRef, debtData);
    batch.set(inboxRef, {
      'recipient_id': friendId,
      'sender_id': userId,
      'type': 'debt_request',
      'payload': {'debt_id': debtRef.id},
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    final debt = DebtModel.fromMap(debtRef.id, debtData, userId);
    if (mounted) {
      state = state.copyWith(debts: [debt, ...state.debts]);
    }
  }

  Future<void> acceptDebtRequest(String requestId) async {
    final request =
        state.requests.where((item) => item.id == requestId).firstOrNull;
    if (request == null) return;
    final debt = request.debt;
    if (debt == null) return;

    // Atomically activate the debt, close the inbox item, and notify the sender.
    final batch = _db.batch();
    batch.set(
      _db.collection('debts').doc(debt.id),
      {'status': 'active', 'updated_at': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection('inbox_items').doc(requestId),
      {'status': 'accepted'},
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection('inbox_items').doc(),
      {
        'recipient_id': debt.friendId,
        'sender_id': _userId!,
        'type': 'debt_accepted',
        'payload': {'debt_id': debt.id},
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();

    if (mounted) {
      state = state.copyWith(
        debts: [
          for (final d in state.debts)
            d.id == debt.id ? d.copyWith(status: DebtStatus.active) : d,
        ],
        requests: state.requests.where((item) => item.id != requestId).toList(),
      );
    }
  }

  Future<void> declineDebtRequest(String requestId) async {
    final request =
        state.requests.where((item) => item.id == requestId).firstOrNull;
    final debt = request?.debt;

    // Atomically close the inbox item, delete the debt, and notify the sender.
    final batch = _db.batch();
    batch.set(
      _db.collection('inbox_items').doc(requestId),
      {'status': 'declined'},
      SetOptions(merge: true),
    );
    if (debt != null) {
      batch.delete(_db.collection('debts').doc(debt.id));
      batch.set(
        _db.collection('inbox_items').doc(),
        {
          'recipient_id': debt.friendId,
          'sender_id': _userId!,
          'type': 'debt_declined',
          'payload': {'debt_id': debt.id},
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();

    if (mounted) {
      state = state.copyWith(
        debts: debt != null
            ? state.debts.where((d) => d.id != debt.id).toList()
            : state.debts,
        requests: state.requests.where((item) => item.id != requestId).toList(),
      );
    }
  }

  Future<void> dismissDebtNotification(String requestId) async {
    await _db.collection('inbox_items').doc(requestId).set(
      {'status': 'dismissed'},
      SetOptions(merge: true),
    );
    if (mounted) {
      state = state.copyWith(
        requests: state.requests.where((item) => item.id != requestId).toList(),
      );
    }
  }

  Future<void> createSettlementRequest(
    String debtId, {
    SettlementPaymentInfo paymentInfo = const SettlementPaymentInfo.cash(),
  }) async {
    final debt =
        state.debts.where((item) => item.id == debtId).firstOrNull;
    if (debt == null) return;
    await _db.collection('inbox_items').add({
      'recipient_id': debt.friendId,
      'sender_id': _userId!,
      'type': 'settlement_request',
      'payload': {
        'debt_ids': [debtId],
        'payment': paymentInfo.toJson(),
      },
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createSettleAllRequest(
    String friendId, {
    SettlementPaymentInfo paymentInfo = const SettlementPaymentInfo.cash(),
  }) async {
    final debtIds = state.debts
        .where((d) => d.friendId == friendId && d.status == DebtStatus.active)
        .map((d) => d.id)
        .toList();
    if (debtIds.isEmpty) return;
    await _db.collection('inbox_items').add({
      'recipient_id': friendId,
      'sender_id': _userId!,
      'type': 'settlement_request',
      'payload': {'debt_ids': debtIds, 'payment': paymentInfo.toJson()},
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptSettlementRequest(String requestId) async {
    final request =
        state.requests.where((item) => item.id == requestId).firstOrNull;
    if (request == null) return;
    final targetIds = request.debtIds.toSet().toList();
    final settledAt = DateTime.now().toUtc();

    await _settleDebtsWithCreditScoring(targetIds, settledAt);
    await _db.collection('inbox_items').doc(requestId).set({
      'status': 'accepted',
    }, SetOptions(merge: true));

    if (mounted) {
      state = state.copyWith(
        debts: [
          for (final d in state.debts)
            targetIds.contains(d.id)
                ? d.copyWith(status: DebtStatus.settled, settledAt: settledAt)
                : d,
        ],
        requests: state.requests.where((item) => item.id != requestId).toList(),
      );
    }
    _ref.read(profileSettingsProvider.notifier).refresh();
  }

  Future<void> declineSettlementRequest(String requestId) async {
    await _db.collection('inbox_items').doc(requestId).set({
      'status': 'declined',
    }, SetOptions(merge: true));
    if (mounted) {
      state = state.copyWith(
        requests: state.requests.where((item) => item.id != requestId).toList(),
      );
    }
  }

  Future<void> _applyOverdueCreditPenalties({
    DateTime? now,
    Set<String>? onlyDebtIds,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final snapshot = await _db
        .collection('debts')
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .get();

    final current = now?.toUtc() ?? DateTime.now().toUtc();
    for (final doc in snapshot.docs) {
      if (onlyDebtIds != null && !onlyDebtIds.contains(doc.id)) continue;

      final data = doc.data();
      final deadlineValue = data['deadline'];
      if (deadlineValue == null) continue;

      final deadline = _readDate(deadlineValue).toUtc();
      final dueAt = DateTime.utc(
        deadline.year,
        deadline.month,
        deadline.day + 1,
      );
      if (current.isBefore(dueAt)) continue;

      final borrower = _borrowerId(data);
      final missedEventId = '${doc.id}_missed_deadline';
      await _applyCreditScoreEvent(
        eventId: missedEventId,
        userId: borrower,
        debtId: doc.id,
        eventType: 'missed_deadline',
        points: -5,
        eventDate: DateTime.utc(deadline.year, deadline.month, deadline.day),
      );

      final fullOverdueDays = current.difference(dueAt).inDays;
      for (var dayOffset = 1; dayOffset <= fullOverdueDays; dayOffset++) {
        final eventDate = DateTime.utc(
          deadline.year,
          deadline.month,
          deadline.day + dayOffset,
        );
        await _applyCreditScoreEvent(
          eventId:
              '${doc.id}_overdue_day_${eventDate.toIso8601String().split('T').first}',
          userId: borrower,
          debtId: doc.id,
          eventType: 'overdue_day',
          points: -1,
          eventDate: eventDate,
        );
      }
    }
  }

  Future<void> _settleDebtsWithCreditScoring(
    List<String> debtIds,
    DateTime settledAt,
  ) async {
    final userId = _userId;
    if (userId == null || debtIds.isEmpty) return;

    await _applyOverdueCreditPenalties(
      now: settledAt,
      onlyDebtIds: debtIds.toSet(),
    );

    for (final debtId in debtIds) {
      final debtRef = _db.collection('debts').doc(debtId);
      final snapshot = await debtRef.get();
      if (!snapshot.exists) continue;

      final data = snapshot.data()!;
      final participants =
          (data['participants'] as List<dynamic>? ?? const []).cast<String>();
      if (!participants.contains(userId)) continue;
      if ((data['status'] as String? ?? '') == 'settled') continue;

      final deadlineValue = data['deadline'];
      if (deadlineValue != null) {
        final deadline = _readDate(deadlineValue).toUtc();
        final dueAt = DateTime.utc(
          deadline.year,
          deadline.month,
          deadline.day + 1,
        );
        if (settledAt.isBefore(dueAt)) {
          await _applyCreditScoreEvent(
            eventId: '${debtId}_on_time_settlement',
            userId: _borrowerId(data),
            debtId: debtId,
            eventType: 'on_time_settlement',
            points: 3,
            eventDate: settledAt,
          );
        }
      }

      await debtRef.set({
        'status': 'settled',
        'settled_at': Timestamp.fromDate(settledAt),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _applyCreditScoreEvent({
    required String eventId,
    required String userId,
    required String debtId,
    required String eventType,
    required int points,
    required DateTime eventDate,
  }) async {
    final eventRef = _db.collection('credit_score_events').doc(eventId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((tx) async {
      final eventSnapshot = await tx.get(eventRef);
      if (eventSnapshot.exists) return;

      final userSnapshot = await tx.get(userRef);
      final currentScore =
          (userSnapshot.data()?['credit_score'] as num?)?.toInt() ?? 100;
      final nextScore = (currentScore + points).clamp(0, 100);

      tx.set(eventRef, {
        'user_id': userId,
        'debt_id': debtId,
        'event_type': eventType,
        'points': points,
        'event_date': Timestamp.fromDate(
          DateTime.utc(eventDate.year, eventDate.month, eventDate.day),
        ),
        'created_at': FieldValue.serverTimestamp(),
      });
      tx.set(userRef, {'credit_score': nextScore}, SetOptions(merge: true));
    });
  }

  String _borrowerId(Map<String, dynamic> debtData) {
    final ownerId = debtData['owner_id'] as String? ?? '';
    final counterpartId = debtData['counterpart_id'] as String? ?? '';
    final direction = debtData['direction'] as String? ?? 'borrow';
    return direction == 'lend' ? counterpartId : ownerId;
  }

  DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

final totalLentProvider = Provider<double>((ref) {
  return ref
      .watch(debtControllerProvider)
      .debts
      .where((debt) => debt.status == DebtStatus.active && debt.isLent)
      .fold(0, (total, debt) => total + debt.amount);
});

final totalBorrowedProvider = Provider<double>((ref) {
  return ref
      .watch(debtControllerProvider)
      .debts
      .where((debt) => debt.status == DebtStatus.active && !debt.isLent)
      .fold(0, (total, debt) => total + debt.amount);
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
      .fold(0, (total, debt) => total + debt.amount);
}

double borrowedFromFriend(Iterable<DebtModel> debts) {
  return debts
      .where((debt) => debt.status == DebtStatus.active && !debt.isLent)
      .fold(0, (total, debt) => total + debt.amount);
}
