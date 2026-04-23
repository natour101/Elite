import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/antique_shell.dart';
import '../../pages/admin_upload_page.dart';
import '../../pages/cart_page.dart';
import '../../pages/home_page.dart';
import '../../pages/product_details_page.dart';
import '../../pages/shop_page.dart';
import '../../pages/stats_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  const adminRoutesEnabled = !kIsWeb;

  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AntiqueShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: '/shop',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const ShopPage(),
            ),
          ),
          GoRoute(
            path: '/product/:id',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: ProductDetailsPage(
                productId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const CartPage(),
            ),
          ),
          if (adminRoutesEnabled)
            GoRoute(
              path: '/admin',
              pageBuilder: (context, state) => _fadePage(
                state: state,
                child: const AdminUploadPage(),
              ),
            ),
          if (adminRoutesEnabled)
            GoRoute(
              path: '/stats',
              pageBuilder: (context, state) => _fadePage(
                state: state,
                child: const StatsPage(),
              ),
            ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

