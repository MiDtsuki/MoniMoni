import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _guestModeKey = 'moni_guest_mode';

final guestSession = GuestSession();

final guestSessionProvider = ChangeNotifierProvider<GuestSession>(
  (_) => guestSession,
);

final isGuestModeProvider = Provider<bool>(
  (ref) => ref.watch(guestSessionProvider).isGuest,
);

class GuestSession extends ChangeNotifier {
  bool _isGuest = false;

  bool get isGuest => _isGuest;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool(_guestModeKey) ?? false;
  }

  Future<void> enter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, true);
    _isGuest = true;
    notifyListeners();
  }

  Future<void> exit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, false);
    _isGuest = false;
    notifyListeners();
  }
}
