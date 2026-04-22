import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  const AdsService._();

  static Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    await MobileAds.instance.initialize();
  }
}
