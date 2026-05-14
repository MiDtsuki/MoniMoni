import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// Subscribes to the Supabase auth stream so auth-derived providers
// automatically rebuild on sign-in, sign-out, and session restore.
final _authStateChangedProvider = StreamProvider<AuthState>(
  (_) => Supabase.instance.client.auth.onAuthStateChange,
);

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(_authStateChangedProvider);
  return Supabase.instance.client.auth.currentUser;
});

final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('Not authenticated');
  return user.id;
});
