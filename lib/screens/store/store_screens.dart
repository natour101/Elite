import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/mediators_controller.dart';
import '../../controllers/orders_controller.dart';
import '../../controllers/products_controller.dart';
import '../../models/app_order.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../widgets/app_scaffold_bits.dart';
import '../../widgets/async_value_builder.dart';

class StoreShell extends ConsumerWidget {
  const StoreShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F1E8),
          appBar: AppBar(
            title: const Text('Elite Store', style: TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              for (final item in const [('المنتجات', '/'), ('رجالي', '/segment/men'), ('ستاتي', '/segment/women'), ('اتصل بنا', '/contact')])
                TextButton(onPressed: () => context.go(item.$2), child: Text(item.$1)),
              TextButton(
                onPressed: () => context.go('/cart'),
                child: Text('السلة (${ref.watch(cartCountProvider)})'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: child,
        ),
      );
}

class StoreHomeScreen extends ConsumerWidget {
  const StoreHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(storefrontSegmentFilterProvider.notifier).state = 'الكل';
    return _catalog(context, ref, 'معرض المنتجات', 'متجر ويب احترافي متصل مباشرة مع Firebase.');
  }
}

class SegmentStoreScreen extends ConsumerWidget {
  const SegmentStoreScreen({super.key, required this.segment});
  final String segment;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(storefrontSegmentFilterProvider.notifier).state = segment;
    return _catalog(context, ref, segment, 'تصفح منتجات قسم $segment.');
  }
}

Widget _catalog(BuildContext context, WidgetRef ref, String title, String subtitle) {
  final value = ref.watch(filteredStorefrontProductsProvider);
  return AsyncValueBuilder<List<Product>>(
    value: value,
    loadingMessage: 'جاري تحميل المنتجات من Firebase...',
    errorMessage: 'تعذر تحميل المنتجات من قاعدة البيانات.',
    data: (products) => RefreshIndicator(
      onRefresh: () => ref.read(productsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF17120C), Color(0xFF8C6A39)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 620,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('متصل مباشرة مع Firebase', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, height: 1.8)),
                  ]),
                ),
                Container(
                  width: 220,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(22)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('المعروض الآن', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text('${products.length}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                    const Text('منتج', style: TextStyle(color: Colors.white70)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final item in const [('الكل', '/'), ('رجالي', '/segment/men'), ('ستاتي', '/segment/women')])
              ChoiceChip(
                label: Text(item.$1),
                selected: ref.watch(storefrontSegmentFilterProvider) == item.$1,
                onSelected: (_) => context.go(item.$2),
              ),
            OutlinedButton.icon(
              onPressed: () => ref.read(productsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ]),
          const SizedBox(height: 20),
          if (products.isEmpty)
            const SectionCard(child: Text('لا توجد منتجات ظاهرة حاليًا.'))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth >= 1280 ? 4 : constraints.maxWidth >= 920 ? 3 : constraints.maxWidth >= 620 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: 0.74,
                  ),
                  itemBuilder: (context, index) => _ProductCard(product: products[index]),
                );
              },
            ),
          const SizedBox(height: 24),
          const StoreFooter(),
        ],
      ),
    ),
  );
}

class ProductDetailsScreen extends ConsumerWidget { const ProductDetailsScreen({super.key, required this.productId}); final String productId;
  @override Widget build(BuildContext context, WidgetRef ref) => AsyncValueBuilder<List<Product>>(
    value: ref.watch(storefrontProductsProvider),
    data: (products) {
      final product = products.where((item) => item.id == productId).firstOrNull;
      if (product == null) return const EmptyState(title: 'المنتج غير موجود', message: 'تعذر العثور على هذا المنتج.');
      return ListView(padding: const EdgeInsets.all(24), children: [
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 320, width: double.infinity, child: _ProductImage(product: product)),
          const SizedBox(height: 16),
          Text(product.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(product.description, style: const TextStyle(height: 1.8)),
          const SizedBox(height: 10),
          Text(formatCurrency(product.price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Wrap(spacing: 12, children: [
            ElevatedButton.icon(
              onPressed: product.isAvailable ? () { ref.read(cartControllerProvider.notifier).addProduct(product); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المنتج إلى السلة'))); } : null,
              icon: const Icon(Icons.add_shopping_cart), label: const Text('إضافة إلى السلة'),
            ),
            OutlinedButton(onPressed: () => context.go('/cart'), child: const Text('فتح السلة')),
          ]),
        ])),
        const SizedBox(height: 24), const StoreFooter(),
      ]);
    },
  );
}

class CartScreen extends ConsumerWidget { const CartScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartControllerProvider); if (items.isEmpty) return const EmptyState(title: 'السلة فارغة', message: 'أضف منتجًا واحدًا أو أكثر ثم تابع إلى إتمام الطلب.');
    return ListView(padding: const EdgeInsets.all(24), children: [
      const SectionCard(child: Text('سلة المشتريات', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
      const SizedBox(height: 16),
      SectionCard(child: Column(children: [
        for (final item in items) ...[_CartRow(item: item), const Divider()],
        Row(children: [const Text('الإجمالي التقريبي'), const Spacer(), Text(formatCurrency(ref.watch(cartTotalProvider)), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft, child: ElevatedButton(onPressed: () => context.go('/checkout'), child: const Text('إتمام الطلب'))),
      ])),
    ]);
  }
}

class CheckoutScreen extends ConsumerStatefulWidget { const CheckoutScreen({super.key}); @override ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState(); }
class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>(); final _name = TextEditingController(); final _phone = TextEditingController(); final _notes = TextEditingController(); String? _mediatorId;
  @override void dispose() { _name.dispose(); _phone.dispose(); _notes.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider); if (cartItems.isEmpty) return const EmptyState(title: 'لا يمكن إنشاء طلب', message: 'السلة فارغة حاليًا.');
    return AsyncValueBuilder(value: ref.watch(mediatorsProvider), data: (mediators) {
      if (mediators.isEmpty) return const EmptyState(title: 'لا يوجد وسطاء', message: 'يجب إضافة وسيط واحد على الأقل قبل إتمام الطلب.');
      _mediatorId ??= mediators.first.id; final action = ref.watch(ordersActionsControllerProvider);
      return ListView(padding: const EdgeInsets.all(24), children: [SectionCard(child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('إتمام الطلب', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 18),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'اسم العميل'), validator: (v) => v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null), const SizedBox(height: 12),
        TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'رقم الهاتف'), validator: (v) => v == null || v.trim().isEmpty ? 'رقم الهاتف مطلوب' : null), const SizedBox(height: 12),
        TextFormField(controller: _notes, minLines: 3, maxLines: 4, decoration: const InputDecoration(labelText: 'ملاحظات إضافية')), const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _mediatorId, decoration: const InputDecoration(labelText: 'اختر الوسيط'), items: mediators.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} - ${m.location} - ${m.phone}'))).toList(), onChanged: (v) => setState(() => _mediatorId = v)),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: action.isLoading ? null : () async {
          if (!_formKey.currentState!.validate()) return; final mediator = mediators.firstWhere((m) => m.id == _mediatorId);
          await ref.read(ordersActionsControllerProvider.notifier).placeOrder(PlaceOrderInput(
            items: cartItems.map((item) => OrderItem(productId: item.product.id, name: item.product.name, quantity: item.quantity, price: item.product.price)).toList(),
            mediatorId: mediator.id, mediatorCode: mediator.code, mediatorName: mediator.name, customerName: _name.text.trim(), customerPhone: _phone.text.trim(), notes: _notes.text.trim(),
          ));
          final result = ref.read(ordersActionsControllerProvider); if (result.hasError) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result.error}'))); return; }
          ref.read(cartControllerProvider.notifier).clear(); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الطلب بنجاح'))); context.go('/'); }
        }, child: Text(action.isLoading ? 'جاري الإرسال...' : 'تأكيد الطلب'))),
      ]))), const SizedBox(height: 24), const StoreFooter()]);
    });
  }
}

class SimpleStorePage extends StatelessWidget { const SimpleStorePage({super.key, required this.title, required this.sections}); final String title; final List<(String, String)> sections;
  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: ListView(padding: const EdgeInsets.all(24), children: [Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 20), for (final s in sections) ...[SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Text(s.$2, style: const TextStyle(height: 1.8))])), const SizedBox(height: 16)], const StoreFooter()]),
  );
}

class StoreFooter extends StatelessWidget { const StoreFooter({super.key});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(28)),
    child: Wrap(spacing: 24, runSpacing: 16, alignment: WrapAlignment.spaceBetween, children: [
      const SizedBox(width: 320, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Elite Store', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)), SizedBox(height: 10), Text('منصة عرض وطلب مرتبطة مع Firebase لعرض المنتجات والطلبات والوسطاء بطريقة عملية واحترافية.', style: TextStyle(color: Colors.white70, height: 1.7))])),
      Wrap(spacing: 12, runSpacing: 12, children: [for (final item in const [('اتصل بنا', '/contact'), ('من نحن', '/about'), ('سياسة الخصوصية', '/privacy-policy'), ('سياسة الشحن', '/shipping-policy'), ('سياسة الاسترجاع', '/returns-policy')]) TextButton(onPressed: () => context.go(item.$2), child: Text(item.$1))]),
      const Text('© 2026 Elite Store. جميع الحقوق محفوظة.', style: TextStyle(color: Colors.white60)),
    ]),
  );
}

class _ProductCard extends ConsumerWidget { const _ProductCard({required this.product}); final Product product;
  @override Widget build(BuildContext context, WidgetRef ref) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10))]),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _ProductImage(product: product)), const SizedBox(height: 14),
        Row(children: [Expanded(child: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))), _StatusChip(text: product.isSold ? 'مباع' : product.isReserved ? 'محجوز' : 'متاح')]),
        const SizedBox(height: 8),
        Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.6)),
        const SizedBox(height: 8),
        Text(product.storefrontSegment.isEmpty ? 'غير مصنف' : product.storefrontSegment, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(formatCurrency(product.price), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ElevatedButton(onPressed: product.isAvailable ? () { ref.read(cartControllerProvider.notifier).addProduct(product); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المنتج إلى السلة'))); } : null, child: const Text('إضافة للسلة')),
          OutlinedButton(onPressed: () => context.go('/product/${product.id}'), child: const Text('التفاصيل')),
        ]),
      ]),
    ),
  );
}

class _FeaturedCard extends StatelessWidget { const _FeaturedCard({required this.product}); final Product product;
  @override Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: () => context.go('/product/${product.id}'),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _ProductImage(product: product)), const SizedBox(height: 12), Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 6), Text(formatCurrency(product.price), style: const TextStyle(fontWeight: FontWeight.w900))]),
    ),
  );
}

class _ProductImage extends StatelessWidget { const _ProductImage({required this.product}); final Product product;
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: product.imageUrl.isNotEmpty
        ? Image.network(product.imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
        : _fallback(),
  );
  Widget _fallback() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF0E6D5), Color(0xFFD0B489)], begin: Alignment.topRight, end: Alignment.bottomLeft)),
    alignment: Alignment.center,
    child: Text(product.name.isEmpty ? 'E' : product.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900)),
  );
}

class _StatusChip extends StatelessWidget { const _StatusChip({required this.text}); final String text;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: text == 'مباع' ? const Color(0xFFE9D8D8) : text == 'محجوز' ? const Color(0xFFF7E1B5) : const Color(0xFFDDF0DD), borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class _CartRow extends ConsumerWidget { const _CartRow({required this.item}); final CartItem item;
  @override Widget build(BuildContext context, WidgetRef ref) => Row(children: [
    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(formatCurrency(item.product.price))])),
    IconButton(onPressed: () => ref.read(cartControllerProvider.notifier).changeQuantity(item.product.id, item.quantity - 1), icon: const Icon(Icons.remove_circle_outline)),
    Text('${item.quantity}'),
    IconButton(onPressed: () => ref.read(cartControllerProvider.notifier).changeQuantity(item.product.id, item.quantity + 1), icon: const Icon(Icons.add_circle_outline)),
    SizedBox(width: 120, child: Text(formatCurrency(item.lineTotal), textAlign: TextAlign.center)),
    IconButton(onPressed: () => ref.read(cartControllerProvider.notifier).removeProduct(item.product.id), icon: const Icon(Icons.delete_outline)),
  ]);
}

extension _IterableX<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
