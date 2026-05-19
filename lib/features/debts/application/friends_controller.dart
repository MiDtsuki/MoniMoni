import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/session_providers.dart';
import '../domain/friend_model.dart';

final friendsControllerProvider =
    StateNotifierProvider<FriendsController, FriendsState>((ref) {
      final isGuest = ref.watch(isGuestModeProvider);
      if (isGuest) {
        return FriendsController.guest(ref);
      }
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return FriendsController.guest(ref);
      }
      return FriendsController.remote(ref, user.uid);
    });

class FriendsState {
  const FriendsState({required this.friends, required this.requests});

  final List<FriendModel> friends;
  final List<FriendRequestModel> requests;

  List<FriendRequestModel> get pendingRequests =>
      requests.where((r) => r.status == FriendRequestStatus.pending).toList();

  FriendsState copyWith({
    List<FriendModel>? friends,
    List<FriendRequestModel>? requests,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
    );
  }
}

class FriendsController extends StateNotifier<FriendsState> {
  FriendsController.remote(this._ref, this._userId)
    : super(const FriendsState(friends: [], requests: [])) {
    _load();
  }

  FriendsController.guest(this._ref)
    : _userId = null,
      super(const FriendsState(friends: [], requests: []));

  final Ref _ref;
  final String? _userId;
  final Set<String> _sentRequestIds = {};

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final userId = _userId;
      if (userId == null) return;

      final friendshipRows = await _db
          .collection('friendships')
          .where('participants', arrayContains: userId)
          .get();

      final friendIds = <String>[];
      for (final doc in friendshipRows.docs) {
        final participants =
            (doc.data()['participants'] as List<dynamic>? ?? const [])
                .cast<String>();
        for (final participant in participants) {
          if (participant != userId) {
            friendIds.add(participant);
          }
        }
      }

      final friends = await _loadUsersByIds(friendIds);

      final requestRows = await _db
          .collection('inbox_items')
          .where('recipient_id', isEqualTo: userId)
          .where('type', isEqualTo: 'friend_request')
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .get();

      final senderIds = requestRows.docs
          .map((doc) => doc.data()['sender_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final senderProfiles = {
        for (final user in await _loadUsersByIds(senderIds)) user.id: user,
      };

      final requests = <FriendRequestModel>[];
      for (final doc in requestRows.docs) {
        final data = doc.data();
        final senderId = data['sender_id'] as String? ?? '';
        final sender = senderProfiles[senderId];
        if (sender != null) {
          requests.add(
            FriendRequestModel(
              id: doc.id,
              user: sender,
              createdAt: _readDate(data['created_at']),
            ),
          );
        }
      }

      if (mounted) {
        state = FriendsState(friends: friends, requests: requests);
      }
    } catch (_) {}
  }

  Future<List<FriendModel>> searchUsers(String username) async {
    final query = username.trim().toLowerCase();
    if (query.isEmpty) return [];

    try {
      final userId = _userId;
      if (userId == null) return [];
      final friendIds = state.friends.map((f) => f.id).toSet();
      final requestedIds = state.pendingRequests.map((r) => r.user.id).toSet();

      final rows = await _db
          .collection('users')
          .orderBy('username_lower')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(10)
          .get();

      return rows.docs
          .map((doc) => FriendModel.fromMap(doc.id, doc.data()))
          .where(
            (user) =>
                user.id != userId &&
                !friendIds.contains(user.id) &&
                !requestedIds.contains(user.id) &&
                !_sentRequestIds.contains(user.id),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> sendFriendRequest(FriendModel user) async {
    if (_sentRequestIds.contains(user.id)) return;
    _sentRequestIds.add(user.id);
    try {
      await _db.collection('inbox_items').add({
        'recipient_id': user.id,
        'sender_id': _userId!,
        'type': 'friend_request',
        'payload': <String, dynamic>{},
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      _sentRequestIds.remove(user.id);
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final userId = _userId;
    if (userId == null) return;
    final request = state.requests.firstWhere((item) => item.id == requestId);
    await _db.collection('inbox_items').doc(requestId).set({
      'status': 'accepted',
    }, SetOptions(merge: true));
    await _db
        .collection('friendships')
        .doc(_friendshipId(userId, request.user.id))
        .set({
          'participants': [userId, request.user.id]..sort(),
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    if (mounted) {
      state = state.copyWith(
        friends: [...state.friends, request.user],
        requests: state.requests.where((item) => item.id != requestId).toList(),
      );
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _db.collection('inbox_items').doc(requestId).set({
      'status': 'declined',
    }, SetOptions(merge: true));
    if (mounted) {
      state = state.copyWith(
        requests: state.requests.where((item) => item.id != requestId).toList(),
      );
    }
  }

  Future<List<FriendModel>> _loadUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final uniqueIds = ids.toSet().toList();
    final users = <FriendModel>[];

    for (var i = 0; i < uniqueIds.length; i += 10) {
      final chunk = uniqueIds.skip(i).take(10).toList();
      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(
        snapshot.docs.map((doc) => FriendModel.fromMap(doc.id, doc.data())),
      );
    }

    return users;
  }

  String _friendshipId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids.first}_${ids.last}';
  }

  DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
