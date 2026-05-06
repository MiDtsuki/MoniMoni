import 'package:flutter/foundation.dart';

enum DebtDirection { owedToMe, iOwe }

enum DebtStatus { pending, active, settled }

enum DebtRequestType { debt, settlement }

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
    this.note,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final ownerId = json['owner_id'] as String;
    final isOwner = ownerId == currentUserId;
    final dbDirection = json['direction'] as String;

    final DebtDirection direction;
    final String friendId;

    if (isOwner) {
      friendId = json['counterpart_id'] as String;
      // owner's 'lend' means owner lent → counterpart owes owner → owedToMe
      direction =
          dbDirection == 'lend' ? DebtDirection.owedToMe : DebtDirection.iOwe;
    } else {
      friendId = ownerId;
      // counterpart perspective: owner's 'lend' means owner lent to me → I owe
      direction =
          dbDirection == 'lend' ? DebtDirection.iOwe : DebtDirection.owedToMe;
    }

    return DebtModel(
      id: json['id'] as String,
      friendId: friendId,
      amount: (json['amount'] as num).toDouble(),
      direction: direction,
      status: _statusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      note: json['description'] as String?,
    );
  }

  final String id;
  final String friendId;
  final double amount;
  final DebtDirection direction;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime? deadline;
  final String? note;

  bool get isLent => direction == DebtDirection.owedToMe;

  DebtModel copyWith({DebtStatus? status}) {
    return DebtModel(
      id: id,
      friendId: friendId,
      amount: amount,
      direction: direction,
      status: status ?? this.status,
      createdAt: createdAt,
      deadline: deadline,
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
  });

  final String id;
  final DebtRequestType type;
  final String friendId;
  final DateTime createdAt;
  final String title;
  final String description;
  final DebtModel? debt;
  final List<String> debtIds;
}
