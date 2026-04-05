import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/mediators_controller.dart';
import '../../controllers/orders_controller.dart';
import '../../controllers/products_controller.dart';
import '../../models/app_order.dart';
import '../../models/mediator.dart';
import '../../models/mediators_stats.dart';
import '../../models/product.dart';
import '../../services/mediators_service.dart';
import '../../widgets/app_scaffold_bits.dart';
import '../../widgets/async_value_builder.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final items = const [
      ('لوحة التحكم', '/admin/dashboard'),
      ('المنتجات', '/admin/products'),
      ('الوسطاء', '/admin/mediators'),
      ('الطلبات', '/admin/orders'),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            Container(
              width: 280,
              color: const Color(0xFF101010),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ELITE ADMIN',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نسخة ويندوز مخصصة لإدارة المنتجات والوسطاء والطلبات.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 28),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        tileColor: currentPath.startsWith(item.$2)
                            ? const Color(0xFFC9A14A)
                            : Colors.white.withOpacity(0.06),
                        title: Text(
                          item.$1,
                          style: TextStyle(
                            color: currentPath.startsWith(item.$2) ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => context.go(item.$2),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authActionControllerProvider.notifier).signOut();
                      if (context.mounted) context.go('/desktop/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ),
            Expanded(child: Container(color: const Color(0xFFF7F4EE), child: child)),
          ],
        ),
      ),
    );
  }
}

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@Elite.jo');
  final _passwordController = TextEditingController(text: '12345678');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(authActionControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 480,
            child: SectionCard(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تسجيل دخول الأدمن', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    const Text('يسمح فقط للحساب الإداري المحدد في Firebase Auth بالدخول إلى لوحة التحكم.'),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'البريد مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'كلمة المرور'),
                      obscureText: true,
                      validator: (value) => value == null || value.trim().isEmpty ? 'كلمة المرور مطلوبة' : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: actionState.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                await ref.read(authActionControllerProvider.notifier).signInAdmin(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    );
                                final result = ref.read(authActionControllerProvider);
                                if (result.hasError) {
                                  final error = result.error;
                                  final message = error is FirebaseAuthException
                                      ? error.message ?? error.code
                                      : '$error';
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  }
                                  return;
                                }
                                final session = ref.read(authSessionProvider);
                                if (!session.isAdmin) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('لم يتم اعتماد جلسة الأدمن بعد.'),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                if (mounted) context.go('/admin/dashboard');
                              },
                        child: Text(actionState.isLoading ? 'جاري تسجيل الدخول...' : 'دخول'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final mediatorStats = ref.watch(mediatorStatsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('لوحة التحكم', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatBox(label: 'إجمالي المنتجات', value: '${stats['products'] ?? 0}'),
            _StatBox(label: 'إجمالي الوسطاء', value: '${stats['mediators'] ?? 0}'),
            _StatBox(label: 'إجمالي الطلبات', value: '${stats['orders'] ?? 0}'),
            _StatBox(label: 'إجمالي المبيعات', value: formatCurrency((stats['sales'] ?? 0).toDouble())),
          ],
        ),
        const SizedBox(height: 24),
        const Text('إحصائيات الوسطاء', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        AsyncValueBuilder<List<MediatorStats>>(
          value: mediatorStats,
          data: (items) {
            if (items.isEmpty) {
              return const SectionCard(child: Text('لا توجد بيانات وسطاء أو طلبات بعد.'));
            }
            return SectionCard(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('الوسيط')),
                    DataColumn(label: Text('الكود')),
                    DataColumn(label: Text('عدد الطلبات')),
                    DataColumn(label: Text('المنتجات المباعة')),
                    DataColumn(label: Text('إجمالي المبيعات')),
                  ],
                  rows: items
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(Text(item.mediator.name)),
                            DataCell(Text(item.mediator.code)),
                            DataCell(Text('${item.ordersCount}')),
                            DataCell(Text('${item.productsSold}')),
                            DataCell(Text(formatCurrency(item.totalSales))),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueBuilder<List<Product>>(
      value: ref.watch(productsProvider),
      data: (products) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                const Expanded(child: Text('إدارة المنتجات', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
                ElevatedButton.icon(
                  onPressed: () => _showProductDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة منتج'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: products.isEmpty
                  ? const Text('لا توجد منتجات بعد.')
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('الاسم')),
                          DataColumn(label: Text('رقم المنتج')),
                          DataColumn(label: Text('التصنيف')),
                          DataColumn(label: Text('السعر')),
                          DataColumn(label: Text('المخزون')),
                          DataColumn(label: Text('مميز')),
                          DataColumn(label: Text('الإجراءات')),
                        ],
                        rows: products.map((product) => _productRow(context, ref, product)).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

DataRow _productRow(BuildContext context, WidgetRef ref, Product product) {
  return DataRow(
    cells: [
      DataCell(Text(product.name)),
      DataCell(Text(product.productNumber)),
      DataCell(Text(product.category)),
      DataCell(Text(formatCurrency(product.price))),
      DataCell(Text('${product.stock}')),
      DataCell(Icon(product.isFeatured ? Icons.check_circle : Icons.remove_circle_outline)),
      DataCell(
        Wrap(
          spacing: 8,
          children: [
            IconButton(
              onPressed: () => _showProductDialog(context, ref, product: product),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: () async => ref.read(productActionsControllerProvider.notifier).delete(product.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    ],
  );
}

class AdminMediatorsScreen extends ConsumerWidget {
  const AdminMediatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueBuilder<List<MediatorProfile>>(
      value: ref.watch(filteredMediatorsProvider),
      data: (mediators) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                const Expanded(child: Text('إدارة الوسطاء', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
                ElevatedButton.icon(
                  onPressed: () => _showMediatorDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة وسيط'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: TextField(
                onChanged: (value) => ref.read(mediatorSearchProvider.notifier).state = value,
                decoration: const InputDecoration(
                  labelText: 'البحث بالاسم أو الكود',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: mediators.isEmpty
                  ? const Text('لا توجد نتائج.')
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('الاسم')),
                          DataColumn(label: Text('الموقع')),
                          DataColumn(label: Text('الهاتف')),
                          DataColumn(label: Text('الكود')),
                          DataColumn(label: Text('الإجراءات')),
                        ],
                        rows: mediators.map((mediator) => _mediatorRow(context, ref, mediator)).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

DataRow _mediatorRow(BuildContext context, WidgetRef ref, MediatorProfile mediator) {
  return DataRow(
    cells: [
      DataCell(Text(mediator.name)),
      DataCell(Text(mediator.location)),
      DataCell(Text(mediator.phone)),
      DataCell(Text(mediator.code)),
      DataCell(
        Wrap(
          spacing: 8,
          children: [
            IconButton(
              onPressed: () => context.go('/admin/mediators/${mediator.id}'),
              icon: const Icon(Icons.open_in_new),
            ),
            IconButton(
              onPressed: () => _showMediatorDialog(context, ref, mediator: mediator),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: () async => ref.read(mediatorActionsControllerProvider.notifier).delete(mediator),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    ],
  );
}

class AdminMediatorDetailsScreen extends ConsumerWidget {
  const AdminMediatorDetailsScreen({super.key, required this.mediatorId});

  final String mediatorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediators = ref.watch(mediatorsProvider);
    final orders = ref.watch(ordersProvider);
    return AsyncValueBuilder<List<MediatorProfile>>(
      value: mediators,
      data: (mediatorsData) {
        MediatorProfile? mediator;
        for (final item in mediatorsData) {
          if (item.id == mediatorId) {
            mediator = item;
            break;
          }
        }
        if (mediator == null) {
          return const EmptyState(title: 'الوسيط غير موجود', message: 'تعذر العثور على هذا الوسيط.');
        }
        final ordersData = orders.valueOrNull ?? const <AppOrder>[];
        final related = ordersData.where((item) => item.mediatorId == mediator!.id).toList();
        final stats = MediatorStats.fromOrders(mediator!, ordersData);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => context.go('/admin/mediators'), icon: const Icon(Icons.arrow_back)),
                const SizedBox(width: 8),
                Text(mediator!.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatBox(label: 'عدد الطلبات', value: '${stats.ordersCount}'),
                _StatBox(label: 'المنتجات المباعة', value: '${stats.productsSold}'),
                _StatBox(label: 'إجمالي المبيعات', value: formatCurrency(stats.totalSales)),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الاسم: ${mediator!.name}'),
                  Text('الموقع: ${mediator.location}'),
                  Text('الهاتف: ${mediator.phone}'),
                  Text('الكود: ${mediator.code}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: related.isEmpty
                  ? const Text('لا توجد طلبات مرتبطة بهذا الوسيط بعد.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الطلبات المرتبطة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        for (final order in related) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('طلب ${order.id.substring(0, 6)}'),
                            subtitle: Text('${order.customerName} - ${DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt)}'),
                            trailing: Text('${order.totalQuantity} منتج', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          const Divider(),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueBuilder<List<AppOrder>>(
      value: ref.watch(ordersProvider),
      data: (orders) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('إدارة الطلبات', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            SectionCard(
              child: orders.isEmpty
                  ? const Text('لا توجد طلبات بعد.')
                  : Column(
                      children: orders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OrderPanel(order: order),
                      )).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderPanel extends ConsumerWidget {
  const _OrderPanel({required this.order});

  final AppOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5DDCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('الطلب ${order.id.substring(0, 6)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              StatusChip(label: order.status),
              DropdownButton<String>(
                value: order.status,
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('pending')),
                  DropdownMenuItem(value: 'processing', child: Text('processing')),
                  DropdownMenuItem(value: 'completed', child: Text('completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(ordersActionsControllerProvider.notifier).updateStatus(orderId: order.id, status: value);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('الوسيط: ${order.mediatorName}'),
          Text('كود الوسيط: ${order.mediatorCode}'),
          Text('العميل: ${order.customerName}'),
          Text('الهاتف: ${order.customerPhone}'),
          Text('الوقت: ${DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt)}'),
          if (order.notes.isNotEmpty) Text('ملاحظات: ${order.notes}'),
          const SizedBox(height: 12),
          const Text('تفاصيل المنتجات', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final item in order.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(item.name),
              subtitle: Text('الكمية: ${item.quantity}'),
              trailing: Text(formatCurrency(item.price)),
            ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

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
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

Future<void> _showProductDialog(BuildContext context, WidgetRef ref, {Product? product}) async {
  final nameController = TextEditingController(text: product?.name ?? '');
  final numberController = TextEditingController(text: product?.productNumber ?? '');
  final categoryController = TextEditingController(text: product?.category ?? '');
  final brandController = TextEditingController(text: product?.brand ?? '');
  final priceController = TextEditingController(text: product?.price?.toString() ?? '');
  final descriptionController = TextEditingController(text: product?.description ?? '');
  final stockController = TextEditingController(text: product?.stock.toString() ?? '0');
  final imageController = TextEditingController(text: product?.imageUrl ?? '');
  final mediatorCodeController = TextEditingController(text: product?.mediatorCode ?? '');
  final formKey = GlobalKey<FormState>();
  var isFeatured = product?.isFeatured ?? false;
  var listingStatus = product?.listingStatus ?? 'active';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(product == null ? 'إضافة منتج' : 'تعديل منتج'),
            content: SizedBox(
              width: 560,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _requiredField(nameController, 'اسم المنتج'),
                      const SizedBox(height: 12),
                      _requiredField(numberController, 'رقم المنتج'),
                      const SizedBox(height: 12),
                      _requiredField(categoryController, 'التصنيف'),
                      const SizedBox(height: 12),
                      _requiredField(brandController, 'العلامة'),
                      const SizedBox(height: 12),
                      TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'السعر (اختياري)')),
                      const SizedBox(height: 12),
                      _requiredField(stockController, 'المخزون'),
                      const SizedBox(height: 12),
                      TextFormField(controller: imageController, decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)')),
                      const SizedBox(height: 12),
                      TextFormField(controller: mediatorCodeController, decoration: const InputDecoration(labelText: 'Mediator Code (optional)')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: listingStatus,
                        decoration: const InputDecoration(labelText: 'Listing Status'),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('active')),
                          DropdownMenuItem(value: 'reserved', child: Text('reserved')),
                          DropdownMenuItem(value: 'sold', child: Text('sold')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => listingStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'الوصف'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('منتج مميز'),
                        value: isFeatured,
                        onChanged: (value) => setState(() => isFeatured = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await ref.read(productActionsControllerProvider.notifier).save(
                        ProductFormData(
                          id: product?.id ?? '',
                          createdAt: product?.createdAt,
                          name: nameController.text.trim(),
                          productNumber: numberController.text.trim(),
                          category: categoryController.text.trim(),
                          brand: brandController.text.trim(),
                          description: descriptionController.text.trim(),
                          stock: int.tryParse(stockController.text.trim()) ?? 0,
                          isFeatured: isFeatured,
                          price: double.tryParse(priceController.text.trim()),
                          imageUrl: imageController.text.trim(),
                          mediatorCode: mediatorCodeController.text.trim(),
                          listingStatus: listingStatus,
                        ),
                      );
                  if (context.mounted) Navigator.of(dialogContext).pop();
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showMediatorDialog(BuildContext context, WidgetRef ref, {MediatorProfile? mediator}) async {
  final nameController = TextEditingController(text: mediator?.name ?? '');
  final locationController = TextEditingController(text: mediator?.location ?? '');
  final phoneController = TextEditingController(text: mediator?.phone ?? '');
  final codeController = TextEditingController(text: mediator?.code ?? '');
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(mediator == null ? 'إضافة وسيط' : 'تعديل وسيط'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _requiredField(nameController, 'اسم الوسيط'),
                const SizedBox(height: 12),
                _requiredField(locationController, 'الموقع'),
                const SizedBox(height: 12),
                _requiredField(phoneController, 'رقم الهاتف'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'الكود الفريد'),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';
                    if (normalized.length != 4) return 'يجب أن يكون 4 أحرف';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(mediatorActionsControllerProvider.notifier).save(
                    MediatorFormData(
                      id: mediator?.id ?? '',
                      createdAt: mediator?.createdAt,
                      name: nameController.text.trim(),
                      location: locationController.text.trim(),
                      phone: phoneController.text.trim(),
                      code: codeController.text.trim().toUpperCase(),
                    ),
                  );
              final result = ref.read(mediatorActionsControllerProvider);
              if (result.hasError && context.mounted) {
                final error = result.error;
                final message = error is DuplicateMediatorCodeException ? 'كود الوسيط مستخدم بالفعل.' : '$error';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                return;
              }
              if (context.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('حفظ'),
          ),
        ],
      );
    },
  );
}

TextFormField _requiredField(TextEditingController controller, String label) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    validator: (value) => value == null || value.trim().isEmpty ? 'مطلوب' : null,
  );
}
