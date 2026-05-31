import 'package:flutter/foundation.dart';

enum FriendRequestStatus { pending, accepted }

@immutable
class FriendModel {
  const FriendModel({
    required this.id,
    required this.name,
    required this.username,
  });

  factory FriendModel.fromMap(String id, Map<String, dynamic> data) {
    final username = data['username'] as String? ?? '';
    return FriendModel(
      id: id,
      name: username,
      username: username,
    );
  }

  final String id;
  final String name;
  final String username;
}

@immutable
class FriendRequestModel {
  const FriendRequestModel({
    required this.id,
    required this.user,
    required this.createdAt,
    this.status = FriendRequestStatus.pending,
    this.isOutgoing = false,
  });

  final String id;
  final FriendModel user;
  final DateTime createdAt;
  final FriendRequestStatus status;
  final bool isOutgoing;

  FriendRequestModel copyWith({FriendRequestStatus? status, bool? isOutgoing}) {
    return FriendRequestModel(
      id: id,
      user: user,
      createdAt: createdAt,
      status: status ?? this.status,
      isOutgoing: isOutgoing ?? this.isOutgoing,
    );
  }
}
