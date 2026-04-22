import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/store_controller.dart';
import '../core/theme/app_theme.dart';
import '../utils/app_spacing.dart';
import 'platform_banner_ad.dart';

class AntiqueShell extends ConsumerWidget {
  const AntiqueShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemsCountProvider);
    final location = GoRouterState.of(context).uri.toString();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 74,
          title: const _BrandLockup(),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'السلة',
                  onPressed: () => context.go('/cart'),
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
                if (cartCount > 0)
                  Positioned(
                    top: 16,
                    left: 10,
                    child: Container(
                      height: 18,
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppTheme.antiqueGold,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: _BackdropLayer()),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  _TopNavigation(location: location),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const PlatformBannerAd(),
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 420 ? 12.0 : 20.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 20),
          child: child,
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0D0B6)),
          ),
          child: Image.asset('assets/branding/store_logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'دار الأنتيكا',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final items = <({String title, String route, IconData icon})>[
      (title: 'الرئيسية', route: '/', icon: Icons.home_rounded),
      (title: 'المنتجات', route: '/shop', icon: Icons.storefront_rounded),
      (title: 'السلة', route: '/cart', icon: Icons.shopping_bag_rounded),
      (title: 'الإحصائيات', route: '/stats', icon: Icons.query_stats_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          return Row(
            children: [
              for (final item in items)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _NavButton(
                      title: item.title,
                      icon: item.icon,
                      compact: compact,
                      selected: location == item.route,
                      onTap: () => context.go(item.route),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.title,
    required this.icon,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.wood : Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12, horizontal: 8),
          child: compact
              ? Icon(icon, color: selected ? Colors.white : AppTheme.bronze)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: selected ? Colors.white : AppTheme.bronze),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: selected ? Colors.white : AppTheme.bronze,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BackdropLayer extends StatelessWidget {
  const _BackdropLayer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF8F1E7),
            Color(0xFFF0E1CC),
            Color(0xFFE7D4BA),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -10,
            child: _GlowOrb(
              color: AppTheme.antiqueGold.withValues(alpha: 0.18),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -20,
            left: -40,
            child: _GlowOrb(
              color: AppTheme.wood.withValues(alpha: 0.12),
              size: 260,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty_rounded, size: 46, color: AppTheme.antiqueGold),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: textTheme.bodyLarge, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
