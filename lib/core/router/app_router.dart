import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/mediator_portal_controller.dart';
import '../../screens/admin/admin_screens.dart';
import '../../screens/desktop/desktop_login_screen.dart';
import '../../screens/mediator/mediator_screens.dart';
import '../../screens/store/store_screens.dart';

enum AppEntry { storefront, admin }

final appRouterProvider = Provider.family<GoRouter, AppEntry>((ref, entry) {
  if (entry == AppEntry.admin) {
    final session = ref.watch(authSessionProvider);
    final mediator = ref.watch(mediatorSessionProvider);

    return GoRouter(
      initialLocation: '/desktop/login',
      refreshListenable: _RouterRefreshStream(
        StreamGroup.merge([
          ref.watch(authServiceProvider).authStateChanges(),
          ref.watch(mediatorSessionProvider.notifier).stream,
        ]),
      ),
      redirect: (context, state) {
        final currentSession = session.valueOrNull;
        final isAdmin = currentSession?.isAdmin ?? false;
        final isMediatorLoggedIn = mediator != null;
        final path = state.matchedLocation;

        final isLogin = path == '/desktop/login';
        final isAdminPath = path.startsWith('/admin');
        final isMediatorPath = path.startsWith('/mediator');

        if (isAdminPath && !isAdmin) return '/desktop/login';
        if (isMediatorPath && !isMediatorLoggedIn) return '/desktop/login';

        if (isLogin && isAdmin) return '/admin/dashboard';
        if (isLogin && isMediatorLoggedIn) return '/mediator/dashboard';

        return null;
      },
      routes: [
        GoRoute(
          path: '/desktop/login',
          builder: (context, state) => const DesktopLoginScreen(),
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
        ShellRoute(
          builder: (context, state, child) => MediatorShell(child: child),
          routes: [
            GoRoute(
              path: '/mediator/dashboard',
              builder: (context, state) => const MediatorDashboardScreen(),
            ),
            GoRoute(
              path: '/mediator/products',
              builder: (context, state) => const MediatorProductsScreen(),
            ),
            GoRoute(
              path: '/mediator/publish',
              builder: (context, state) => const MediatorPublishRequestScreen(),
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

class StreamGroup {
  static Stream<dynamic> merge(List<Stream<dynamic>> streams) {
    final controller = StreamController<dynamic>.broadcast();
    final subscriptions = <StreamSubscription<dynamic>>[];

    for (final stream in streams) {
      subscriptions.add(stream.listen(controller.add));
    }

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }
}
