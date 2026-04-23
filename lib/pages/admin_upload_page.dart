import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/antique_shell.dart';
import '../controllers/store_controller.dart';
import '../utils/app_spacing.dart';

class AdminUploadPage extends ConsumerStatefulWidget {
  const AdminUploadPage({super.key});

  @override
  ConsumerState<AdminUploadPage> createState() => _AdminUploadPageState();
}

class _AdminUploadPageState extends ConsumerState<AdminUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _eraController = TextEditingController();
  final _materialController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _storyController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _conditionController = TextEditingController();
  bool _isFeatured = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _eraController.dispose();
    _materialController.dispose();
    _imageUrlController.dispose();
    _storyController.dispose();
    _dimensionsController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      child: ListView(
        children: [
          Text('إدارة المنتجات', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'أضف المنتج إلى قاعدة البيانات ليظهر مباشرة في الموقع والتطبيق.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_nameController, 'اسم المنتج'),
                  _field(_descriptionController, 'وصف مختصر', maxLines: 3),
                  _field(
                    _priceController,
                    'السعر',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  _field(_categoryController, 'التصنيف'),
                  _field(_eraController, 'الحقبة / النوع', required: false),
                  _field(_materialController, 'الخامة', required: false),
                  _field(
                    _imageUrlController,
                    'رابط الصورة',
                    required: false,
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return null;
                      }
                      final uri = Uri.tryParse(trimmed);
                      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                        return 'أدخل رابط صورة صحيحًا';
                      }
                      return null;
                    },
                  ),
                  _field(_storyController, 'قصة القطعة', maxLines: 3, required: false),
                  _field(_dimensionsController, 'الأبعاد', required: false),
                  _field(_conditionController, 'الحالة', required: false),
                  SwitchListTile(
                    value: _isFeatured,
                    onChanged: (value) => setState(() => _isFeatured = value),
                    title: const Text('إظهار ضمن المنتجات المميزة'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting ? 'جارٍ الحفظ...' : 'حفظ المنتج'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: validator ??
            (value) {
              if (!required) {
                return null;
              }
              return value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;
            },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السعر غير صالح')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(antiqueCatalogServiceProvider).saveProduct(
            name: _nameController.text,
            description: _descriptionController.text,
            price: price,
            category: _categoryController.text,
            era: _eraController.text,
            material: _materialController.text,
            imageUrl: _imageUrlController.text,
            story: _storyController.text,
            dimensions: _dimensionsController.text,
            condition: _conditionController.text,
            isFeatured: _isFeatured,
          );

      if (!mounted) return;
      _formKey.currentState!.reset();
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _categoryController.clear();
      _eraController.clear();
      _materialController.clear();
      _imageUrlController.clear();
      _storyController.clear();
      _dimensionsController.clear();
      _conditionController.clear();
      setState(() => _isFeatured = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المنتج وسيظهر مباشرة بعد المزامنة.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'تعذر حفظ المنتج حاليًا. حاول مرة أخرى.' : message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
