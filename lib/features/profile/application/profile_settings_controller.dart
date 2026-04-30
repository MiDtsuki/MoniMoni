import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileSettingsProvider =
    StateNotifierProvider<ProfileSettingsController, ProfileSettings>((ref) {
      return ProfileSettingsController();
    });

class ProfileSettings {
  const ProfileSettings({required this.currency});

  final CurrencyOption currency;

  ProfileSettings copyWith({CurrencyOption? currency}) {
    return ProfileSettings(currency: currency ?? this.currency);
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
  ProfileSettingsController()
    : super(const ProfileSettings(currency: defaultCurrency));

  void setCurrency(CurrencyOption currency) {
    state = state.copyWith(currency: currency);
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
