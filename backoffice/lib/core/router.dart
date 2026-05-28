import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/countries/countries_page.dart';
import '../features/operators/operators_page.dart';
import '../features/operators/tariffs_page.dart';
import '../features/ai_providers/ai_providers_page.dart';
import '../features/ai_providers/ai_models_page.dart';
import '../features/exchange_rates/exchange_rates_page.dart';
import '../shared/widgets/admin_scaffold.dart';

const _storage = FlutterSecureStorage();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) async {
      final token = await _storage.read(key: 'admin_jwt_token');
      final isLoggedIn = token != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/countries',
            builder: (context, state) => const CountriesPage(),
          ),
          GoRoute(
            path: '/countries/:code/operators',
            builder: (context, state) =>
                OperatorsPage(countryCode: state.pathParameters['code']!),
          ),
          GoRoute(
            path: '/operators/:id/tariffs',
            builder: (context, state) =>
                TariffsPage(operatorId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/ai-providers',
            builder: (context, state) => const AiProvidersPage(),
          ),
          GoRoute(
            path: '/ai-providers/:id/models',
            builder: (context, state) =>
                AiModelsPage(providerId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/exchange-rates',
            builder: (context, state) => const ExchangeRatesPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page introuvable: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Retour au tableau de bord'),
            ),
          ],
        ),
      ),
    ),
  );
});
