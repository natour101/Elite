import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  const AdsService._();

  static Future<void> initialize() async {
    final supportsMobileAds = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (!supportsMobileAds) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // Ignore ad initialization failures so the rest of the app keeps working.
    }
  }
}
