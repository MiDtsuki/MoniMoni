import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/session_providers.dart';

final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(profileSettingsProvider).currency.symbol;
});

final profileSettingsProvider =
    StateNotifierProvider<ProfileSettingsController, ProfileSettings>((ref) {
      final isGuest = ref.watch(isGuestModeProvider);
      if (isGuest) {
        return ProfileSettingsController.guest(ref);
      }
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return ProfileSettingsController.signedOut(ref);
      }
      return ProfileSettingsController.remote(ref, user.uid);
    });

class ProfileSettings {
  const ProfileSettings({
    required this.currency,
    this.displayName = '',
    this.username = '',
    this.creditScore = 100,
  });

  final CurrencyOption currency;
  final String displayName;
  final String username;
  final int creditScore;

  ProfileSettings copyWith({
    CurrencyOption? currency,
    String? displayName,
    String? username,
    int? creditScore,
  }) {
    return ProfileSettings(
      currency: currency ?? this.currency,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      creditScore: creditScore ?? this.creditScore,
    );
  }
}

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;
}

class ProfileSettingsController extends StateNotifier<ProfileSettings> {
  ProfileSettingsController.remote(this._ref, this._userId)
    : super(const ProfileSettings(currency: defaultCurrency)) {
    _load();
  }

  ProfileSettingsController.guest(this._ref)
    : _userId = null,
      super(
        const ProfileSettings(
          currency: defaultCurrency,
          displayName: 'Guest',
          username: 'offline',
        ),
      );

  ProfileSettingsController.signedOut(this._ref)
    : _userId = null,
      super(const ProfileSettings(currency: defaultCurrency));

  final Ref _ref;
  final String? _userId;

  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final fallback = _settingsFromUser(user, state.currency);
    if (mounted) {
      state = fallback;
    }

    try {
      var snapshot = await _fetchProfileDoc();
      if (!snapshot.exists) {
        await _insertProfileDoc(user, fallback);
        snapshot = await _fetchProfileDoc();
      }

      final row = snapshot.data();
      if (row == null) return;

      final currencyCode = row['currency'] as String? ?? 'USD';
      final currency = supportedCurrencies.firstWhere(
        (c) => c.code == currencyCode,
        orElse: () => defaultCurrency,
      );

      if (mounted) {
        state = ProfileSettings(
          currency: currency,
          displayName: row['display_name'] as String? ?? '',
          username: row['username'] as String? ?? '',
          creditScore: (row['credit_score'] as num?)?.toInt() ?? 100,
        );
      }
    } catch (_) {}
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchProfileDoc() {
    return _db.collection('users').doc(_userId!).get();
  }

  Future<void> _insertProfileDoc(User user, ProfileSettings fallback) async {
    await _db.collection('users').doc(user.uid).set({
      'display_name': fallback.displayName,
      'username': fallback.username,
      'username_lower': fallback.username.toLowerCase(),
      'currency': fallback.currency.code,
      'credit_score': 100,
      'email': user.email,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  ProfileSettings _settingsFromUser(User user, CurrencyOption currency) {
    final displayName = user.displayName;
    final emailName = user.email?.split('@').first.trim();

    return ProfileSettings(
      currency: currency,
      displayName: _firstNonEmpty([displayName, emailName, 'Profile']),
      username: _firstNonEmpty([emailName]),
    );
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  Future<void> setCurrency(CurrencyOption currency) async {
    state = state.copyWith(currency: currency);
    if (_userId == null) return;
    try {
      await _db.collection('users').doc(_userId).set({
        'currency': currency.code,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}

const defaultCurrency = CurrencyOption(
  code: 'USD',
  symbol: r'$',
  name: 'US Dollar',
);

const supportedCurrencies = [
  defaultCurrency,
  CurrencyOption(code: 'EUR', symbol: 'EUR', name: 'Euro'),
  CurrencyOption(code: 'GBP', symbol: 'GBP', name: 'British Pound'),
  CurrencyOption(code: 'JPY', symbol: 'JPY', name: 'Japanese Yen'),
  CurrencyOption(code: 'THB', symbol: 'THB', name: 'Thai Baht'),
  CurrencyOption(code: 'MMK', symbol: 'K', name: 'Myanmar Kyat'),
  CurrencyOption(code: 'SGD', symbol: 'SGD', name: 'Singapore Dollar'),
];
