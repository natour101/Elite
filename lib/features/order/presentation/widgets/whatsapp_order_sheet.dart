import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../../catalog/domain/product.dart';
import '../../../../core/constants/app_copy.dart';

class WhatsAppOrderSheet extends StatefulWidget {
  const WhatsAppOrderSheet({super.key, required this.product});

  final Product product;

  @override
  State<WhatsAppOrderSheet> createState() => _WhatsAppOrderSheetState();
}

class _WhatsAppOrderSheetState extends State<WhatsAppOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final currency = NumberFormat.currency(
      locale: 'ar',
      symbol: 'JOD ',
      decimalDigits: 0,
    ).format(widget.product.price);

    final message = '''
مرحبًا، أرغب بطلب المنتج التالي:
اسم المنتج: ${widget.product.name}
رقم المنتج: ${widget.product.productNumber}
السعر: $currency
اسم التاجر البائع: ${widget.product.sellerName}
هاتف التاجر البائع: ${widget.product.sellerPhone}
اسم المشتري: ${_buyerNameController.text.trim()}
هاتف المشتري: ${_buyerPhoneController.text.trim()}
''';

    final cleanPhone = _normalizeWhatsappNumber(AppCopy.whatsappPhone);
    final encoded = Uri.encodeComponent(message);
    final primaryUri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
    final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded');

    final launched = await launchUrl(primaryUri, mode: LaunchMode.externalApplication) ||
        await launchUrl(webUri, mode: LaunchMode.externalApplication);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (launched) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب حاليًا.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إتمام الطلب',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم إرسال الطلب إلى ${AppCopy.whatsappPhone} عبر واتساب.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _buyerNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'اسم المشتري'),
              validator: (value) =>
                  value == null || value.trim().length < 2 ? 'أدخل الاسم' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _buyerPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'رقم هاتف المشتري'),
              validator: (value) =>
                  value == null || value.trim().length < 7 ? 'أدخل رقمًا صحيحًا' : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'جاري التحويل...' : 'طلب عبر واتساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeWhatsappNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('962')) return digits;
    if (digits.startsWith('0')) return '962${digits.substring(1)}';
    return digits;
  }
}
