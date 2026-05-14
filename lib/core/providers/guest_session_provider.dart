import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A ValueNotifier the router can observe (it lives outside Riverpod scope).
final guestModeNotifier = ValueNotifier<bool>(false);

/// Riverpod mirror for widgets and providers to reactively watch.
final isGuestProvider = StateProvider<bool>((ref) => false);

void enterGuestMode(WidgetRef ref) {
  guestModeNotifier.value = true;
  ref.read(isGuestProvider.notifier).state = true;
}

void exitGuestMode(WidgetRef ref) {
  guestModeNotifier.value = false;
  ref.read(isGuestProvider.notifier).state = false;
}
