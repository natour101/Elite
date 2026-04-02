import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_copy.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/brand_logo.dart';

class StoreHeader extends StatelessWidget {
  const StoreHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final items = const [
      ('الرئيسية', '/'),
      ('المتجر', '/shop'),
      ('من نحن', '/about'),
      ('تواصل معنا', '/contact'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 32, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF050505).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: AppTheme.gold.withOpacity(0.18)),
        ),
      ),
      child: Row(
        children: [
          const BrandLogo(height: 58),
          const Spacer(),
          if (!mobile)
            Wrap(
              spacing: 12,
              children: [
                for (final item in items)
                  TextButton(
                    onPressed: () => context.go(item.$2),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: Text(item.$1),
                  ),
              ],
            )
          else
            PopupMenuButton<String>(
              color: const Color(0xFF101010),
              onSelected: (value) => context.go(value),
              itemBuilder: (context) => items
                  .map(
                    (item) => PopupMenuItem<String>(
                      value: item.$2,
                      child: Text(
                        item.$1,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              icon: const Icon(Icons.menu_rounded, color: AppTheme.gold),
            ),
        ],
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 22 : 34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        image: kIsWeb
            ? const DecorationImage(
                image: AssetImage(AppAssets.backgroundGif),
                fit: BoxFit.cover,
              )
            : null,
        gradient: kIsWeb
            ? null
            : const LinearGradient(
                colors: [Color(0xFF050505), Color(0xFF121212), Color(0xFF1A140B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(color: AppTheme.gold.withOpacity(0.22)),
      ),
      child: Container(
        padding: EdgeInsets.all(mobile ? 18 : 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.72),
              Colors.black.withOpacity(0.62),
              const Color(0xFF130F08).withOpacity(0.82),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppCopy.companyName.toUpperCase(),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppCopy.slogan,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              AppCopy.heroSubtitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.78),
                    height: 1.8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle = '',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.68),
                  height: 1.7,
                ),
          ),
        ],
      ],
    );
  }
}

class StoreFooter extends StatelessWidget {
  const StoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.gold.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(height: 54, withLabel: true),
          const SizedBox(height: 18),
          Text(
            'خليك إتيكيت... خليك ELITE',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'منتجات أصلية مختارة بهوية فاخرة وظهور راقٍ.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 14),
          const Text(
            'للتواصل: 0780045351',
            style: TextStyle(
              color: AppTheme.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
