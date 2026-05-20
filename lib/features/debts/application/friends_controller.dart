import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/session_providers.dart';
import '../domain/friend_model.dart';

// Watch user?.uid (a String) instead of the full User object so the controller
// only rebuilds when the logged-in account actually changes — not every time
// Firebase Auth re-emits the same user with a new object reference on startup.
final friendsControllerProvider =
    StateNotifierProvider<FriendsController, FriendsState>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (isGuest) {
    return FriendsController.guest(ref);
  }
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) {
    return FriendsController.guest(ref);
  }
  return FriendsController.remote(ref, uid);
});

class FriendsState {
  const FriendsState({
    required this.friends,
    required this.requests,
    this.acceptedNotifications = const [],
  });

  final List<FriendModel> friends;
  final List<FriendRequestModel> requests;
  final List<FriendRequestModel> acceptedNotifications;

  List<FriendRequestModel> get pendingRequests =>
      requests.where((r) => r.status == FriendRequestStatus.pending).toList();

  FriendsState copyWith({
    List<FriendModel>? friends,
    List<FriendRequestModel>? requests,
    List<FriendRequestModel>? acceptedNotifications,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
      acceptedNotifications:
          acceptedNotifications ?? this.acceptedNotifications,
    );
  }
}

class FriendsController extends StateNotifier<FriendsState> {
  FriendsController.remote(this._ref, this._userId)
      : super(const FriendsState(friends: [], requests: [])) {
    _load();
    _subscribeToRemoteChanges();
  }

  FriendsController.guest(this._ref)
      : _userId = null,
        super(const FriendsState(friends: [], requests: []));

  final Ref _ref;
  final String? _userId;
  final Set<String> _sentRequestIds = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  // Generation counters prevent stale concurrent async fetches from overwriting
  // newer results when multiple snapshot events fire in quick succession.
  int _requestsGeneration = 0;
  int _friendsGeneration = 0;

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> refresh() => _load();

  // Single source of truth for state.friends — always reads from the
  // `friendships` collection so the list survives hot restarts and sign-out/in.
  Future<void> _loadFriends() async {
    final userId = _userId;
    if (userId == null) return;
    final gen = ++_friendsGeneration;
    try {
      final snapshot = await _db
          .collection('friendships')
          .where('participants', arrayContains: userId)
          .get();
      final friends = await _buildFriends(snapshot.docs);
      if (mounted && gen == _friendsGeneration) {
        state = state.copyWith(friends: friends);
      }
    } catch (e, st) {
      debugPrint('FriendsController friends load failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _subscribeToRemoteChanges() {
    final userId = _userId;
    if (userId == null) return;

    // Single-filter query (no composite index needed). Friend-request/pending
    // filtering is applied in Dart so this subscription also wakes up when a
    // debt request arrives, but that's harmless — _buildRequests is cheap.
    _subscriptions.add(
      _db
          .collection('inbox_items')
          .where('recipient_id', isEqualTo: userId)
          .snapshots()
          .listen(
        (snapshot) {
          final requestDocs = snapshot.docs.where((doc) {
            final data = doc.data();
            return data['type'] == 'friend_request' &&
                data['status'] == 'pending';
          }).toList();

          final acceptedDocs = snapshot.docs.where((doc) {
            final data = doc.data();
            return data['type'] == 'friend_request_accepted' &&
                data['status'] == 'pending';
          }).toList();

          final gen = ++_requestsGeneration;
          Future.wait([
            _buildRequests(requestDocs),
            _buildRequests(acceptedDocs),
          ]).then((results) {
            if (mounted && gen == _requestsGeneration) {
              state = state.copyWith(
                requests: results[0],
                acceptedNotifications: results[1],
              );
              // Reload friends from Firestore whenever we receive new accepted
              // notifications so the sender sees the friend immediately without
              // relying on notification data being in state.
              if (results[1].isNotEmpty) _loadFriends();
            }
          }).catchError((Object e) {
            debugPrint('FriendsController requests update failed: $e');
          });
        },
        onError: (Object e) =>
            debugPrint('FriendsController inbox stream error: $e'),
      ),
    );

    // Friendships stream — fires for both sides whenever a friendship document
    // is created or updated, keeping state.friends in sync in real-time.
    _subscriptions.add(
      _db
          .collection('friendships')
          .where('participants', arrayContains: userId)
          .snapshots()
          .listen(
        (snapshot) {
          final gen = ++_friendsGeneration;
          _buildFriends(snapshot.docs).then((friends) {
            if (mounted && gen == _friendsGeneration) {
              state = state.copyWith(friends: friends);
            }
          }).catchError((Object e) {
            debugPrint('FriendsController friends update failed: $e');
          });
        },
        onError: (Object e) =>
            debugPrint('FriendsController friendships stream error: $e'),
      ),
    );
  }

  // Initial load and pull-to-refresh.  Each section is an independent
  // try-catch so a missing Firestore index on one query doesn't wipe out
  // the results of another.
  Future<void> _load() async {
    final userId = _userId;
    if (userId == null) return;

    // Friends are loaded WITHOUT a generation guard so the result is always
    // applied — the subscription's initial snapshot (which increments
    // _friendsGeneration immediately) must not be able to discard this query.
    try {
      final snapshot = await _db
          .collection('friendships')
          .where('participants', arrayContains: userId)
          .get();
      final friends = await _buildFriends(snapshot.docs);
      if (mounted) state = state.copyWith(friends: friends);
    } catch (e, st) {
      debugPrint('FriendsController friends load failed: $e');
      debugPrintStack(stackTrace: st);
    }

    try {
      final snapshot = await _db
          .collection('inbox_items')
          .where('recipient_id', isEqualTo: userId)
          .where('type', isEqualTo: 'friend_request')
          .where('status', isEqualTo: 'pending')
          .get();
      final requests = await _buildRequests(snapshot.docs);
      if (mounted) state = state.copyWith(requests: requests);
    } catch (e, st) {
      debugPrint('FriendsController requests load failed: $e');
      debugPrintStack(stackTrace: st);
    }

    try {
      final snapshot = await _db
          .collection('inbox_items')
          .where('recipient_id', isEqualTo: userId)
          .where('type', isEqualTo: 'friend_request_accepted')
          .where('status', isEqualTo: 'pending')
          .get();
      final notifications = await _buildRequests(snapshot.docs);
      if (mounted) state = state.copyWith(acceptedNotifications: notifications);
    } catch (e, st) {
      debugPrint('FriendsController accepted notifications load failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<List<FriendModel>> _buildFriends(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final friendIds = <String>[];
    for (final doc in docs) {
      final participants =
          (doc.data()['participants'] as List<dynamic>? ?? const [])
              .cast<String>();
      for (final participant in participants) {
        if (participant != _userId) {
          friendIds.add(participant);
        }
      }
    }
    return _loadUsersByIds(friendIds);
  }

  Future<List<FriendRequestModel>> _buildRequests(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return [];

    final senderIds = docs
        .map((doc) => doc.data()['sender_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final senderProfiles = {
      for (final user in await _loadUsersByIds(senderIds)) user.id: user,
    };

    final requests = <FriendRequestModel>[];
    for (final doc in docs) {
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
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
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
          .endAt(['$query'])
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

  // Atomically marks the request accepted, creates the friendship document,
  // and notifies the original sender — all in a single Firestore batch so no
  // partial state is left if any step fails.
  Future<void> acceptFriendRequest(String requestId) async {
    final userId = _userId;
    if (userId == null) return;
    final request =
        state.requests.where((item) => item.id == requestId).firstOrNull;
    if (request == null) return;

    final notificationRef = _db.collection('inbox_items').doc();
    final batch = _db.batch();

    batch.set(
      _db.collection('inbox_items').doc(requestId),
      {'status': 'accepted'},
      SetOptions(merge: true),
    );
    batch.set(
      _db
          .collection('friendships')
          .doc(_friendshipId(userId, request.user.id)),
      {
        'participants': [userId, request.user.id]..sort(),
        'created_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(notificationRef, {
      'recipient_id': request.user.id,
      'sender_id': userId,
      'type': 'friend_request_accepted',
      'status': 'pending',
      'payload': <String, dynamic>{},
      'created_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Immediately update the acceptor's local state so the friend appears
    // without waiting for the friendships stream.
    if (mounted) {
      state = state.copyWith(
        friends: [...state.friends, request.user],
        requests: state.requests.where((r) => r.id != requestId).toList(),
      );
    }
  }

  Future<void> dismissAcceptedNotification(String notificationId) async {
    await _db.collection('inbox_items').doc(notificationId).set(
      {'status': 'dismissed'},
      SetOptions(merge: true),
    );
    // inbox_items stream removes the dismissed notification from `acceptedNotifications`
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _db.collection('inbox_items').doc(requestId).set(
      {'status': 'declined'},
      SetOptions(merge: true),
    );
    // inbox_items stream removes the declined request from `requests`
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

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
