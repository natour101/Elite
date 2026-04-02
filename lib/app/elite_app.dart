import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';

class EliteApp extends StatelessWidget {
  const EliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider(_resolveEntry()));
          return MaterialApp.router(
            title: 'Elite Luxury Store',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }

  AppEntry _resolveEntry() {
    if (kIsWeb) return AppEntry.storefront;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return AppEntry.admin;
    }
    return AppEntry.storefront;
  }
}
