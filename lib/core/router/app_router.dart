import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalog/presentation/pages/storefront_pages.dart';
import '../../features/dashboard/presentation/pages/admin_pages.dart';

enum AppEntry { storefront, admin }

final appRouterProvider = Provider.family<GoRouter, AppEntry>((ref, entry) {
  if (entry == AppEntry.admin) {
    return GoRouter(
      initialLocation: '/admin/dashboard',
      routes: [
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => const AdminLoginPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => AdminShell(child: child),
          routes: [
            GoRoute(
              path: '/admin/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/admin/orders',
              builder: (context, state) => const OrdersPage(),
            ),
            GoRoute(
              path: '/admin/settings',
              builder: (context, state) => const SettingsPage(),
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
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(path: '/shop', builder: (context, state) => const ShopPage()),
          GoRoute(
            path: '/segment/:segment',
            builder: (context, state) => SegmentPage(
              segmentSlug: state.pathParameters['segment']!,
            ),
          ),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) =>
                ProductDetailsPage(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const SimpleContentPage(
              title: 'من نحن',
              sections: [
                (
                  'رؤيتنا',
                  'نقدم متجرًا فاخرًا يركز على المنتجات الأصلية فقط بتجربة هادئة وأنيقة.'
                ),
                (
                  'هويتنا',
                  'اللون الأسود للفخامة، الأبيض للنقاء، والذهبي للتفاصيل الراقية التي تبرز الثقة.'
                ),
              ],
            ),
          ),
          GoRoute(path: '/contact', builder: (context, state) => const ContactPage()),
          GoRoute(
            path: '/faq',
            builder: (context, state) => const SimpleContentPage(
              title: 'الأسئلة الشائعة',
              sections: [
                ('هل المنتجات أصلية؟', 'نعم، المتجر مخصص للمنتجات الأصلية فقط.'),
                ('كيف يتم الطلب؟', 'حاليًا يتم الطلب مباشرة عبر نموذج بسيط ثم واتساب.'),
                ('هل يمكن التوسع لاحقًا؟', 'نعم، البنية جاهزة للربط مع سلة مشتريات وFirebase.'),
              ],
            ),
          ),
          GoRoute(
            path: '/shipping-policy',
            builder: (context, state) => const SimpleContentPage(
              title: 'سياسة الشحن',
              sections: [
                ('مدة الشحن', 'يمكن تخصيص المدة حسب المدينة وطريقة التسليم لاحقًا.'),
                ('رسوم الشحن', 'يتم تحديدها وفق سياسة المتجر النهائية عند الإطلاق.'),
              ],
            ),
          ),
          GoRoute(
            path: '/returns-policy',
            builder: (context, state) => const SimpleContentPage(
              title: 'سياسة الاسترجاع',
              sections: [
                ('آلية الاسترجاع', 'يتم تحديدها وفق حالة المنتج وشروط المتجر.'),
                ('المنتجات الخاصة', 'يمكن استثناء بعض المنتجات حسب سياسة الإدارة.'),
              ],
            ),
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (context, state) => const SimpleContentPage(
              title: 'سياسة الخصوصية',
              sections: [
                ('البيانات', 'نحافظ على الحد الأدنى من البيانات اللازمة للتواصل والطلب.'),
                ('الاستخدام', 'تستخدم البيانات فقط لخدمة الطلبات وتحسين التجربة.'),
              ],
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Text('الصفحة غير موجودة: ${state.uri.toString()}'),
        ),
      ),
    ),
  );
});
