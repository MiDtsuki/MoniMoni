import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const usersCollection = 'users';
const userProfilesCollection = 'user_profiles';
const usernameClaimsCollection = 'username_claims';
const creditScoreEventsCollection = 'credit_score_events';

final usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

String normalizeUsername(String value) => value.trim().toLowerCase();

String suggestUsername(String value, {String fallback = 'profile'}) {
  final normalized = value.trim().toLowerCase();
  final sanitized = normalized.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  final collapsed = sanitized.replaceAll(RegExp(r'_+'), '_');
  final trimmed = collapsed.replaceAll(RegExp(r'^_+|_+$'), '');
  final candidate = trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed;
  if (isValidUsername(candidate)) {
    return candidate;
  }

  final fallbackSanitized = fallback.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9_]'),
    '_',
  );
  final safeFallback = fallbackSanitized.isEmpty
      ? 'profile'
      : fallbackSanitized;
  final fallbackCandidate = safeFallback.length > 20
      ? safeFallback.substring(0, 20)
      : safeFallback;
  if (isValidUsername(fallbackCandidate)) {
    return fallbackCandidate;
  }
  return 'profile_user';
}

bool isValidUsername(String value) {
  return usernamePattern.hasMatch(normalizeUsername(value));
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();

  @override
  String toString() => 'That username is already taken.';
}

class UsernameFormatException implements Exception {
  const UsernameFormatException();

  @override
  String toString() =>
      'Use 3-20 lowercase letters, numbers, or underscores for your username.';
}

Future<void> createAccountRecords({
  required FirebaseFirestore db,
  required User user,
  required String fullName,
  required String username,
  required String email,
  required String currencyCode,
}) async {
  final normalizedUsername = normalizeUsername(username);
  if (!isValidUsername(normalizedUsername)) {
    throw const UsernameFormatException();
  }

  final userRef = db.collection(usersCollection).doc(user.uid);
  final profileRef = db.collection(userProfilesCollection).doc(user.uid);
  final claimRef = db
      .collection(usernameClaimsCollection)
      .doc(normalizedUsername);

  await db.runTransaction((tx) async {
    final claimSnapshot = await tx.get(claimRef);
    if (claimSnapshot.exists) {
      final ownerUid = claimSnapshot.data()?['owner_uid'] as String?;
      if (ownerUid != user.uid) {
        throw const UsernameTakenException();
      }
    }

    tx.set(userRef, {
      'email': email,
      'full_name': fullName,
      'currency': currencyCode,
      'credit_score': 100,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    tx.set(profileRef, {
      'display_name': normalizedUsername,
      'display_name_lower': normalizedUsername,
      'username': normalizedUsername,
      'username_lower': normalizedUsername,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    tx.set(claimRef, {
      'owner_uid': user.uid,
      'username_lower': normalizedUsername,
      'created_at': FieldValue.serverTimestamp(),
    });
  });
}

Future<void> ensureAccountRecords({
  required FirebaseFirestore db,
  required User user,
  required String fullName,
  required String username,
  required String email,
  required String currencyCode,
}) async {
  final normalizedUsername = normalizeUsername(username);
  if (!isValidUsername(normalizedUsername)) {
    throw const UsernameFormatException();
  }

  final userRef = db.collection(usersCollection).doc(user.uid);
  final profileRef = db.collection(userProfilesCollection).doc(user.uid);
  final claimRef = db
      .collection(usernameClaimsCollection)
      .doc(normalizedUsername);

  await db.runTransaction((tx) async {
    final userSnapshot = await tx.get(userRef);
    final profileSnapshot = await tx.get(profileRef);
    final claimSnapshot = await tx.get(claimRef);

    if (claimSnapshot.exists) {
      final ownerUid = claimSnapshot.data()?['owner_uid'] as String?;
      if (ownerUid != user.uid) {
        throw const UsernameTakenException();
      }
    }

    if (!userSnapshot.exists) {
      tx.set(userRef, {
        'email': email,
        'full_name': fullName,
        'currency': currencyCode,
        'credit_score': 100,
        'created_at': FieldValue.serverTimestamp(),
      });
    } else if ((userSnapshot.data()?['full_name'] as String?)?.trim().isEmpty ??
        true) {
      tx.set(userRef, {'full_name': fullName}, SetOptions(merge: true));
    }

    if (!profileSnapshot.exists) {
      tx.set(profileRef, {
        'display_name': normalizedUsername,
        'display_name_lower': normalizedUsername,
        'username': normalizedUsername,
        'username_lower': normalizedUsername,
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      final profileData = profileSnapshot.data() ?? const <String, dynamic>{};
      final patch = <String, dynamic>{};
      final currentDisplayName = profileData['display_name'] as String?;
      if (currentDisplayName == null ||
          currentDisplayName.trim().isEmpty ||
          currentDisplayName.trim() != normalizedUsername) {
        patch['display_name'] = normalizedUsername;
      }
      final currentDisplayNameLower =
          profileData['display_name_lower'] as String?;
      if (currentDisplayNameLower == null ||
          currentDisplayNameLower.trim().isEmpty ||
          currentDisplayNameLower.trim() != normalizedUsername) {
        patch['display_name_lower'] = normalizedUsername;
      }
      final currentUsername = (profileData['username'] as String?)?.trim();
      if (currentUsername == null ||
          currentUsername.isEmpty ||
          currentUsername != normalizedUsername) {
        patch['username'] = normalizedUsername;
      }
      final currentUsernameLower = (profileData['username_lower'] as String?)
          ?.trim();
      if (currentUsernameLower == null ||
          currentUsernameLower.isEmpty ||
          currentUsernameLower != normalizedUsername) {
        patch['username_lower'] = normalizedUsername;
      }
      if (patch.isNotEmpty) {
        tx.set(profileRef, patch, SetOptions(merge: true));
      }
    }

    if (!claimSnapshot.exists) {
      tx.set(claimRef, {
        'owner_uid': user.uid,
        'username_lower': normalizedUsername,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  });
}
