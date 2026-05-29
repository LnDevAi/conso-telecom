import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../l10n/language_provider.dart';

import '../../features/dashboard/dashboard_page.dart';
import '../../features/data_usage/data_usage_page.dart';
import '../../features/ai_tokens/ai_tokens_page.dart';
import '../../features/costs/costs_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/plans/plans_page.dart';
import '../../features/calls/calls_sms_page.dart';
import '../../features/comparator/comparator_page.dart';
import '../../features/history/history_page.dart';
import '../../features/settings/ai_keys_page.dart';
import '../../features/alerts/alerts_page.dart';
import '../../features/settings/operator_setup_page.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/data',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DataUsagePage(),
            ),
          ),
          GoRoute(
            path: '/ai',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AiTokensPage(),
            ),
          ),
          GoRoute(
            path: '/costs',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CostsPage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),

      // Routes sans barre de navigation
      GoRoute(
        path: '/plans',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PlansPage(),
      ),
      GoRoute(
        path: '/calls',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CallsSmsPage(),
      ),
      GoRoute(
        path: '/comparator',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ComparatorPage(),
      ),
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/settings/ai-keys',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiKeysPage(),
      ),
      GoRoute(
        path: '/settings/alerts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AlertsPage(),
      ),
      GoRoute(
        path: '/settings/operators',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OperatorSetupPage(),
      ),
    ],
  );
}

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({super.key, required this.child});

  final Widget child;

  static const _paths = ['/', '/data', '/ai', '/costs', '/settings'];

  int _locationToIndex(String location) {
    for (int i = _paths.length - 1; i >= 0; i--) {
      if (location.startsWith(_paths[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);
    final s = ref.watch(translationsProvider);

    final tabs = [
      _NavTab(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: s.navDashboard),
      _NavTab(icon: Icons.wifi_outlined, activeIcon: Icons.wifi, label: s.navData),
      _NavTab(icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: s.navAi),
      _NavTab(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: s.navCosts),
      _NavTab(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: s.navSettings),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index != currentIndex) {
            context.go(_paths[index]);
          }
        },
        destinations: tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
