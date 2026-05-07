import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/signup_page.dart';
import '../features/debts/presentation/debt_detail_page.dart';
import '../features/debts/presentation/debt_form_page.dart';
import '../features/debts/presentation/debt_page.dart';
import '../features/profile/presentation/inbox_page.dart';
import '../features/profile/application/notification_controller.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/stats/presentation/stats_page.dart';
import '../features/transactions/presentation/transaction_form_page.dart';
import '../features/transactions/presentation/transaction_list_page.dart';
import '../data/local/db_test_page_stub.dart'
    if (dart.library.io) '../data/local/db_test_page.dart';

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

final _authNotifier = _AuthChangeNotifier();

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    if (!loggedIn && !isAuthRoute) return '/login';
    if (loggedIn && isAuthRoute) return '/logs';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/db-test', builder: (context, state) => const DbTestPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MoniShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/logs',
              builder: (context, state) => const TransactionListPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const TransactionFormPage(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => TransactionFormPage(
                    transactionId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/debts',
              builder: (context, state) => const DebtPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const DebtFormPage(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      DebtDetailPage(friendId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'inbox',
                  builder: (context, state) => const InboxPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class MoniShell extends ConsumerWidget {
  const MoniShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationCount = ref.watch(pendingNotificationCountProvider);
    final profileIcon = _BadgeIcon(
      icon: LucideIcons.userRound,
      count: notificationCount,
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14174936),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(LucideIcons.receiptText),
              selectedIcon: Icon(LucideIcons.receiptText),
              label: 'Logs',
            ),
            const NavigationDestination(
              icon: Icon(LucideIcons.handCoins),
              selectedIcon: Icon(LucideIcons.handCoins),
              label: 'Debts',
            ),
            const NavigationDestination(
              icon: Icon(LucideIcons.chartPie),
              selectedIcon: Icon(LucideIcons.chartPie),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: profileIcon,
              selectedIcon: profileIcon,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Icon(icon);
    }
    return Badge.count(count: count, child: Icon(icon));
  }
}
