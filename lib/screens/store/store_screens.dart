import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../DATE.dart';
import '../../controllers/mediators_controller.dart';
import '../../controllers/products_controller.dart';
import '../../controllers/site_metrics_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_loader.dart';
import '../../models/mediator.dart';
import '../../models/product.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/app_scaffold_bits.dart';
import '../../widgets/async_value_builder.dart';
const bool useFakeData = true;
const _storeName = 'Elite Store';
const _storeLogo = 'assets/branding/store_logo.png';
const _shellBackground = Color(0xFFF5EFE5);
const _surface = Colors.white;
const _ink = Color(0xFF16120D);
const _gold = Color(0xFFC39A47);
const _muted = Color(0xFF7E7366);
const _pageMaxWidth = 1320.0;

class StoreShell extends StatefulWidget {
  const StoreShell({
    super.key,
    required this.child,
    required this.routeLocation,
  });

  final Widget child;
  final String routeLocation;

  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  static const _loaderDuration = Duration(seconds: 2);

  Timer? _loaderTimer;
  bool _showLoader = true;

  @override
  void initState() {
    super.initState();
    _triggerLoader();
  }

  @override
  void didUpdateWidget(covariant StoreShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeLocation != widget.routeLocation) {
      _triggerLoader();
    }
  }

  @override
  void dispose() {
    _loaderTimer?.cancel();
    super.dispose();
  }

  void _triggerLoader() {
    _loaderTimer?.cancel();
    setState(() => _showLoader = true);
    _loaderTimer = Timer(_loaderDuration, () {
      if (mounted) {
        setState(() => _showLoader = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _shellBackground,
        appBar: AppBar(
          toolbarHeight: 78,
          titleSpacing: 18,
          title: const _StoreBrand(),
          actions: [
            Builder(
              builder: (context) => IconButton(
                tooltip: 'القائمة',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: const Icon(Icons.grid_view_rounded),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        endDrawer: const _StoreDrawer(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => WhatsappService.openSupportChat(),
          backgroundColor:  Colors.white,
          icon: const Icon(Icons.support_agent_rounded),
          label: const Text('دعم فني على واتساب'),
        ),
        body: Stack(
          children: [
            SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: KeyedSubtree(
                  key: ValueKey(widget.routeLocation),
                  child: widget.child,
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !_showLoader,
              child: AnimatedOpacity(
                opacity: _showLoader ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                child: Container(
                  color: const Color(0xD9F5EFE5),
                  alignment: Alignment.center,
                  child: const AppLoader(
                    label: 'Elite يحمل لك التجربة...',
                    showCard: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreHomeScreen extends ConsumerStatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  ConsumerState<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends ConsumerState<StoreHomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(storefrontSegmentFilterProvider.notifier).state = kAllProductsSegment;
  }

  @override
  Widget build(BuildContext context) {
    return const _CatalogPage(showHero: true);
  }
}

class SegmentStoreScreen extends ConsumerStatefulWidget {
  const SegmentStoreScreen({super.key, required this.segment});

  final String segment;

  @override
  ConsumerState<SegmentStoreScreen> createState() => _SegmentStoreScreenState();
}

class _SegmentStoreScreenState extends ConsumerState<SegmentStoreScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(storefrontSegmentFilterProvider.notifier).state = widget.segment;
  }

  @override
  void didUpdateWidget(covariant SegmentStoreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segment != widget.segment) {
      ref.read(storefrontSegmentFilterProvider.notifier).state = widget.segment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _CatalogPage(showHero: false);
  }
}

class _CatalogPage extends ConsumerWidget {
  const _CatalogPage({required this.showHero});

  final bool showHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(siteVisitsProvider);
    final sales = ref.watch(salesCountProvider);
    return AsyncValueBuilder<List<Product>>(
      value: useFakeData
          ? AsyncValue.data(fakeProducts.cast<Product>())
          : ref.watch(filteredStorefrontProductsProvider),
      loadingMessage: 'جاري تحميل المنتجات...',
      errorMessage: 'تعذر تحميل المنتجات من قاعدة البيانات.',
      data: (products) => _CatalogBody(
        products: products,
        showHero: showHero,
        visits: visits,
        sales: sales,
      ),
    );
  }
}

class _CatalogBody extends ConsumerStatefulWidget {
  const _CatalogBody({
    required this.products,
    required this.showHero,
    required this.visits,
    required this.sales,
  });

  final List<Product> products;
  final bool showHero;
  final int visits;
  final int sales;

  @override
  ConsumerState<_CatalogBody> createState() => _CatalogBodyState();
}

class _CatalogBodyState extends ConsumerState<_CatalogBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.products.where((product) {
      final query = _searchQuery.trim().toLowerCase();
      final nameMatches =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.productNumber.toLowerCase().contains(query);
      final price = product.price;
      final minMatches = _minPrice == null || (price != null && price >= _minPrice!);
      final maxMatches = _maxPrice == null || (price != null && price <= _maxPrice!);
      return nameMatches && minMatches && maxMatches;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(productsProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
              child: Column(
                children: [
                  if (widget.showHero) ...[
                    _HomeHero(visits: widget.visits, sales: widget.sales),
                    const SizedBox(height: 20),
                  ],
                  const _FreeDeliveryBanner(),
                  const SizedBox(height: 18),
                  _SearchAndPriceFilterCard(
                    controller: _searchController,
                    onSearchChanged: (value) => setState(() => _searchQuery = value),
                    onMinPriceChanged: (value) => setState(() => _minPrice = value),
                    onMaxPriceChanged: (value) => setState(() => _maxPrice = value),
                  ),
                  const SizedBox(height: 18),
                  if (filteredProducts.isEmpty)
                    const SectionCard(
                      child: Text('لا توجد منتجات مطابقة للبحث أو لمدى السعر المحدد.'),
                    )
                  else
                    _ResponsiveProductGrid(products: filteredProducts),
                  const SizedBox(height: 24),
                  const _FooterMenu(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return AsyncValueBuilder<List<Product>>(
      value: ref.watch(storefrontProductsProvider),
      loadingMessage: 'جاري تحميل تفاصيل المنتج...',
      errorMessage: 'تعذر تحميل تفاصيل المنتج.',
      data: (products) {
        final product = products.where((item) => item.id == widget.productId).firstOrNull;
        if (product == null) {
          return const EmptyState(
            title: 'المنتج غير موجود',
            message: 'تعذر العثور على هذا المنتج.',
          );
        }

        final similarProducts = products
            .where((item) => item.id != product.id && item.category == product.category)
            .take(3)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 980;
                        return Wrap(
                          spacing: 18,
                          runSpacing: 18,
                          children: [
                            SizedBox(
                              width: wide ? (constraints.maxWidth - 18) * 0.54 : constraints.maxWidth,
                              child: _DetailsVisualCard(product: product),
                            ),
                            SizedBox(
                              width: wide ? (constraints.maxWidth - 18) * 0.46 : constraints.maxWidth,
                              child: _DetailsPurchaseCard(
                                product: product,
                                submitting: _submitting,
                                onBuy: () => _confirmDirectPurchase(product),
                                onInquiry: () => _sendInquiry(product),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (similarProducts.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'منتجات مشابهة',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _ink),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ResponsiveProductGrid(products: similarProducts),
                    ],
                    const SizedBox(height: 24),
                    const _FooterMenu(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDirectPurchase(Product product) async {
    final approved = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('شراء المنتج'),
            content: Text(
              product.isAvailable
                  ? 'سيتم حجز المنتج مباشرة ثم فتح واتساب الشركة برسالة جاهزة.'
                  : 'هذا المنتج غير متاح حالياً للحجز.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: product.isAvailable
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: const Text('موافق'),
              ),
            ],
          ),
        ) ??
        false;

    if (!approved) return;

    setState(() => _submitting = true);

    try {
      await ref.read(productsServiceProvider).reserveProduct(
            product: product,
            reservationSource: 'store_purchase',
          );
      await ref.read(productsProvider.notifier).refresh();
      final launched = await WhatsappService.openCompanyChat(
        'أريد شراء ${product.displayName}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            launched
                ? 'تم حجز المنتج وفتح واتساب الشركة.'
                : 'تم حجز المنتج، لكن تعذر فتح واتساب تلقائياً.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _sendInquiry(Product product) async {
    await ref.read(productsServiceProvider).noteInquiry(product);
    final launched = await WhatsappService.openCompanyChat(
      'أرغب بالاستفسار أكثر عن ${product.displayName}',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          launched
              ? 'تم فتح واتساب للاستفسار عن المنتج.'
              : 'تعذر فتح واتساب حالياً.',
        ),
      ),
    );
  }
}
class PoliciesPage extends StatelessWidget {
  const PoliciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoPage(
      title: 'سياسات شركتنا',
      body:
          'في Elite نؤمن بأن الثقة تبدأ من الوضوح. لذلك نعرض تفاصيل المنتجات بدقة، ونوفر حجزاً مؤقتاً لمدة 15 دقيقة يمنح العميل فرصة آمنة لاتخاذ القرار بدون ضغط. جميع الطلبات تراجع بعناية من فريقنا لضمان سرعة المتابعة، ودقة التنسيق، وتجربة شراء راقية تليق بعملائنا.',
    );
  }
}

class AboutCompanyPage extends StatelessWidget {
  const AboutCompanyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoPage(
      title: 'حول الشركة',
      body:
          'Elite Store منصة عرض رقمية متخصصة بتقديم المنتجات المختارة بعناية ضمن تجربة عربية أنيقة وسهلة. نركز على جودة العرض، وسلاسة التصفح، ووضوح المعلومات، حتى يصل العميل إلى ما يناسبه بسرعة ويثبت حجزه بثقة. هدفنا أن نجمع بين الفخامة والبساطة في تجربة واحدة تبدو احترافية من أول زيارة وحتى آخر خطوة.',
    );
  }
}

class TeamPage extends ConsumerWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const managers = [
      (
        'محمد الناطور',
        'مسؤول تطوير وإدارة التطبيق',
        '0795422974',
        'assets/images/mohammad.jpeg',
      ),
      (
        'عماد ملكاوي',
        'مسؤول خدمة العملاء',
        '0780045351',
        'assets/images/emad.png',
      ),
      (
        'ابراهيم دغيمات',
        'مسؤول التسويق والسوشيل ميديا',
        '0775642660',
        'assets/images/ibrahim.jpg',
      ),
    ];

    final mediatorsAsync = ref.watch(mediatorsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B1611), Color(0xFFC49A47)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فريقنا',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'الوجوه التي تدير تجربة Elite وتتابع جودة العرض والحجز وخدمة العملاء.',
                        style: TextStyle(color: Color(0xFFEADFC7), height: 1.7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 292,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: managers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final manager = managers[index];
                      return SizedBox(
                        width: 260,
                        child: _ManagerCard(
                          name: manager.$1,
                          role: manager.$2,
                          phone: manager.$3,
                          imagePath: manager.$4,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionLineTitle(title: 'أعضاء فريقنا'),
                const SizedBox(height: 14),
                mediatorsAsync.when(
                  data: (mediators) {
                    if (mediators.isEmpty) {
                      return const SectionCard(
                        child: Text('لا يوجد أعضاء إضافيون مخزنين حالياً في Firebase.'),
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 980
                            ? 3
                            : constraints.maxWidth >= 640
                                ? 2
                                : 1;
                        final itemWidth =
                            (constraints.maxWidth - ((columns - 1) * 12)) / columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final mediator in mediators)
                              SizedBox(
                                width: itemWidth,
                                child: _MediatorCard(mediator: mediator),
                              ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: AppLoader(label: 'جاري تحميل أعضاء الفريق...', size: 72),
                  ),
                  error: (error, _) => SectionCard(
                    child: Text('تعذر تحميل أعضاء الفريق: $error'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 28,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Text(body, style: const TextStyle(height: 1.9, color: _muted)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreBrand extends StatelessWidget {
  const _StoreBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x17000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(_storeLogo, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _storeName,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _ink),
            ),
            Text(
              'خيلك إتيكيت ... خليك ELITE',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _StoreDrawer extends StatelessWidget {
  const _StoreDrawer();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('الرئيسية', '/', Icons.home_rounded),
      ('سياسات شركتنا', '/policies', Icons.shield_outlined),
      ('حول الشركة', '/about', Icons.apartment_rounded),
      ('فريقنا', '/team', Icons.groups_rounded),
      ('تسجيل الدخول ', '/portal', Icons.login),
    ];
    return Drawer(
      backgroundColor: const Color(0xFFFFFBF5),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 32, 18, 18),
        children: [
          const _StoreBrand(),
          const SizedBox(height: 20),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: const Color(0xFFE8F4EC),
            leading: const Icon(Icons.support_agent_rounded, color: Color(0xFF1D6F42)),
            title: const Text('دعم فني على واتساب'),
            onTap: () async {
              Navigator.of(context).pop();
              await WhatsappService.openSupportChat();
            },
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                tileColor: const Color(0xFFF4ECDF),
                leading: Icon(item.$3, color: _gold),
                title: Text(item.$1),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(item.$2);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.visits, required this.sales});

  final int visits;
  final int sales;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.all(mobile ? 20 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1611), Color(0xFF6E5630), Color(0xFFC49A47)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اكتشف منتجاتنا بسهولة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
                        'تصفح التشكيلة، ابحث باسم المنتج أو رقم المنتج، فلتر بالسعر، ثم ثبّت حجزك بخطوة بسيطة وواضحة.',
            style: TextStyle(color: Color(0xFFF4E6CC), height: 1.8),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricCard(label: 'زوار الموقع', value: '$visits'),
              _MetricCard(label: 'المبيعات', value: '$sales'),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SearchAndPriceFilterCard extends StatefulWidget {
  const _SearchAndPriceFilterCard({
    required this.controller,
    required this.onSearchChanged,
    required this.onMinPriceChanged,
    required this.onMaxPriceChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<double?> onMinPriceChanged;
  final ValueChanged<double?> onMaxPriceChanged;

  @override
  State<_SearchAndPriceFilterCard> createState() =>
      _SearchAndPriceFilterCardState();
}

class _SearchAndPriceFilterCardState extends State<_SearchAndPriceFilterCard> {
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wide = screenWidth >= 720;
    final fieldWidth = wide ? 190.0 : screenWidth - 68;
    final searchWidth = wide ? 320.0 : screenWidth - 68;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: searchWidth,
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onSearchChanged,
              decoration: const InputDecoration(
                    labelText: 'ابحث باسم المنتج أو رقم المنتج',
                hintText: 'مثال: ساعة - عطر - حقيبة',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            width: fieldWidth,
            child: TextField(
              controller: _minController,
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  widget.onMinPriceChanged(double.tryParse(value.trim())),
              decoration: const InputDecoration(
                labelText: 'من سعر',
                hintText: '100',
                prefixIcon: Icon(Icons.tune_rounded),
              ),
            ),
          ),
          SizedBox(
            width: fieldWidth,
            child: TextField(
              controller: _maxController,
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  widget.onMaxPriceChanged(double.tryParse(value.trim())),
              decoration: const InputDecoration(
                labelText: 'إلى سعر',
                hintText: '300',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              widget.controller.clear();
              _minController.clear();
              _maxController.clear();
              widget.onSearchChanged('');
              widget.onMinPriceChanged(null);
              widget.onMaxPriceChanged(null);
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('إعادة التصفية'),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveProductGrid extends StatelessWidget {
  const _ResponsiveProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 4
            : constraints.maxWidth >= 860
                ? 3
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 1.02 : 0.8,
          ),
          itemBuilder: (context, index) => _ProductCard(product: products[index]),
        );
      },
    );
  }
}

class _FreeDeliveryBanner extends StatelessWidget {
  const _FreeDeliveryBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF17120E), Color(0xFFC39A47)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'توصيل مجاني لفترة محدودة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'استفد الآن من التوصيل المجاني داخل إربد والزرقاء عند تأكيد الطلب عبر واتساب.',
                style: TextStyle(color: Color(0xFFF6E8CA), height: 1.7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => context.go('/product/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _ProductImage(product: product)),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.56),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        product.storefrontSegment,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _AvailabilityBadge(product: product),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.productNumber,
              style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, height: 1.6),
            ),
            const SizedBox(height: 6),
            Text(
              formatCurrency(product.price),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _gold),
            ),
            if (product.hasActiveReservation) ...[
              const SizedBox(height: 10),
              _ReservationCountdown(product: product, compact: true),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/product/${product.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: product.hasActiveReservation ? const Color(0xFFB39A72) : _ink,
                ),
                child: Text(product.hasActiveReservation ? 'محجوز حالياً' : 'احجز الآن'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: product.imageUrl.isNotEmpty
          ? Image.network(
              product.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5ECE0), Color(0xFFE0C89D)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Image.asset(_storeLogo, fit: BoxFit.contain),
      ),
    );
  }
}

class _DetailsVisualCard extends StatelessWidget {
  const _DetailsVisualCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 420, child: _ProductImage(product: product)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SoftChip(label: product.category),
              if (product.brand.isNotEmpty) _SoftChip(label: product.brand),
              _SoftChip(label: 'رقم المنتج ${product.productNumber}'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            product.name,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _ink),
          ),
          const SizedBox(height: 10),
          Text(
            product.description,
            style: const TextStyle(height: 1.9, color: _muted),
          ),
        ],
      ),
    );
  }
}

class _DetailsPurchaseCard extends StatelessWidget {
  const _DetailsPurchaseCard({
    required this.product,
    required this.submitting,
    required this.onBuy,
    required this.onInquiry,
  });

  final Product product;
  final bool submitting;
  final VoidCallback onBuy;
  final VoidCallback onInquiry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الشراء والاستفسار',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _ink),
          ),
          const SizedBox(height: 10),
          Text(
            formatCurrency(product.price),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _gold),
          ),
          const SizedBox(height: 14),
          _AvailabilityPanel(product: product),
          const SizedBox(height: 18),
          Text(
            'القسم: ${product.storefrontSegment.isEmpty ? AppConstants.productSections.first : product.storefrontSegment}',
            style: const TextStyle(height: 1.8, color: _muted),
          ),
          const SizedBox(height: 8),
          const Text(
            'زر الشراء يحجز المنتج ثم يفتح واتساب الشركة. زر الاستفسار يفتح واتساب فقط بدون أي حجز.',
            style: TextStyle(height: 1.8, color: _muted),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'توصيل مجاني داخل إربد والزرقاء مع هذا العرض الخاص.',
              style: TextStyle(
                color: Color(0xFF8A5A00),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: product.isAvailable && !submitting ? onBuy : null,
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_bag_outlined),
              label: Text(product.isAvailable ? 'شراء المنتج' : product.statusLabel),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onInquiry,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('الاستفسار أكثر عن المنتج'),
            ),
          ),
        ],
      ),
    );
  }
}
class _AvailabilityPanel extends StatelessWidget {
  const _AvailabilityPanel({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final background = product.hasActiveReservation
        ? const Color(0xFFFFF2DE)
        : product.isSold
            ? const Color(0xFFF7E7E5)
            : const Color(0xFFEAF6EE);
    final textColor = product.hasActiveReservation
        ? const Color(0xFF8A5A00)
        : product.isSold
            ? const Color(0xFFA33924)
            : const Color(0xFF23663D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.isReserved
                ? 'محجوز الآن'
                : product.isSold
                    ? 'تم بيع المنتج'
                    : 'متاح للشراء',
            style: TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 18),
          ),
          const SizedBox(height: 6),
          if (product.hasActiveReservation)
            _ReservationCountdown(product: product)
          else
            Text(
              product.isSold
                  ? 'هذا المنتج غير متاح حالياً.'
                  : 'هذا المنتج جاهز للحجز الآن.',
              style: TextStyle(color: textColor, height: 1.7),
            ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final color = product.hasActiveReservation
        ? const Color(0xFF8A5A00)
        : product.isSold
            ? const Color(0xFFA33924)
            : const Color(0xFF23663D);
    final background = product.hasActiveReservation
        ? const Color(0xFFFFF2DE)
        : product.isSold
            ? const Color(0xFFF7E7E5)
            : const Color(0xFFEAF6EE);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        product.hasActiveReservation
            ? 'محجوز'
            : product.isSold
                ? 'مباع'
                : 'متاح',
        style: TextStyle(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _ReservationCountdown extends StatefulWidget {
  const _ReservationCountdown({
    required this.product,
    this.compact = false,
  });

  final Product product;
  final bool compact;

  @override
  State<_ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<_ReservationCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.product.remainingReservation;
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant _ReservationCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    _remaining = widget.product.remainingReservation;
    _startTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _timer?.cancel();
    if (_remaining == Duration.zero) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = widget.product.remainingReservation;
      if (remaining == Duration.zero) {
        _timer?.cancel();
      }
      setState(() => _remaining = remaining);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Text(
        'انتهى الحجز وأصبح المنتج متاحاً مجدداً.',
        style: TextStyle(
          color: widget.compact ? const Color(0xFF23663D) : const Color(0xFF8A5A00),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);
    final value =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Row(
      children: [
        const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF8A5A00)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.compact ? value : 'الوقت المتبقي للحجز: $value',
            style: const TextStyle(
              color: Color(0xFF8A5A00),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECDF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _ManagerCard extends StatelessWidget {
  const _ManagerCard({
    required this.name,
    required this.role,
    required this.phone,
    required this.imagePath,
  });

  final String name;
  final String role;
  final String phone;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 42,
            backgroundImage: AssetImage(imagePath),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.7),
          ),
          const SizedBox(height: 10),
          Text(
            phone,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _gold),
          ),
        ],
      ),
    );
  }
}

class _SectionLineTitle extends StatelessWidget {
  const _SectionLineTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(
            thickness: 1.2,
            color: Color(0xFFD8C9AE),
          ),
        ),
      ],
    );
  }
}

class _MediatorCard extends StatelessWidget {
  const _MediatorCard({required this.mediator});

  final Mediator mediator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: ClipOval(
              child: Image.asset(_storeLogo, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediator.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  mediator.subtitle,
                  style: const TextStyle(color: _muted, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _FooterMenu extends StatelessWidget {
  const _FooterMenu();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('الرئيسية', '/'),
      ('سياسات شركتنا', '/policies'),
      ('حول الشركة', '/about'),
      ('فريقنا', '/team'),
      ('البوابة', '/portal'),
    ];
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF17120E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            _storeName,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'تجربة عرض أنيقة، حجز سريع، وانتقال ناعم بين كل أقسام المتجر.',
            style: TextStyle(color: Color(0xFFCCBC9F), height: 1.7),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                TextButton(
                  onPressed: () => context.go(item.$2),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(item.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
