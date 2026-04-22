import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/store_controller.dart';
import '../models/antique_product.dart';
import '../models/cart_item.dart';
import '../services/whatsapp_service.dart';
import '../utils/app_spacing.dart';

class WhatsAppOrderSheet extends ConsumerStatefulWidget {
  const WhatsAppOrderSheet.single({
    super.key,
    required this.product,
  })  : items = null,
        total = null;

  const WhatsAppOrderSheet.cart({
    super.key,
    required this.items,
    required this.total,
  }) : product = null;

  final AntiqueProduct? product;
  final List<CartItem>? items;
  final double? total;

  static Future<void> showSingle(
    BuildContext context, {
    required AntiqueProduct product,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WhatsAppOrderSheet.single(product: product),
    );
  }

  static Future<void> showCart(
    BuildContext context, {
    required List<CartItem> items,
    required double total,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WhatsAppOrderSheet.cart(items: items, total: total),
    );
  }

  @override
  ConsumerState<WhatsAppOrderSheet> createState() => _WhatsAppOrderSheetState();
}

class _WhatsAppOrderSheetState extends ConsumerState<WhatsAppOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F3EA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2BEA2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.product != null ? 'إرسال الطلب على واتساب' : 'إرسال طلب السلة على واتساب',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'اكتب اسمك فقط، وسيفتح واتساب مباشرة مع كل بيانات القطعة المطلوبة.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسمك',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.chat_rounded),
                    label: Text(_submitting ? 'جارٍ الفتح...' : 'فتح واتساب'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);

    final customerName = _nameController.text.trim();
    final launched = widget.product != null
        ? await WhatsappService.openSingleProductOrder(
            product: widget.product!,
            customerName: customerName,
          )
        : await WhatsappService.openCartOrder(
            customerName: customerName,
            items: widget.items!,
            total: widget.total!,
          );

    if (!mounted) {
      return;
    }

    setState(() => _submitting = false);

    if (launched) {
      ref.read(appStatsProvider.notifier).recordOrderRequest();
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر فتح واتساب حالياً.')),
    );
  }
}
