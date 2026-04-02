import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../catalog/presentation/controllers/catalog_controller.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Dashboard', '/admin/dashboard'),
      ('الطلبات', '/admin/orders'),
      ('الإعدادات', '/admin/settings'),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            Container(
              width: 260,
              color: AppTheme.black,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ELITE ADMIN',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          )),
                  const SizedBox(height: 8),
                  const Text('لوحة إدارة احترافية',
                      style: TextStyle(color: AppTheme.gold)),
                  const SizedBox(height: 24),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => context.go(item.$2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        tileColor: Colors.white.withOpacity(0.05),
                        title: Text(item.$1,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppTheme.offWhite,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.black,
        body: Center(
          child: Card(
            child: SizedBox(
              width: 420,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تسجيل دخول الإدارة',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    const Text('واجهة أولية جاهزة للربط مع Firebase Auth لاحقًا.'),
                    const SizedBox(height: 18),
                    const TextField(decoration: InputDecoration(labelText: 'البريد الإلكتروني')),
                    const SizedBox(height: 12),
                    const TextField(
                      decoration: InputDecoration(labelText: 'كلمة المرور'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('دخول'),
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

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return products.when(
      data: (items) {
        final featured = items.where((e) => e.isFeatured).length;
        final lowStock = items.where((e) => e.stock <= 3).length;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(title: 'إجمالي المنتجات', value: '${items.length}'),
                  _StatCard(title: 'منتجات مميزة', value: '$featured'),
                  _StatCard(title: 'مخزون منخفض', value: '$lowStock'),
                  const _StatCard(title: 'طلبات اليوم', value: '12'),
                ],
              ),
              const SizedBox(height: 24),
              const _AdminSectionTitle(title: 'إدارة المنتجات'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search_rounded),
                                hintText: 'بحث داخل المنتجات',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة منتج'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('الاسم')),
                            DataColumn(label: Text('الرقم')),
                            DataColumn(label: Text('الفئة')),
                            DataColumn(label: Text('السعر')),
                            DataColumn(label: Text('المخزون')),
                            DataColumn(label: Text('الإجراءات')),
                          ],
                          rows: items
                              .map(
                                (item) => DataRow(cells: [
                                  DataCell(Text(item.name)),
                                  DataCell(Text(item.productNumber)),
                                  DataCell(Text(item.category)),
                                  DataCell(Text('${item.price}')),
                                  DataCell(Text('${item.stock}')),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.edit_outlined)),
                                      IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.delete_outline)),
                                    ],
                                  )),
                                ]),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _AdminSectionTitle(title: 'إضافة / تعديل منتج'),
              const SizedBox(height: 12),
              const ProductFormCard(),
            ],
          ),
        );
      },
      loading: () => const AppLoader(),
      error: (_, __) => const Center(child: Text('تعذر تحميل لوحة التحكم')),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AdminSectionTitle(title: 'إدارة الطلبات'),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('الطلب')),
                  DataColumn(label: Text('المنتج')),
                  DataColumn(label: Text('العميل')),
                  DataColumn(label: Text('الحالة')),
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('#ORD-1001')),
                    DataCell(Text('ساعة Luxury Edition')),
                    DataCell(Text('أحمد خالد')),
                    DataCell(Text('جديد')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('#ORD-1002')),
                    DataCell(Text('عطر فرنسي')),
                    DataCell(Text('سارة محمود')),
                    DataCell(Text('تم التواصل')),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminSectionTitle(title: 'إعدادات المتجر'),
          SizedBox(height: 14),
          ProductFormCard(isSettings: true),
        ],
      ),
    );
  }
}

class ProductFormCard extends StatelessWidget {
  const ProductFormCard({super.key, this.isSettings = false});

  final bool isSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (!isSettings) ...const [
              _FormInput(label: 'اسم المنتج'),
              _FormInput(label: 'رقم المنتج'),
              _FormInput(label: 'السعر'),
              _FormInput(label: 'البرند'),
              _FormInput(label: 'التصنيف'),
              _FormInput(label: 'الوصف', width: 620),
              _FormInput(label: 'اسم التاجر البائع'),
              _FormInput(label: 'رقم هاتف البائع'),
              _FormInput(label: 'كمية المخزون'),
            ] else ...const [
              _FormInput(label: 'اسم المتجر'),
              _FormInput(label: 'رقم التواصل'),
              _FormInput(label: 'رقم واتساب'),
              _FormInput(label: 'العنوان'),
              _FormInput(label: 'ساعات العمل', width: 620),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('منتج مميز'),
                SizedBox(width: 8),
                Switch(value: true, onChanged: null),
              ],
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save_outlined),
              label: Text(isSettings ? 'حفظ الإعدادات' : 'حفظ المنتج'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({required this.label, this.width = 300});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(decoration: InputDecoration(labelText: label)),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSectionTitle extends StatelessWidget {
  const _AdminSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
