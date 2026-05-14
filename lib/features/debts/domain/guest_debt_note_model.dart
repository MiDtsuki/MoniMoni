import 'package:flutter/foundation.dart';

@immutable
class GuestDebtNoteModel {
  const GuestDebtNoteModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.deadline,
    this.note,
  });

  factory GuestDebtNoteModel.fromJson(Map<String, dynamic> json) {
    return GuestDebtNoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: GuestDebtNoteType.values.byName(json['type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      note: json['note'] as String?,
    );
  }

  final String id;
  final String title;
  final double amount;
  final GuestDebtNoteType type;
  final DateTime createdAt;
  final DateTime? deadline;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'note': note,
    };
  }
}

enum GuestDebtNoteType { lent, borrowed }
