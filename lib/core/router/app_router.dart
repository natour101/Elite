import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../screens/admin/admin_screens.dart';
import '../../screens/store/store_screens.dart';

enum AppEntry { storefront, admin }

final appRouterProvider = Provider.family<GoRouter, AppEntry>((ref, entry) {
  if (entry == AppEntry.admin) {
    final session = ref.watch(authSessionProvider);

    return GoRouter(
      initialLocation: '/admin/dashboard',
      refreshListenable: _RouterRefreshStream(
        ref.watch(authServiceProvider).authStateChanges(),
      ),
      redirect: (context, state) {
        final currentSession = session.valueOrNull;
        final loggedIn = currentSession?.isAuthenticated ?? false;
        final isAdmin = currentSession?.isAdmin ?? false;
        final loggingIn = state.matchedLocation == '/admin/login';

        if (!loggedIn) {
          return loggingIn ? null : '/admin/login';
        }
        if (!isAdmin) {
          return '/admin/login';
        }
        if (loggingIn) {
          return '/admin/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => AdminShell(child: child),
          routes: [
            GoRoute(
              path: '/admin/dashboard',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            GoRoute(
              path: '/admin/products',
              builder: (context, state) => const AdminProductsScreen(),
            ),
            GoRoute(
              path: '/admin/mediators',
              builder: (context, state) => const AdminMediatorsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => AdminMediatorDetailsScreen(
                    mediatorId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/admin/orders',
              builder: (context, state) => const AdminOrdersScreen(),
            ),
          ],
        ),
      ],
    );
  }

  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => StoreShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const StoreHomeScreen()),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) => ProductDetailsScreen(
              productId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),
        ],
      ),
    ],
  );
});

class _RouterRefreshStream extends ChangeNotifier {
  _RouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
