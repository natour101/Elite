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
      redirect: (context, state) {
        final isAdmin = session.isAdmin;
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
            GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),
            GoRoute(path: '/admin/products', builder: (context, state) => const AdminProductsScreen()),
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
            GoRoute(path: '/admin/orders', builder: (context, state) => const AdminOrdersScreen()),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) => MediatorShell(child: child),
          routes: [
            GoRoute(path: '/mediator/dashboard', builder: (context, state) => const MediatorDashboardScreen()),
            GoRoute(path: '/mediator/products', builder: (context, state) => const MediatorProductsScreen()),
            GoRoute(path: '/mediator/publish', builder: (context, state) => const MediatorPublishRequestScreen()),
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
          GoRoute(path: '/segment/men', builder: (context, state) => const SegmentStoreScreen(segment: 'رجالي')),
          GoRoute(path: '/segment/women', builder: (context, state) => const SegmentStoreScreen(segment: 'ستاتي')),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) => ProductDetailsScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
          GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
          GoRoute(
            path: '/contact',
            builder: (context, state) => const SimpleStorePage(
              title: 'اتصل بنا',
              sections: [
                ('رقم الهاتف', '0780045351'),
                ('واتساب', '0795422974'),
                ('ساعات العمل', 'من السبت إلى الخميس، من 10 صباحًا حتى 8 مساءً.'),
              ],
            ),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const SimpleStorePage(
              title: 'من نحن',
              sections: [
                ('رؤيتنا', 'Elite Store منصة لعرض المنتجات الأصلية وتسهيل الطلب وربط العملاء بالوسطاء بطريقة منظمة واحترافية.'),
                ('هدفنا', 'تقديم تجربة طلب واضحة وسريعة مع عرض أنيق للمنتجات وسهولة الوصول إلى الوسطاء.'),
              ],
            ),
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (context, state) => const SimpleStorePage(
              title: 'سياسة الخصوصية',
              sections: [
                ('البيانات', 'نستخدم بيانات الطلب مثل الاسم ورقم الهاتف فقط لخدمة الطلبات وتحسين تجربة الاستخدام.'),
                ('الحماية', 'يتم حفظ البيانات داخل Firebase وفق الإعدادات الفنية المعتمدة للمشروع.'),
              ],
            ),
          ),
          GoRoute(
            path: '/shipping-policy',
            builder: (context, state) => const SimpleStorePage(
              title: 'سياسة الشحن',
              sections: [
                ('مدة الشحن', 'تختلف مدة الشحن حسب المدينة والوسيط المختار وطبيعة المنتج.'),
                ('طريقة التسليم', 'يتم التنسيق مع الوسيط بعد إنشاء الطلب لتأكيد التوصيل أو التسليم.'),
              ],
            ),
          ),
          GoRoute(
            path: '/returns-policy',
            builder: (context, state) => const SimpleStorePage(
              title: 'سياسة الاسترجاع',
              sections: [
                ('الاسترجاع', 'تتم مراجعة طلبات الاسترجاع حسب حالة المنتج وسياسة الإدارة.'),
                ('الاستثناءات', 'بعض المنتجات قد لا تكون قابلة للاسترجاع وفق نوعها أو حالتها.'),
              ],
            ),
          ),
        ],
      ),
    ],
  );
});
