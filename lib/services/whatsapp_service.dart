import 'package:flutter/foundation.dart';
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
    final cleanPhone = _normalizePhone(_salesPhone);
    final encoded = Uri.encodeComponent(message);

    final uris = <Uri>[
      Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded'),
      Uri.parse('https://wa.me/$cleanPhone?text=$encoded'),
      Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded'),
    ];

    if (kIsWeb) {
      return launchUrl(uris[1], mode: LaunchMode.platformDefault);
    }

    for (final uri in uris) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        return true;
      }
    }

    return false;
  }

  static String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) {
      return digits.substring(2);
    }
    return digits;
  }
}
