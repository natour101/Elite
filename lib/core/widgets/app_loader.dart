import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.label = 'جاري التحميل...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(color: AppTheme.gold),
          ),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    );
  }
}
