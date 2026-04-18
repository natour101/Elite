import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/portal/presentation/pages/portal_pages.dart';
import '../../models/product.dart';
import '../../screens/store/store_screens.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => StoreShell(
          routeLocation: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const StoreHomeScreen(),
          ),
          GoRoute(
            path: '/segment/men',
            builder: (context, state) =>
                const SegmentStoreScreen(segment: kMenSegment),
          ),
          GoRoute(
            path: '/segment/women',
            builder: (context, state) =>
                const SegmentStoreScreen(segment: kWomenSegment),
          ),
          GoRoute(
            path: '/segment/antique',
            builder: (context, state) =>
                const SegmentStoreScreen(segment: kAntiqueSegment),
          ),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) => ProductDetailsScreen(
              productId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/policies',
            builder: (context, state) => const PoliciesPage(),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutCompanyPage(),
          ),
          GoRoute(
            path: '/team',
            builder: (context, state) => const TeamPage(),
          ),
          GoRoute(
            path: '/portal',
            builder: (context, state) => const PortalGatePage(),
          ),
        ],
      ),
    ],
  );
});
