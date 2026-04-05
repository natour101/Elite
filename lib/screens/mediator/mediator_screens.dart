import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/mediator_portal_controller.dart';
import '../../controllers/products_controller.dart';
import '../../models/product.dart';
import '../../widgets/app_scaffold_bits.dart';
import '../../widgets/async_value_builder.dart';

class MediatorShell extends ConsumerWidget {
  const MediatorShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediator = ref.watch(mediatorSessionProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            Container(
              width: 280,
              color: const Color(0xFF141414),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'بوابة الوسيط',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (mediator != null)
                    Text(
                      '${mediator.name} • ${mediator.code}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  const SizedBox(height: 24),
                  ListTile(
                    title: const Text('حسابي', style: TextStyle(color: Colors.white)),
                    onTap: () => context.go('/mediator/dashboard'),
                  ),
                  ListTile(
                    title: const Text('منتجاتي', style: TextStyle(color: Colors.white)),
                    onTap: () => context.go('/mediator/products'),
                  ),
                  ListTile(
                    title: const Text('طلب نشر سلعة', style: TextStyle(color: Colors.white)),
                    onTap: () => context.go('/mediator/publish'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(mediatorSessionProvider.notifier).signOut();
                      context.go('/desktop/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('خروج'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF7F4EE),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MediatorDashboardScreen extends ConsumerWidget {
  const MediatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediator = ref.watch(mediatorSessionProvider);
    final summary = ref.watch(mediatorSummaryProvider);

    if (mediator == null) {
      return const EmptyState(
        title: 'لم يتم تسجيل دخول وسيط',
        message: 'ادخل بالرمز أولًا للوصول إلى بوابة الوسيط.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'مرحبًا ${mediator.name}',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text('تفاصيل الحساب والرصيد الحالي المرتبط بالمبيعات الفعلية.'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MediatorStatCard(label: 'الرصيد الحالي', value: formatCurrency(summary.balance)),
            _MediatorStatCard(label: 'عدد الطلبات', value: '${summary.totalOrders}'),
            _MediatorStatCard(label: 'منتجات مباعة', value: '${summary.productsSold}'),
            _MediatorStatCard(label: 'منتجات محجوزة', value: '${summary.reservedProducts}'),
          ],
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الاسم: ${mediator.name}'),
              Text('الموقع: ${mediator.location}'),
              Text('الهاتف: ${mediator.phone}'),
              Text('الرمز: ${mediator.code}'),
            ],
          ),
        ),
      ],
    );
  }
}

class MediatorProductsScreen extends ConsumerWidget {
  const MediatorProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediator = ref.watch(mediatorSessionProvider);
    if (mediator == null) {
      return const EmptyState(
        title: 'لا توجد جلسة وسيط',
        message: 'ادخل بالرمز أولًا.',
      );
    }

    return AsyncValueBuilder<List<Product>>(
      value: ref.watch(mediatorOwnedProductsProvider),
      data: (products) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'منتجاتي',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: products.isEmpty
                  ? const Text('لا توجد منتجات مرتبطة بهذا الوسيط حاليًا.')
                  : Column(
                      children: products
                          .map((product) => _MediatorProductRow(product: product))
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MediatorProductRow extends ConsumerWidget {
  const _MediatorProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediator = ref.watch(mediatorSessionProvider)!;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text(
        'الحالة: ${product.listingStatus} • السعر: ${formatCurrency(product.price)}',
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: product.isSold
                ? null
                : () {
                    ref.read(productActionsControllerProvider.notifier).updateStatus(
                          productId: product.id,
                          status: 'reserved',
                          mediatorId: mediator.id,
                          mediatorCode: mediator.code,
                        );
                  },
            child: const Text('محجوز'),
          ),
          ElevatedButton(
            onPressed: product.isSold
                ? null
                : () {
                    ref.read(productActionsControllerProvider.notifier).updateStatus(
                          productId: product.id,
                          status: 'sold',
                          mediatorId: mediator.id,
                          mediatorCode: mediator.code,
                        );
                  },
            child: const Text('تم البيع'),
          ),
        ],
      ),
    );
  }
}

class MediatorPublishRequestScreen extends ConsumerStatefulWidget {
  const MediatorPublishRequestScreen({super.key});

  @override
  ConsumerState<MediatorPublishRequestScreen> createState() =>
      _MediatorPublishRequestScreenState();
}

class _MediatorPublishRequestScreenState
    extends ConsumerState<MediatorPublishRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(mediatorPublicationRequestControllerProvider);
    final requests = ref.watch(mediatorPublicationRequestsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'طلب نشر سلعة',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _field(_nameController, 'اسم المنتج'),
                const SizedBox(height: 12),
                _field(_brandController, 'البراند'),
                const SizedBox(height: 12),
                _field(_categoryController, 'التصنيف'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'السعر'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'رابط الصورة'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: requestState.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            await ref
                                .read(
                                  mediatorPublicationRequestControllerProvider
                                      .notifier,
                                )
                                .submit(
                                  PublicationRequestInput(
                                    name: _nameController.text.trim(),
                                    brand: _brandController.text.trim(),
                                    category: _categoryController.text.trim(),
                                    description:
                                        _descriptionController.text.trim(),
                                    price: double.tryParse(
                                      _priceController.text.trim(),
                                    ),
                                    imageUrl: _imageUrlController.text.trim(),
                                  ),
                                );

                            final result =
                                ref.read(mediatorPublicationRequestControllerProvider);
                            if (result.hasError) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${result.error}')),
                                );
                              }
                              return;
                            }

                            _nameController.clear();
                            _brandController.clear();
                            _categoryController.clear();
                            _descriptionController.clear();
                            _priceController.clear();
                            _imageUrlController.clear();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم إرسال طلب النشر بنجاح'),
                                ),
                              );
                            }
                          },
                    child: Text(
                      requestState.isLoading ? 'جاري الإرسال...' : 'إرسال الطلب',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AsyncValueBuilder(
          value: requests,
          data: (items) {
            return SectionCard(
              child: items.isEmpty
                  ? const Text('لا توجد طلبات نشر سابقة.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.category} • ${item.brand} • ${item.status}',
                              ),
                              trailing: Text(formatCurrency(item.price)),
                            ),
                          )
                          .toList(),
                    ),
            );
          },
        ),
      ],
    );
  }

  TextFormField _field(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value == null || value.trim().isEmpty ? 'مطلوب' : null,
    );
  }
}

class _MediatorStatCard extends StatelessWidget {
  const _MediatorStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
