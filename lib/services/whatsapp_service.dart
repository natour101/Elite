import 'package:url_launcher/url_launcher.dart';

import '../models/antique_product.dart';
import '../models/cart_item.dart';

class WhatsappService {
  const WhatsappService._();

  static const String _salesPhone = '00962795422974';

  static Future<bool> openSingleProductOrder({
    required AntiqueProduct product,
    required String customerName,
  }) {
    final message = StringBuffer()
      ..writeln('طلب شراء قطعة أنتيكا')
      ..writeln('اسم العميل: $customerName')
      ..writeln('رقم المنتج: ${product.productNumber}')
      ..writeln('اسم القطعة: ${product.name}')
      ..writeln('السعر: ${product.price.toStringAsFixed(0)} د.أ')
      ..writeln('التصنيف: ${product.category}')
      ..writeln('النوع / الحقبة: ${product.era}');

    return _openChat(message.toString());
  }

  static Future<bool> openCartOrder({
    required String customerName,
    required List<CartItem> items,
    required double total,
  }) {
    final message = StringBuffer()
      ..writeln('طلب شراء عبر المتجر')
      ..writeln('اسم العميل: $customerName')
      ..writeln('عدد القطع: ${items.length}')
      ..writeln('الإجمالي التقريبي: ${total.toStringAsFixed(0)} د.أ')
      ..writeln('')
      ..writeln('تفاصيل القطع:');

    for (final item in items) {
      message
        ..writeln('- ${item.product.name}')
        ..writeln('  رقم المنتج: ${item.product.productNumber}')
        ..writeln('  السعر: ${item.product.price.toStringAsFixed(0)} د.أ');
    }

    return _openChat(message.toString());
  }

  static Future<bool> _openChat(String message) async {
    final cleanPhone = _salesPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final encoded = Uri.encodeComponent(message);
    final primaryUri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
    final fallbackUri =
        Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded');

    final launchedPrimary =
        await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
    if (launchedPrimary) {
      return true;
    }

    return launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
  }
}
