import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/friend_model.dart';

final friendsControllerProvider =
    StateNotifierProvider<FriendsController, FriendsState>((ref) {
      return FriendsController();
    });

class FriendsState {
  const FriendsState({
    required this.friends,
    required this.users,
    required this.requests,
  });

  final List<FriendModel> friends;
  final List<FriendModel> users;
  final List<FriendRequestModel> requests;

  List<FriendRequestModel> get pendingRequests {
    return requests
        .where((request) => request.status == FriendRequestStatus.pending)
        .toList();
  }

  FriendsState copyWith({
    List<FriendModel>? friends,
    List<FriendModel>? users,
    List<FriendRequestModel>? requests,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      users: users ?? this.users,
      requests: requests ?? this.requests,
    );
  }
}

class FriendsController extends StateNotifier<FriendsState> {
  FriendsController()
    : super(
        FriendsState(
          friends: _mockFriends,
          users: _mockUsers,
          requests: [
            FriendRequestModel(
              id: 'friend-request-1',
              user: _mockUsers[3],
              createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            ),
          ],
        ),
      );

  static const _uuid = Uuid();

  List<FriendModel> searchUsers(String username) {
    final query = username.trim().toLowerCase();
    if (query.isEmpty) {
      return const [];
    }
    final friendIds = state.friends.map((friend) => friend.id).toSet();
    final requestedIds = state.pendingRequests
        .map((request) => request.user.id)
        .toSet();
    return state.users.where((user) {
      return !friendIds.contains(user.id) &&
          !requestedIds.contains(user.id) &&
          user.username.toLowerCase().contains(query);
    }).toList();
  }

  void sendFriendRequest(FriendModel user) {
    state = state.copyWith(
      requests: [
        FriendRequestModel(
          id: _uuid.v4(),
          user: user,
          createdAt: DateTime.now(),
        ),
        ...state.requests,
      ],
    );
  }

  void acceptFriendRequest(String requestId) {
    final request = state.requests.firstWhere((item) => item.id == requestId);
    state = state.copyWith(
      friends: [...state.friends, request.user],
      requests: state.requests.where((item) => item.id != requestId).toList(),
    );
  }

  void declineFriendRequest(String requestId) {
    state = state.copyWith(
      requests: state.requests.where((item) => item.id != requestId).toList(),
    );
  }
}

const _mockFriends = [
  FriendModel(id: 'friend-1', name: 'Maya Chen', username: '@maya'),
  FriendModel(id: 'friend-2', name: 'Noah Park', username: '@noah'),
  FriendModel(id: 'friend-3', name: 'Ari Lee', username: '@ari'),
];

const _mockUsers = [
  ..._mockFriends,
  FriendModel(id: 'friend-4', name: 'Sofia Kim', username: '@sofia'),
  FriendModel(id: 'friend-5', name: 'Ethan Wells', username: '@ethan'),
  FriendModel(id: 'friend-6', name: 'Lina Stone', username: '@lina'),
];
