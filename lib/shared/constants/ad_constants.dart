import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// lib/shared/constants/ad_constants.dart - AdMob constants

/// Production Android banner unit — belongs to app `ca-app-pub-2093403233028868~6019383556`
/// (see AndroidManifest.xml). Ad unit IDs are per-platform; this one is Android-only.
const String androidBannerAdUnitId = 'ca-app-pub-2093403233028868/1705631815';

/// STILL A GOOGLE TEST ID — an iOS banner unit must be created in AdMob before App Store
/// submission (Phase 3). Reusing the Android unit above would serve no ads and breaks
/// AdMob policy, so do not copy it here.
const String iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

/// Production Android interstitial unit — belongs to app `ca-app-pub-2093403233028868~6019383556`.
const String androidInterstitialAdUnitId = 'ca-app-pub-2093403233028868/6050707837';

/// Google AdMob official standard test interstitial ad units for fallback / testing.
const String testAndroidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
const String testIosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

String get interstitialAdUnitId {
  if (Platform.isAndroid) {
    final envId = dotenv.env['ANDROID_INTERSTITIAL_AD_UNIT_ID'];
    if (envId != null && envId.trim().isNotEmpty) {
      return envId.trim();
    }
    return androidInterstitialAdUnitId;
  } else if (Platform.isIOS) {
    final envId = dotenv.env['IOS_INTERSTITIAL_AD_UNIT_ID'];
    if (envId != null && envId.trim().isNotEmpty) {
      return envId.trim();
    }
    return testIosInterstitialAdUnitId;
  }
  return androidInterstitialAdUnitId;
}
