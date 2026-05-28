import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';

class AdminScaffold extends ConsumerWidget {
  final Widget child;

  const AdminScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 240,
      color: AppTheme.sidebarColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / title area
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.signal_cellular_alt, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ConsoTélécom',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Back-office v2.0',
                  style: TextStyle(color: AppTheme.sidebarTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2A4A6F), thickness: 1, height: 1),
          const SizedBox(height: 8),

          // Navigation items
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Tableau de bord',
            route: '/dashboard',
            currentLocation: location,
          ),
          _NavItem(
            icon: Icons.flag_outlined,
            label: 'Pays',
            route: '/countries',
            currentLocation: location,
          ),
          _NavItem(
            icon: Icons.cell_tower_outlined,
            label: 'Opérateurs',
            route: '/countries',
            currentLocation: location,
            isSubItem: true,
          ),
          _NavItem(
            icon: Icons.smart_toy_outlined,
            label: 'Fournisseurs IA',
            route: '/ai-providers',
            currentLocation: location,
          ),
          _NavItem(
            icon: Icons.currency_exchange_outlined,
            label: 'Taux de change',
            route: '/exchange-rates',
            currentLocation: location,
          ),

          const Spacer(),
          const Divider(color: Color(0xFF2A4A6F), thickness: 1, height: 1),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.sidebarTextColor, size: 20),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: AppTheme.sidebarTextColor, fontSize: 14),
            ),
            onTap: () async {
              await ref.read(apiClientProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentLocation;
  final bool isSubItem;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentLocation,
    this.isSubItem = false,
  });

  bool get _isActive => currentLocation.startsWith(route);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: _isActive ? AppTheme.accentColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: _isActive ? AppTheme.accentColor : AppTheme.sidebarTextColor,
          size: isSubItem ? 18 : 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: _isActive ? Colors.white : AppTheme.sidebarTextColor,
            fontSize: isSubItem ? 13 : 14,
            fontWeight: _isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSubItem ? 20 : 16,
          vertical: 0,
        ),
        minLeadingWidth: 20,
        visualDensity: const VisualDensity(vertical: -2),
        onTap: () => context.go(route),
      ),
    );
  }
}
