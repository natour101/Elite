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
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Elite Store'),
          actions: [
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('المنتجات'),
            ),
            TextButton(
              onPressed: () => context.go('/cart'),
              child: Text('السلة ($cartCount)'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Container(color: const Color(0xFFF7F4EE), child: child),
      ),
    );
  }
}

class StoreHomeScreen extends ConsumerWidget {
  const StoreHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueBuilder<List<Product>>(
      value: ref.watch(storefrontProductsProvider),
      data: (products) {
        if (products.isEmpty) {
          return const EmptyState(
            title: 'لا توجد منتجات بعد',
            message: 'أضف منتجات من لوحة الأدمن وستظهر هنا مباشرة.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معرض المنتجات',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8),
                  Text('المستخدم يتصفح المنتجات ويضيفها إلى السلة ثم يختار وسيطًا لإتمام الطلب.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 1180 ? 3 : width >= 700 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) => _ProductCard(product: products[index]),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueBuilder<List<Product>>(
      value: ref.watch(storefrontProductsProvider),
      data: (products) {
        Product? product;
        for (final item in products) {
          if (item.id == productId) {
            product = item;
            break;
          }
        }
        if (product == null) {
          return const EmptyState(
            title: 'المنتج غير موجود',
            message: 'تعذر العثور على تفاصيل هذا المنتج.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SectionCard(
              child: Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _ProductPreview(product: product!),
                  SizedBox(
                    width: 540,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text('رقم المنتج: ${product.productNumber}'),
                        Text('التصنيف: ${product.category}'),
                        Text('العلامة: ${product.brand}'),
                        Text('السعر: ${formatCurrency(product.price)}'),
                        Text('المخزون: ${product.stock}'),
                        const SizedBox(height: 18),
                        Text(product.description),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: product.isAvailable
                                  ? () {
                                      ref
                                          .read(cartControllerProvider.notifier)
                                          .addProduct(product!);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('تمت إضافة المنتج إلى السلة'),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('إضافة إلى السلة'),
                            ),
                            OutlinedButton(
                              onPressed: () => context.go('/cart'),
                              child: const Text('فتح السلة'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartControllerProvider);
    if (items.isEmpty) {
      return const EmptyState(
        title: 'السلة فارغة',
        message: 'أضف منتجًا واحدًا أو أكثر ثم تابع إلى صفحة إتمام الطلب.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionCard(
          child: Text(
            'سلة المشتريات',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            children: [
              for (final item in items) ...[
                _CartRow(item: item),
                const Divider(),
              ],
              Row(
                children: [
                  const Text('الإجمالي التقريبي:', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    formatCurrency(ref.watch(cartTotalProvider)),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () => context.go('/checkout'),
                  child: const Text('إتمام الطلب'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedMediatorId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider);
    if (cartItems.isEmpty) {
      return const EmptyState(title: 'لا يمكن إنشاء طلب', message: 'السلة فارغة حاليًا.');
    }

    return AsyncValueBuilder(
      value: ref.watch(mediatorsProvider),
      data: (mediators) {
        if (mediators.isEmpty) {
          return const EmptyState(
            title: 'لا يوجد وسطاء',
            message: 'يجب على الأدمن إضافة الوسطاء أولًا قبل إتمام أي طلب.',
          );
        }
        _selectedMediatorId ??= mediators.first.id;
        final actionState = ref.watch(ordersActionsControllerProvider);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SectionCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إتمام الطلب',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'اسم العميل'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'الاسم مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'رقم الهاتف مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'ملاحظات'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedMediatorId,
                      decoration: const InputDecoration(labelText: 'اختر الوسيط'),
                      items: mediators
                          .map(
                            (mediator) => DropdownMenuItem(
                              value: mediator.id,
                              child: Text('${mediator.name} - ${mediator.location} - ${mediator.phone}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedMediatorId = value),
                    ),
                    const SizedBox(height: 16),
                    for (final mediator in mediators)
                      if (mediator.id == _selectedMediatorId)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE6D9),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الاسم: ${mediator.name}'),
                              Text('الموقع: ${mediator.location}'),
                              Text('الهاتف: ${mediator.phone}'),
                              Text('الكود: ${mediator.code}'),
                            ],
                          ),
                        ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: actionState.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final mediator = mediators.firstWhere((item) => item.id == _selectedMediatorId);
                                await ref.read(ordersActionsControllerProvider.notifier).placeOrder(
                                      PlaceOrderInput(
                                        items: cartItems
                                            .map(
                                              (item) => OrderItem(
                                                productId: item.product.id,
                                                name: item.product.name,
                                                quantity: item.quantity,
                                                price: item.product.price,
                                              ),
                                            )
                                            .toList(),
                                        mediatorId: mediator.id,
                                        mediatorCode: mediator.code,
                                        mediatorName: mediator.name,
                                        customerName: _nameController.text.trim(),
                                        customerPhone: _phoneController.text.trim(),
                                        notes: _notesController.text.trim(),
                                      ),
                                    );
                                final result = ref.read(ordersActionsControllerProvider);
                                if (result.hasError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${result.error}')),
                                  );
                                  return;
                                }
                                ref.read(cartControllerProvider.notifier).clear();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم حفظ الطلب بنجاح')),
                                  );
                                  context.go('/');
                                }
                              },
                        child: Text(actionState.isLoading ? 'جاري الإرسال...' : 'تأكيد الطلب'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductPreview(product: product),
          const SizedBox(height: 14),
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Text('رقم المنتج: ${product.productNumber}'),
          Text('السعر: ${formatCurrency(product.price)}'),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: product.isAvailable
                    ? () {
                        ref.read(cartControllerProvider.notifier).addProduct(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تمت إضافة المنتج إلى السلة')),
                        );
                      }
                    : null,
                child: const Text('إضافة للسلة'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/product/${product.id}'),
                child: const Text('التفاصيل'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          product.imageUrl,
          height: 160,
          width: 320,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackPreview();
          },
        ),
      );
    }

    return _fallbackPreview();
  }

  Widget _fallbackPreview() {
    return Container(
      height: 160,
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE6D9),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        product.name.substring(0, 1).toUpperCase(),
        style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('السعر: ${formatCurrency(item.product.price)}'),
            ],
          ),
        ),
        IconButton(
          onPressed: () => ref.read(cartControllerProvider.notifier).changeQuantity(
                item.product.id,
                item.quantity - 1,
              ),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('${item.quantity}'),
        IconButton(
          onPressed: () => ref.read(cartControllerProvider.notifier).changeQuantity(
                item.product.id,
                item.quantity + 1,
              ),
          icon: const Icon(Icons.add_circle_outline),
        ),
        SizedBox(
          width: 140,
          child: Text(formatCurrency(item.lineTotal), textAlign: TextAlign.center),
        ),
        IconButton(
          onPressed: () => ref.read(cartControllerProvider.notifier).removeProduct(item.product.id),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
