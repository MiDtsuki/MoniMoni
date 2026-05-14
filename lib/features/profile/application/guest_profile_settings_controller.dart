import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../data/local/drift_db.dart';
import 'profile_settings_controller.dart';

class GuestProfileSettingsController extends BaseProfileSettingsController {
  GuestProfileSettingsController(this._ref)
      : super(const ProfileSettings(
          currency: defaultCurrency,
          displayName: 'Guest',
          username: '',
        )) {
    _load();
  }

  final Ref _ref;
  LocalSettingsDao get _dao => _ref.read(localSettingsDaoProvider);

  Future<void> _load() async {
    try {
      final displayName = await _dao.getValue('display_name');
      final currencyCode = await _dao.getValue('currency');
      final currency = currencyCode != null
          ? supportedCurrencies.firstWhere(
              (c) => c.code == currencyCode,
              orElse: () => defaultCurrency,
            )
          : defaultCurrency;
      if (mounted) {
        state = state.copyWith(
          displayName: displayName ?? 'Guest',
          currency: currency,
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> setCurrency(CurrencyOption currency) async {
    state = state.copyWith(currency: currency);
    try {
      await _dao.setValue('currency', currency.code);
    } catch (_) {}
  }

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(displayName: trimmed);
    try {
      await _dao.setValue('display_name', trimmed);
    } catch (_) {}
  }
}
