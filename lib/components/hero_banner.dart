import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/app_spacing.dart';
import 'antique_shell.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2B1E17), Color(0xFF6A4C36)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 840;

                final title = Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'تحف وقطع قديمة مختارة بعناية',
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'تصفح القطع واطلبها مباشرة عبر واتساب.',
                        style: textTheme.bodyLarge?.copyWith(color: const Color(0xFFF1E3D1)),
                      ),
                    ],
                  ),
                );

                final button = OutlinedButton(
                  onPressed: () => context.go('/shop'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFF1D5A7)),
                  ),
                  child: const Text('عرض المنتجات'),
                );

                if (wide) {
                  return Row(
                    children: [
                      title,
                      const SizedBox(width: AppSpacing.md),
                      button,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.md),
                    button,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
