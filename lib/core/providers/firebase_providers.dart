import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.read(firebaseAuthProvider).authStateChanges(),
);

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  final auth = ref.read(firebaseAuthProvider);
  return authState.when(
    data: (user) => user,
    loading: () => auth.currentUser,
    error: (_, _) => auth.currentUser,
  );
});

final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('Not authenticated');
  return user.uid;
});
