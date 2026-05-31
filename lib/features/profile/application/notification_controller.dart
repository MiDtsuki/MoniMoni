import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../debts/application/debt_controller.dart';
import '../../debts/application/friends_controller.dart';

final pendingNotificationCountProvider = Provider<int>((ref) {
  final friendsState = ref.watch(friendsControllerProvider);
  final debtRequests = ref.watch(debtControllerProvider).pendingRequests;
  return friendsState.pendingRequests.length +
      friendsState.acceptedNotifications.length +
      debtRequests.length;
});
