import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../debts/application/debt_controller.dart';
import '../../debts/application/friends_controller.dart';

final pendingNotificationCountProvider = Provider<int>((ref) {
  final friendRequests = ref.watch(friendsControllerProvider).pendingRequests;
  final debtRequests = ref.watch(debtControllerProvider).pendingRequests;
  return friendRequests.length + debtRequests.length;
});
