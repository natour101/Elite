import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/store_controller.dart';
import '../utils/app_spacing.dart';
import 'antique_shell.dart';

class FiltersPanel extends ConsumerStatefulWidget {
  const FiltersPanel({super.key});

  @override
  ConsumerState<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends ConsumerState<FiltersPanel> {
  late final TextEditingController _searchController;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(productFiltersProvider);
    _searchController = TextEditingController(text: filters.query);
    _minPriceController = TextEditingController(
      text: filters.minPrice == null ? '' : filters.minPrice!.toStringAsFixed(0),
    );
    _maxPriceController = TextEditingController(
      text: filters.maxPrice == null ? '' : filters.maxPrice!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(productFiltersProvider);
    final categories = ref.watch(categoriesProvider);
    final eras = ref.watch(erasProvider);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('فلترة المجموعة', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final children = [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: ref.read(productFiltersProvider.notifier).setQuery,
                    decoration: const InputDecoration(
                      labelText: 'ابحث باسم القطعة أو وصفها',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md, height: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: filters.category,
                    decoration: const InputDecoration(labelText: 'التصنيف'),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('كل التصنيفات')),
                      ...categories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: ref.read(productFiltersProvider.notifier).setCategory,
                  ),
                ),
                const SizedBox(width: AppSpacing.md, height: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: filters.era,
                    decoration: const InputDecoration(labelText: 'النوع / الحقبة'),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('كل الأنواع')),
                      ...eras.map(
                        (era) => DropdownMenuItem<String>(
                          value: era,
                          child: Text(era),
                        ),
                      ),
                    ],
                    onChanged: ref.read(productFiltersProvider.notifier).setEra,
                  ),
                ),
              ];

              return Column(
                children: [
                  if (wide)
                    Row(children: children)
                  else
                    ...children.expand((widget) => [widget]),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'أقل سعر'),
                          onChanged: (value) {
                            ref.read(productFiltersProvider.notifier).setMinPrice(
                                  double.tryParse(value.trim()),
                                );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'أعلى سعر'),
                          onChanged: (value) {
                            ref.read(productFiltersProvider.notifier).setMaxPrice(
                                  double.tryParse(value.trim()),
                                );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(productFiltersProvider.notifier).reset();
                          _searchController.clear();
                          _minPriceController.clear();
                          _maxPriceController.clear();
                        },
                        child: const Text('إعادة الضبط'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
