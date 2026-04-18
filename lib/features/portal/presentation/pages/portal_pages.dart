import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import '../../../../controllers/dashboard_controller.dart';
import '../../../../controllers/mediators_controller.dart';
import '../../../../controllers/portal_session_controller.dart';
import '../../../../controllers/products_controller.dart';
import '../../../../controllers/site_metrics_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../models/dashboard_summary.dart';
import '../../../../models/mediator.dart';
import '../../../../models/portal_session.dart';
import '../../../../models/product.dart';
import '../../../../services/whatsapp_service.dart';
import '../../../../widgets/app_scaffold_bits.dart';

const _portalBackground = Color(0xFFF7F3EC);
const _portalInk = Color(0xFF17120E);
const _portalGold = Color(0xFFC39A47);
const _portalSurface = Colors.white;

class PortalGatePage extends ConsumerWidget {
  const PortalGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(portalSessionProvider).valueOrNull;
    return session == null ? const PortalLoginPage() : PortalHomePage(session: session);
  }
}

extension _PortalHomePageActions on _PortalHomePageState {
  Future<void> _showMediatorDialog() async {
    final name = TextEditingController();
    final username = TextEditingController();
    final code = TextEditingController();
    final phone = TextEditingController();
    final location = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('وسيط جديد'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(controller: name, label: 'الاسم', validator: _required),
                _DialogField(controller: username, label: 'اليوزر', validator: _required),
                _DialogField(controller: code, label: 'الكود', validator: _required),
                _DialogField(controller: phone, label: 'الهاتف'),
                _DialogField(controller: location, label: 'المدينة'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(mediatorsServiceProvider).saveMediator(
                    Mediator(
                      id: '',
                      name: name.text.trim(),
                      username: username.text.trim().toUpperCase(),
                      code: code.text.trim().toUpperCase(),
                      phone: phone.text.trim(),
                      location: location.text.trim(),
                      createdAt: DateTime.now(),
                    ),
                  );
              ref.invalidate(mediatorsProvider);
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ الوسيط')),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductDialog(PortalSession session) async {
    if (!session.isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الوسيط لا يستطيع إضافة منتجات، ويمكنه فقط بيع منتجات المنصة.'),
          ),
        );
      }
      return;
    }

    final name = TextEditingController();
    final number = TextEditingController();
    final price = TextEditingController();
    final ownerName = TextEditingController();
    final ownerPhone = TextEditingController();
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var section = AppConstants.productSections.first;
    var featured = false;
    var generatingNumber = true;
    var uploadingImage = false;
    String? submitError;
    XFile? selectedImage;
    Uint8List? selectedImageBytes;

    Future<void> generateNumber(StateSetter setDialogState) async {
      setDialogState(() {
        generatingNumber = true;
        submitError = null;
      });
      try {
        final generated =
            await ref.read(productsServiceProvider).generateUniqueProductNumber();
        number.text = generated;
      } catch (error) {
        submitError = '$error'.replaceFirst('Exception: ', '');
      } finally {
        if (mounted) {
          setDialogState(() => generatingNumber = false);
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (generatingNumber && number.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) {
                generateNumber(setDialogState);
              }
            });
          }

          return AlertDialog(
            title: const Text('منتج جديد'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogField(controller: name, label: 'اسم المنتج', validator: _required),
                      _DialogField(
                        controller: number,
                        label: 'رقم المنتج',
                        validator: _required,
                        readOnly: true,
                        suffixIcon: generatingNumber
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                tooltip: 'توليد رقم جديد',
                                onPressed: () => generateNumber(setDialogState),
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                      ),
                      _DialogField(
                        controller: price,
                        label: 'السعر',
                        validator: _required,
                        keyboardType: TextInputType.number,
                      ),
                      DropdownButtonFormField<String>(
                        value: section,
                        decoration: const InputDecoration(labelText: 'القسم'),
                        items: AppConstants.productSections
                            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => section = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: uploadingImage
                              ? null
                              : () async {
                                  final picker = ImagePicker();
                                  final file = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 88,
                                  );
                                  if (file == null) return;
                                  final bytes = await file.readAsBytes();
                                  setDialogState(() {
                                    selectedImage = file;
                                    selectedImageBytes = bytes;
                                  });
                                },
                          icon: uploadingImage
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            selectedImage == null ? 'اختيار صورة ورفعها إلى Cloudinary' : 'تغيير الصورة',
                          ),
                        ),
                      ),
                      if (selectedImage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F4EC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            selectedImage!.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                      if (selectedImageBytes != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            selectedImageBytes!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _DialogField(controller: ownerName, label: 'اسم صاحب المنتج'),
                      _DialogField(
                        controller: ownerPhone,
                        label: 'رقم صاحب المنتج',
                        keyboardType: TextInputType.phone,
                      ),
                      _DialogField(
                        controller: description,
                        label: 'الوصف',
                        validator: _required,
                        maxLines: 4,
                      ),
                      if (submitError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          submitError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      SwitchListTile(
                        value: featured,
                        onChanged: (value) => setDialogState(() => featured = value),
                        title: const Text('منتج مميز'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: generatingNumber || uploadingImage
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        if (selectedImage == null) {
                          setDialogState(() => submitError = 'يرجى اختيار صورة المنتج.');
                          return;
                        }
                        setDialogState(() => submitError = null);
                        try {
                          setDialogState(() => uploadingImage = true);
                          final imageUrl = await ref
                              .read(cloudinaryServiceProvider)
                              .uploadProductImage(selectedImage!);
                          final mediator = session.mediator;
                          await ref.read(productsServiceProvider).saveProduct(
                                Product(
                                  id: '',
                                  name: name.text.trim(),
                                  productNumber: number.text.trim(),
                                  category: section,
                                  brand: '',
                                  description: description.text.trim(),
                                  stock: 1,
                                  isFeatured: featured,
                                  createdAt: DateTime.now(),
                                  price: double.tryParse(price.text.trim()),
                                  imageUrl: imageUrl,
                                  segment: section,
                                  ownerName: ownerName.text.trim(),
                                  ownerPhone: ownerPhone.text.trim(),
                                  listingStatus: kProductStatusAvailable,
                                  approvalStatus: 'approved',
                                  listedByMediatorId: mediator?.id ?? '',
                                  listedByMediatorCode: mediator?.code ?? '',
                                  listedByMediatorName: mediator?.name ?? '',
                                  mediatorId: mediator?.id ?? '',
                                  mediatorCode: mediator?.code ?? '',
                                  reservedByMediatorId: '',
                                  reservedByMediatorCode: '',
                                  reservedByMediatorName: '',
                                  reservedAt: null,
                                  lastAction: 'admin_listing',
                                ),
                              );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          await ref.read(productsProvider.notifier).refresh();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('تم حفظ المنتج'),
                            ),
                          );
                        } catch (error) {
                          setDialogState(() {
                            submitError =
                                '$error'.replaceFirst('Exception: ', '');
                            uploadingImage = false;
                          });
                          return;
                        }
                      },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );

    name.dispose();
    number.dispose();
    price.dispose();
    ownerName.dispose();
    ownerPhone.dispose();
    description.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'مطلوب';
    return null;
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.session,
    required this.tabs,
    required this.selectedTab,
    required this.onSelect,
    required this.onLogout,
  });

  final PortalSession session;
  final List<(_PortalTab, String)> tabs;
  final _PortalTab selectedTab;
  final ValueChanged<_PortalTab> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _portalInk,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.isAdmin ? 'ELITE ADMIN' : 'ELITE MEDIATOR',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(session.displayName, style: const TextStyle(color: Color(0xFFE7D6B4))),
          const SizedBox(height: 18),
          for (final tab in tabs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                selected: selectedTab == tab.$1,
                selectedTileColor: const Color(0x1FFFFFFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: Text(tab.$2, style: const TextStyle(color: Colors.white)),
                onTap: () => onSelect(tab.$1),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('خروج'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.session, required this.summary});

  final PortalSession session;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1611), Color(0xFF6E5630), _portalGold],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.isAdmin ? 'لوحة الإدارة' : session.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                session.isAdmin
                    ? 'إجمالي المبيعات ${formatCurrency(summary.grossSales)}'
                    : 'رصيدك الحالي ${formatCurrency(summary.totalMediatorBalances)}',
                style: const TextStyle(color: Color(0xFFFFF0D7), fontSize: 22),
              ),
            ],
          ),
          _MetricPill(label: 'المنتجات المباعة', value: '${summary.soldProducts}'),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.session, required this.summary});

  final PortalSession session;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('المنتجات', '${summary.totalProducts}'),
      (session.isAdmin ? 'المتاحة' : 'مبيعاتي', '${session.isAdmin ? summary.availableProducts : summary.soldProducts}'),
      (
        session.isAdmin ? 'عدد الوسطاء' : 'الرصيد الحالي',
        session.isAdmin ? '${summary.totalMediators}' : formatCurrency(summary.totalMediatorBalances),
      ),
      (
        session.isAdmin ? 'عمولة العرض' : 'عمولة البيع 2.5%',
        formatCurrency(
          session.isAdmin
              ? summary.totalListingCommissions
              : summary.totalSellingCommissions,
        ),
      ),
      (
        session.isAdmin ? 'عمولة البيع 2.5%' : 'إجمالي العمولة',
        formatCurrency(summary.totalSellingCommissions),
      ),
      (
        session.isAdmin ? 'المنتجات المحجوزة' : 'إجمالي المبيعات',
        session.isAdmin ? '${summary.reservedProducts}' : formatCurrency(summary.grossSales),
      ),
      (
        session.isAdmin ? 'حصة الشركة' : 'المنتجات المتاحة للبيع',
        session.isAdmin ? formatCurrency(summary.companySales) : '${summary.availableProducts}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 700
            ? constraints.maxWidth
            : constraints.maxWidth < 1100
                ? (constraints.maxWidth - 14) / 2
                : (constraints.maxWidth - 28) / 3;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final item in items)
              SizedBox(width: width, child: _MetricCard(label: item.$1, value: item.$2)),
          ],
        );
      },
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({required this.summary, required this.mediators});

  final DashboardSummary summary;
  final List<Mediator> mediators;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MoneyBadge(label: 'عمولات العرض', value: formatCurrency(summary.totalListingCommissions)),
              _MoneyBadge(label: 'عمولات البيع 2.5%', value: formatCurrency(summary.totalSellingCommissions)),
              _MoneyBadge(label: 'الرصيد المستحق للوسطاء', value: formatCurrency(summary.totalMediatorBalances)),
              _MoneyBadge(label: 'حصة الشركة الفعلية', value: formatCurrency(summary.companySales)),
              _MoneyBadge(label: 'المنتجات المتاحة', value: '${summary.availableProducts}'),
              _MoneyBadge(label: 'المنتجات المحجوزة', value: '${summary.reservedProducts}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SimpleListSection(
          title: 'أرصدة الوسطاء',
          items: [
            for (final mediator in mediators)
              _ListRowData(
                title: mediator.name,
                subtitle: mediator.username,
                trailing: 'الرصيد ${formatCurrency(summary.mediatorBalances[mediator.code] ?? 0)}',
              ),
          ],
        ),
      ],
    );
  }
}

class _MediatorOverview extends StatelessWidget {
  const _MediatorOverview({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MoneyBadge(label: 'الرصيد الحالي', value: formatCurrency(summary.totalMediatorBalances)),
          _MoneyBadge(label: 'عمولة البيع 2.5%', value: formatCurrency(summary.totalSellingCommissions)),
          _MoneyBadge(label: 'عدد مبيعاتك', value: '${summary.soldProducts}'),
        ],
      ),
    );
  }
}

class _ProductsSection extends ConsumerStatefulWidget {
  const _ProductsSection({
    required this.session,
    required this.products,
    this.onAddProduct,
  });

  final PortalSession session;
  final List<Product> products;
  final VoidCallback? onAddProduct;

  @override
  ConsumerState<_ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends ConsumerState<_ProductsSection> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final products = widget.products.where((product) {
      final query = _searchQuery.trim().toUpperCase();
      if (query.isEmpty) return true;
      return product.productNumber.toUpperCase().contains(query);
    }).toList();

    return Column(
      children: [
        if (!session.isAdmin)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'بيع منتجات المنصة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ابحث برقم المنتج، افتح واتساب الإدارة والدعم الفني، وبعد إتمام العملية ثبّت البيع لتحصل على عمولتك 2.5%.',
                  style: TextStyle(color: Colors.black54, height: 1.7),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    labelText: 'ابحث برقم المنتج',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
        if (!session.isAdmin) const SizedBox(height: 16),
        _SimpleListSection(
          title: session.isAdmin ? 'المنتجات' : 'كتالوج البيع',
          action: session.isAdmin && widget.onAddProduct != null
              ? ElevatedButton.icon(
                  onPressed: widget.onAddProduct,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة'),
                )
              : null,
          emptyLabel: session.isAdmin
              ? 'لا توجد منتجات حالياً'
              : 'لا توجد نتائج مطابقة لرقم المنتج.',
          items: [
            for (final product in products)
              _ListRowData(
                title: product.displayName,
                subtitle: session.isAdmin
                    ? '${product.productNumber} • ${product.storefrontSegment} • ${formatCurrency(product.price)} • ${product.statusLabel}\nصاحب المنتج: ${product.ownerName.isEmpty ? 'غير محدد' : product.ownerName}${product.ownerPhone.isEmpty ? '' : ' • ${product.ownerPhone}'}'
                    : '${product.productNumber} • ${product.storefrontSegment} • ${formatCurrency(product.price)} • ${product.statusLabel}',
                trailing: session.isAdmin
                    ? (product.listedByMediatorName.isEmpty ? 'الإدارة' : product.listedByMediatorName)
                    : (product.hasActiveReservation
                        ? 'محجوز مؤقتاً'
                        : 'عمولتك ${formatCurrency(product.effectivePrice * kMediatorSellingCommissionRate)}'),
                onTap: session.isAdmin
                    ? null
                    : () => WhatsappService.openProductSalesChat(
                          productNumber: product.productNumber,
                          productName: product.displayName,
                          mediatorName: session.displayName,
                        ),
                actions: [
                  if (!session.isAdmin)
                    _ActionChip(
                      label: 'تواصل واتساب',
                      onTap: () => WhatsappService.openProductSalesChat(
                        productNumber: product.productNumber,
                        productName: product.displayName,
                        mediatorName: session.displayName,
                      ),
                    ),
                  if (product.isApproved &&
                      !product.isSold &&
                      (session.isAdmin ||
                          !product.hasActiveReservation ||
                          product.reservedByMediatorCode ==
                              session.mediator?.code))
                    _ActionChip(
                      label: 'تم البيع',
                      onTap: () => _markSold(context, ref, session, product),
                    ),
                  if (session.isAdmin && product.isSold)
                    _ActionChip(
                      label: 'حذف',
                      onTap: () => _deleteSold(context, ref, product),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _markSold(
    BuildContext context,
    WidgetRef ref,
    PortalSession session,
    Product product,
  ) async {
    final buyerPhone = TextEditingController();
    final buyerAddress = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('تم البيع'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(
                  controller: buyerPhone,
                  label: 'رقم المشتري',
                  keyboardType: TextInputType.phone,
                ),
                _DialogField(
                  controller: buyerAddress,
                  label: 'عنوان المشتري',
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final mediator = session.mediator;
    await ref.read(productsServiceProvider).markProductSold(
          product: product,
          buyerPhone: buyerPhone.text.trim(),
          buyerAddress: buyerAddress.text.trim(),
          soldByMediatorId: session.isAdmin ? '' : mediator?.id ?? '',
          soldByMediatorCode: session.isAdmin ? '' : mediator?.code ?? '',
          soldByMediatorName: session.isAdmin ? '' : mediator?.name ?? '',
        );
    await WhatsappService.openCompanyChat(
      'تم بيع المنتج رقم (${product.productNumber})\n'
      'اسم صاحب المنتج: ${product.ownerName.isEmpty ? 'غير محدد' : product.ownerName}\n'
      'رقم المشتري: (${buyerPhone.text.trim()})\n'
      'عنوان المشتري: (${buyerAddress.text.trim()})',
    );
    await ref.read(productsProvider.notifier).refresh();
    ref.invalidate(siteMetricsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم البيع وتحديث الحالة')),
    );
  }

  Future<void> _deleteSold(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    await ref.read(productsServiceProvider).deleteProduct(product.id);
    await ref.read(productsProvider.notifier).refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المنتج')),
    );
  }
}

class _PendingApprovalsSection extends ConsumerWidget {
  const _PendingApprovalsSection({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = products.where((product) => product.isPendingApproval).toList();

    return _SimpleListSection(
      title: 'اعتمادات المنتجات',
      emptyLabel: 'لا توجد طلبات معلقة',
      items: [
        for (final product in pending)
          _ListRowData(
            title: product.displayName,
            subtitle:
                '${product.productNumber} • ${product.storefrontSegment} • ${product.listedByMediatorName}',
            actions: [
              _ActionChip(label: 'قبول', onTap: () => _approve(ref, product.id, true)),
              _ActionChip(label: 'رفض', onTap: () => _approve(ref, product.id, false)),
            ],
          ),
      ],
    );
  }

  Future<void> _approve(WidgetRef ref, String productId, bool approved) async {
    await ref.read(productsServiceProvider).approveProduct(
          productId: productId,
          approved: approved,
        );
    await ref.read(productsProvider.notifier).refresh();
  }
}

class _MediatorsSection extends StatelessWidget {
  const _MediatorsSection({
    required this.summary,
    required this.mediators,
    required this.onCreateMediator,
  });

  final DashboardSummary summary;
  final List<Mediator> mediators;
  final VoidCallback onCreateMediator;

  @override
  Widget build(BuildContext context) {
    return _SimpleListSection(
      title: 'الوسطاء',
      action: ElevatedButton.icon(
        onPressed: onCreateMediator,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('إضافة'),
      ),
      items: [
        for (final mediator in mediators)
          _ListRowData(
            title: mediator.name,
            subtitle: mediator.username,
            trailing: 'الرصيد ${formatCurrency(summary.mediatorBalances[mediator.code] ?? 0)}',
          ),
      ],
    );
  }
}

class _SalesSection extends StatelessWidget {
  const _SalesSection({
    required this.session,
    required this.soldProducts,
    required this.catalogProducts,
    required this.summary,
  });

  final PortalSession session;
  final List<Product> soldProducts;
  final List<Product> catalogProducts;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MoneyBadge(label: 'الرصيد الحالي', value: formatCurrency(summary.totalMediatorBalances)),
              _MoneyBadge(label: 'عمولة البيع 2.5%', value: formatCurrency(summary.totalSellingCommissions)),
              _MoneyBadge(label: 'المبيعات', value: '${summary.soldProducts}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SimpleListSection(
          title: 'سجل المبيعات',
          emptyLabel: 'لا توجد مبيعات حتى الآن',
          items: [
            for (final product in soldProducts)
              _ListRowData(
                title: product.displayName,
                subtitle:
                    '${formatCurrency(product.price)} • بيعك',
                trailing: 'العمولة ${formatCurrency(product.sellingShare)}',
              ),
          ],
        ),
        if (!session.isAdmin) ...[
          const SizedBox(height: 16),
          _ProductsSection(
            session: session,
            products: catalogProducts,
          ),
        ],
      ],
    );
  }
}

class _SimpleListSection extends StatelessWidget {
  const _SimpleListSection({
    required this.title,
    required this.items,
    this.action,
    this.emptyLabel = 'لا توجد عناصر',
  });

  final String title;
  final List<_ListRowData> items;
  final Widget? action;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(emptyLabel)
          else
            ...items.map((item) => _ListRow(data: item)),
        ],
      ),
    );
  }
}

class _ListRowData {
  const _ListRowData({
    required this.title,
    this.subtitle = '',
    this.trailing = '',
    this.actions = const [],
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final List<Widget> actions;
  final VoidCallback? onTap;
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.data});

  final _ListRowData data;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowInfo(),
                  const SizedBox(height: 12),
                  _rowTrailing(compact: true),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _rowInfo()),
                  const SizedBox(width: 16),
                  _rowTrailing(compact: false),
                ],
              ),
      ),
    );
  }

  Widget _rowInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        if (data.subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(data.subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ],
    );
  }

  Widget _rowTrailing({required bool compact}) {
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (data.trailing.isNotEmpty)
          Text(
            data.trailing,
            style: const TextStyle(color: _portalGold, fontWeight: FontWeight.w900),
          ),
        if (data.actions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: data.actions),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8D1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.suffixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _portalSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _MoneyBadge extends StatelessWidget {
  const _MoneyBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8D1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF8A6425),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

extension on _PortalHomePageState {
  List<Widget> _buildBody({
    required PortalSession session,
    required List<Product> catalogProducts,
    required List<Product> salesProducts,
    required List<Mediator> mediators,
    required DashboardSummary summary,
  }) {
    switch (_tab) {
      case _PortalTab.overview:
        return [
          if (session.isAdmin)
            _AdminOverview(summary: summary, mediators: mediators)
          else
            _MediatorOverview(summary: summary),
        ];
      case _PortalTab.products:
        return [
          _ProductsSection(
            session: session,
            products: catalogProducts,
            onAddProduct: session.isAdmin ? () => _showProductDialog(session) : null,
          ),
        ];
      case _PortalTab.approvals:
        return [_PendingApprovalsSection(products: catalogProducts)];
      case _PortalTab.mediators:
        return [
          _MediatorsSection(
            summary: summary,
            mediators: mediators,
            onCreateMediator: _showMediatorDialog,
          ),
        ];
      case _PortalTab.sales:
        return [
          _SalesSection(
            session: session,
            soldProducts: salesProducts,
            catalogProducts: catalogProducts,
            summary: summary,
          ),
        ];
    }
  }
}

class PortalLoginPage extends ConsumerStatefulWidget {
  const PortalLoginPage({super.key});

  @override
  ConsumerState<PortalLoginPage> createState() => _PortalLoginPageState();
}

class _PortalLoginPageState extends ConsumerState<PortalLoginPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _portalBackground,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  return Flex(
                    direction: compact ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF17120E), Color(0xFF6E5630), _portalGold],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'بوابة Elite',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'بوابة تسجيل الدخول للوسطاء  ، ادخل باليوزر الخاص بك .',
                                style: TextStyle(color: Color(0xFFE9D9B8), height: 1.8,
                                  fontSize: 34,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: compact ? 0 : 24, height: compact ? 24 : 0),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: _portalSurface,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 28,
                                offset: Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تسجيل الدخول',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _controller,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                decoration: const InputDecoration(
                                  labelText: 'اليوزر ',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _loading ? null : _submit,
                                  icon: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.login_rounded),
                                  label: const Text('دخول'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    setState(() => _loading = true);
    final ok = await ref.read(portalSessionProvider.notifier).login(username);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المستخدم غير موجود')),
      );
    }
  }
}

enum _PortalTab { overview, products, approvals, mediators, sales }

class PortalHomePage extends ConsumerStatefulWidget {
  const PortalHomePage({super.key, required this.session});

  final PortalSession session;

  @override
  ConsumerState<PortalHomePage> createState() => _PortalHomePageState();
}

class _PortalHomePageState extends ConsumerState<PortalHomePage> {
  late _PortalTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.session.isAdmin ? _PortalTab.overview : _PortalTab.sales;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final summary = ref.watch(portalSummaryProvider);
    final catalogProducts = ref.watch(portalCatalogProductsProvider);
    final salesProducts = ref.watch(portalSalesProductsProvider);
    final mediators = ref.watch(mediatorsProvider).valueOrNull ?? const <Mediator>[];
    final compact = MediaQuery.sizeOf(context).width < 1040;

    final tabs = session.isAdmin
        ? const <(_PortalTab, String)>[
            (_PortalTab.overview, 'الرئيسية'),
            (_PortalTab.products, 'المنتجات'),
            (_PortalTab.approvals, 'الاعتمادات'),
            (_PortalTab.mediators, 'الوسطاء'),
          ]
        : const <(_PortalTab, String)>[
            (_PortalTab.sales, 'مبيعاتي'),
          ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _portalBackground,
        drawer: compact
            ? Drawer(
                child: _Sidebar(
                  session: session,
                  tabs: tabs,
                  selectedTab: _tab,
                  onSelect: (tab) {
                    setState(() => _tab = tab);
                    Navigator.of(context).pop();
                  },
                  onLogout: () => ref.read(portalSessionProvider.notifier).logout(),
                ),
              )
            : null,
        appBar: compact
            ? AppBar(
                title: Text(session.isAdmin ? 'ELITE ADMIN' : session.displayName),
              )
            : null,
        body: Row(
          children: [
            if (!compact)
              SizedBox(
                width: 280,
                child: _Sidebar(
                  session: session,
                  tabs: tabs,
                  selectedTab: _tab,
                  onSelect: (tab) => setState(() => _tab = tab),
                  onLogout: () => ref.read(portalSessionProvider.notifier).logout(),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _HeroCard(session: session, summary: summary),
                  const SizedBox(height: 18),
                  _SummaryCards(session: session, summary: summary),
                  const SizedBox(height: 18),
                  ..._buildBody(
                    session: session,
                    catalogProducts: catalogProducts,
                    salesProducts: salesProducts,
                    mediators: mediators,
                    summary: summary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
