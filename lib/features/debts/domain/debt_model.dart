import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'settlement_payment_info.dart';

enum DebtDirection { owedToMe, iOwe }

enum DebtStatus { pending, active, settled }

enum DebtRequestType {
  debt,
  settlement,
  debtAccepted,
  debtDeclined,
  settlementAccepted,
}

@immutable
class DebtModel {
  const DebtModel({
    required this.id,
    required this.friendId,
    required this.amount,
    required this.direction,
    required this.status,
    required this.createdAt,
    this.deadline,
    this.settledAt,
    this.note,
  });

  factory DebtModel.fromMap(
    String id,
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    final ownerId = data['owner_id'] as String? ?? '';
    final isOwner = ownerId == currentUserId;
    final dbDirection = data['direction'] as String? ?? 'borrow';

    final DebtDirection direction;
    final String friendId;

    if (isOwner) {
      friendId = data['counterpart_id'] as String? ?? '';
      direction = dbDirection == 'lend'
          ? DebtDirection.owedToMe
          : DebtDirection.iOwe;
    } else {
      friendId = ownerId;
      direction = dbDirection == 'lend'
          ? DebtDirection.iOwe
          : DebtDirection.owedToMe;
    }

    return DebtModel(
      id: id,
      friendId: friendId,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      direction: direction,
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      createdAt: _readDate(data['created_at']),
      deadline: data['deadline'] != null ? _readDate(data['deadline']) : null,
      settledAt: data['settled_at'] != null
          ? _readDate(data['settled_at'])
          : null,
      note: data['description'] as String?,
    );
  }

  final String id;
  final String friendId;
  final double amount;
  final DebtDirection direction;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime? deadline;
  final DateTime? settledAt;
  final String? note;

  bool get isLent => direction == DebtDirection.owedToMe;

  DebtModel copyWith({DebtStatus? status, DateTime? settledAt}) {
    return DebtModel(
      id: id,
      friendId: friendId,
      amount: amount,
      direction: direction,
      status: status ?? this.status,
      createdAt: createdAt,
      deadline: deadline,
      settledAt: settledAt ?? this.settledAt,
      note: note,
    );
  }

  static DebtStatus _statusFromString(String s) {
    switch (s) {
      case 'active':
        return DebtStatus.active;
      case 'settled':
        return DebtStatus.settled;
      default:
        return DebtStatus.pending;
    }
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

@immutable
class DebtRequestModel {
  const DebtRequestModel({
    required this.id,
    required this.type,
    required this.friendId,
    required this.createdAt,
    required this.title,
    required this.description,
    this.debt,
    this.debtIds = const [],
    this.paymentInfo = const SettlementPaymentInfo.cash(),
    this.isOutgoing = false,
  });

  final String id;
  final DebtRequestType type;
  final String friendId;
  final DateTime createdAt;
  final String title;
  final String description;
  final DebtModel? debt;
  final List<String> debtIds;
  final SettlementPaymentInfo paymentInfo;
  final bool isOutgoing;
}
