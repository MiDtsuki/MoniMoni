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
  });

  final CurrencyOption currency;
  final String displayName;
  final String username;

  ProfileSettings copyWith({
    CurrencyOption? currency,
    String? displayName,
    String? username,
  }) {
    return ProfileSettings(
      currency: currency ?? this.currency,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
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
    try {
      final row = await _client
          .from('profiles')
          .select('display_name, username, currency')
          .eq('id', _userId)
          .single();

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
        );
      }
    } catch (_) {}
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
