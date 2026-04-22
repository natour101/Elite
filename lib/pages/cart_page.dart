import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/antique_shell.dart';
import '../components/cart_item_card.dart';
import '../components/whatsapp_order_sheet.dart';
import '../controllers/store_controller.dart';
import '../utils/app_spacing.dart';
import '../utils/currency_formatter.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStatsProvider.notifier).recordCartVisit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);

    return PageFrame(
      child: item == null
          ? EmptyStateCard(
              title: 'السلة فارغة',
              message: 'أضف منتجًا واحدًا إلى السلة ثم أرسل الطلب مباشرة عبر واتساب.',
              actionLabel: 'تصفح المتجر',
              onAction: () => context.go('/shop'),
            )
          : ListView(
              children: [
                Text('السلة', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: AppSpacing.md),
                CartItemCard(item: item),
                const SizedBox(height: AppSpacing.md),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ملخص الطلب', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.md),
                      const _SummaryRow(label: 'عدد المنتجات', value: '1'),
                      _SummaryRow(label: 'الإجمالي', value: formatPrice(subtotal)),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(appStatsProvider.notifier).recordOrderRequest();
                            WhatsAppOrderSheet.showCart(
                              context,
                              items: [item],
                              total: subtotal,
                            );
                          },
                          child: const Text('إرسال الطلب على واتساب'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
