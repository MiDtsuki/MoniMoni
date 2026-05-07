import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';

final profileSettingsProvider =
    StateNotifierProvider<ProfileSettingsController, ProfileSettings>((ref) {
      return ProfileSettingsController(ref);
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
  ProfileSettingsController(this._ref)
    : super(const ProfileSettings(currency: defaultCurrency)) {
    _load();
  }

  final Ref _ref;

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String get _userId => _ref.read(currentUserIdProvider);

  Future<void> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final fallback = _settingsFromUser(user, state.currency);
    if (mounted) {
      state = fallback;
    }

    try {
      var row = await _fetchProfileRow();
      if (row == null) {
        await _insertProfileRow(user, fallback);
        row = await _fetchProfileRow();
      }
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

  Future<Map<String, dynamic>?> _fetchProfileRow() async {
    try {
      return await _client
          .from('profiles')
          .select('display_name, username, currency, credit_score')
          .eq('id', _userId)
          .maybeSingle();
    } on PostgrestException catch (error) {
      // Older remote databases may not have credit_score until migrations run.
      if (error.code != '42703') rethrow;
      return await _client
          .from('profiles')
          .select('display_name, username, currency')
          .eq('id', _userId)
          .maybeSingle();
    }
  }

  Future<void> _insertProfileRow(User user, ProfileSettings fallback) async {
    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'display_name': fallback.displayName,
        'username': fallback.username.isEmpty ? null : fallback.username,
        'currency': fallback.currency.code,
      });
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
    }
  }

  ProfileSettings _settingsFromUser(User user, CurrencyOption currency) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final displayName = metadata['display_name'] as String?;
    final username = metadata['username'] as String?;
    final emailName = user.email?.split('@').first.trim();

    return ProfileSettings(
      currency: currency,
      displayName: _firstNonEmpty([displayName, emailName, 'Profile']),
      username: _firstNonEmpty([username, emailName]),
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
    try {
      await _client
          .from('profiles')
          .update({'currency': currency.code})
          .eq('id', _userId);
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
  CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro'),
  CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound'),
  CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  CurrencyOption(code: 'THB', symbol: '฿', name: 'Thai Baht'),
  CurrencyOption(code: 'MMK', symbol: 'K', name: 'Myanmar Kyat'),
  CurrencyOption(code: 'SGD', symbol: r'S$', name: 'Singapore Dollar'),
];
