import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/guest_session_provider.dart';
import '../../debts/application/debt_controller.dart';
import '../../debts/application/friends_controller.dart';

final pendingNotificationCountProvider = Provider<int>((ref) {
  if (ref.watch(isGuestProvider)) return 0;
  final friendRequests = ref.watch(friendsControllerProvider).pendingRequests;
  final debtRequests = ref.watch(debtControllerProvider).pendingRequests;
  return friendRequests.length + debtRequests.length;
});
