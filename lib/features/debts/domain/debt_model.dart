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
