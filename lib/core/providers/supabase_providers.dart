import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final currentUserProvider = Provider<User?>(
  (_) => Supabase.instance.client.auth.currentUser,
);

final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('Not authenticated');
  return user.id;
});
