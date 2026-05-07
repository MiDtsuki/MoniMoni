import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../domain/friend_model.dart';

final friendsControllerProvider =
    StateNotifierProvider<FriendsController, FriendsState>((ref) {
      return FriendsController(ref);
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
  FriendsController(this._ref)
    : super(const FriendsState(friends: [], requests: [])) {
    _load();
  }

  final Ref _ref;
  final Set<String> _sentRequestIds = {};

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String get _userId => _ref.read(currentUserIdProvider);

  Future<void> _load() async {
    try {
      final userId = _userId;

      // Load friendships
      final friendshipRows = await _client
          .from('friendships')
          .select('user_id, friend_id')
          .or('user_id.eq.$userId,friend_id.eq.$userId');

      final friendIds = <String>[];
      for (final row in (friendshipRows as List)) {
        final uid = row['user_id'] as String;
        final fid = row['friend_id'] as String;
        friendIds.add(uid == userId ? fid : uid);
      }

      List<FriendModel> friends = [];
      if (friendIds.isNotEmpty) {
        final profileRows = await _client
            .from('profiles')
            .select('id, display_name, username, credit_score')
            .inFilter('id', friendIds);
        friends = (profileRows as List)
            .map((r) => FriendModel.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      // Load pending incoming friend requests
      final requestRows = await _client
          .from('inbox_items')
          .select('id, sender_id, created_at')
          .eq('recipient_id', userId)
          .eq('type', 'friend_request')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final senderIds = (requestRows as List)
          .map((r) => r['sender_id'] as String)
          .toList();

      final Map<String, FriendModel> senderProfiles = {};
      if (senderIds.isNotEmpty) {
        final profileRows = await _client
            .from('profiles')
            .select('id, display_name, username, credit_score')
            .inFilter('id', senderIds);
        for (final r in (profileRows as List)) {
          final m = r as Map<String, dynamic>;
          senderProfiles[m['id'] as String] = FriendModel.fromJson(m);
        }
      }

      final requests = <FriendRequestModel>[];
      for (final row in requestRows) {
        final senderId = row['sender_id'] as String;
        final sender = senderProfiles[senderId];
        if (sender != null) {
          requests.add(
            FriendRequestModel(
              id: row['id'] as String,
              user: sender,
              createdAt: DateTime.parse(row['created_at'] as String),
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
    final query = username.trim();
    if (query.isEmpty) return [];

    try {
      final userId = _userId;
      final friendIds = state.friends.map((f) => f.id).toSet();
      final requestedIds = state.pendingRequests.map((r) => r.user.id).toSet();

      final rows = await _client
          .from('profiles')
          .select('id, display_name, username, credit_score')
          .ilike('username', '%$query%')
          .neq('id', userId)
          .limit(10);

      return (rows as List)
          .map((r) => FriendModel.fromJson(r as Map<String, dynamic>))
          .where(
            (user) =>
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
      await _client.from('inbox_items').insert({
        'recipient_id': user.id,
        'sender_id': _userId,
        'type': 'friend_request',
        'payload': <String, dynamic>{},
      });
    } catch (_) {
      _sentRequestIds.remove(user.id);
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final request = state.requests.firstWhere((item) => item.id == requestId);
    try {
      await _client
          .from('inbox_items')
          .update({'status': 'accepted'})
          .eq('id', requestId);
      await _client.from('friendships').insert({
        'user_id': _userId,
        'friend_id': request.user.id,
      });
      if (mounted) {
        state = state.copyWith(
          friends: [...state.friends, request.user],
          requests: state.requests
              .where((item) => item.id != requestId)
              .toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _client
          .from('inbox_items')
          .update({'status': 'declined'})
          .eq('id', requestId);
      if (mounted) {
        state = state.copyWith(
          requests: state.requests
              .where((item) => item.id != requestId)
              .toList(),
        );
      }
    } catch (_) {}
  }
}
