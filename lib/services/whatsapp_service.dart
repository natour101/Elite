import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';

class WhatsappService {
  const WhatsappService._();

  static Future<bool> openCompanyChat(String message) {
    return _openChat(
      phone: AppConstants.companyWhatsappPhone,
      message: message,
    );
  }

  static Future<bool> openSupportChat([String? message]) {
    return _openChat(
      phone: AppConstants.supportWhatsappPhone,
      message: message ?? 'مرحباً، أحتاج إلى دعم فني.',
    );
  }

  static Future<bool> openProductSalesChat({
    required String productNumber,
    required String productName,
    required String mediatorName,
  }) {
    return _openChat(
      phone: AppConstants.companyWhatsappPhone,
      message:
          'مرحباً، أنا الوسيط $mediatorName وأرغب بمتابعة بيع المنتج رقم $productNumber ($productName). الرجاء تنسيق الإدارة والدعم الفني.',
    );
  }

  static Future<bool> _openChat({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final encoded = Uri.encodeComponent(message);
    final primaryUri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
    final fallbackUri =
        Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded');

    final primaryLaunched =
        await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
    if (primaryLaunched) return true;
    return launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
  }
}
