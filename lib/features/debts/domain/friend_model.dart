import 'package:flutter/foundation.dart';

enum FriendRequestStatus { pending, accepted }

@immutable
class FriendModel {
  const FriendModel({
    required this.id,
    required this.name,
    required this.username,
  });

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
  });

  final String id;
  final FriendModel user;
  final DateTime createdAt;
  final FriendRequestStatus status;

  FriendRequestModel copyWith({FriendRequestStatus? status}) {
    return FriendRequestModel(
      id: id,
      user: user,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
