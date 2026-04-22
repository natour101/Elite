import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';

class EliteApp extends StatelessWidget {
  const EliteApp({super.key, this.firebaseError});

  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            title: 'دار الأنتيكا',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
            builder: (context, child) {
              if (firebaseError == null) {
                return child ?? const SizedBox.shrink();
              }

              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  Positioned(
                    right: 16,
                    left: 16,
                    bottom: 16,
                    child: Material(
                      color: const Color(0xFF2F2118),
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'تعذر تشغيل خدمات Firebase بالكامل حالياً، لذا سيعتمد المتجر على بيانات الأنتيكا الاحتياطية للحفاظ على السرعة والاستقرار.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
