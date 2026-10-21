import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../shared/constants/ad_constants.dart';
import 'store_service.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _isLoadingInterstitial = false;
  static DateTime? _lastInterstitialShownTime;

  static Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    try {
      // 1. Set general audience request configuration to maximize ad fill & unblock restricted bidding
      final requestConfiguration = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        maxAdContentRating: MaxAdContentRating.ma,
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      // 2. Initialize MobileAds SDK
      final initStatus = await MobileAds.instance.initialize();
      for (final entry in initStatus.adapterStatuses.entries) {
        debugPrint('[AdMob] Adapter ${entry.key}: state=${entry.value.state}, description=${entry.value.description}');
      }

      // 3. Request UMP (User Messaging Platform) Consent (Required for European & privacy regions)
      _requestConsent();

      // 4. Preload initial interstitial ad so it's instantly ready when conversion finishes
      preloadInterstitialAd();
    } catch (e) {
      debugPrint('[AdMob] Initialization failed: $e');
    }
  }

  static void _requestConsent() {
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) {
            debugPrint('[AdMob] Consent form error: ${formError.message}');
          } else {
            debugPrint('[AdMob] UMP Consent gathered or not required.');
          }
        });
      },
      (FormError error) {
        debugPrint('[AdMob] Consent info update failure: ${error.message}');
      },
    );
  }

  /// Preloads an interstitial ad into memory so it pops up with zero delay.
  static Future<void> preloadInterstitialAd() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    // Never load ads for Pro users who have removed ads
    if (storeService.currentStatus.isAdsRemoved) {
      debugPrint('[AdMob] User has Pro status; suppressing interstitial preload.');
      return;
    }

    if (_interstitialAd != null || _isLoadingInterstitial) {
      return;
    }

    _isLoadingInterstitial = true;
    final adUnit = interstitialAdUnitId;

    try {
      await InterstitialAd.load(
        adUnitId: adUnit,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('[AdMob] Interstitial ad preloaded successfully.');
            _interstitialAd = ad;
            _isLoadingInterstitial = false;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('[AdMob] Interstitial ad failed to preload: code=${error.code}, message="${error.message}"');
            _interstitialAd = null;
            _isLoadingInterstitial = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdMob] Exception during preload: $e');
      _interstitialAd = null;
      _isLoadingInterstitial = false;
    }
  }

  /// Shows the preloaded interstitial ad.
  /// Used after every successful conversion.
  static Future<void> showInterstitialAdIfAvailable({VoidCallback? onDismissed}) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      onDismissed?.call();
      return;
    }

    // Pro users bypass all ads
    if (storeService.currentStatus.isAdsRemoved) {
      debugPrint('[AdMob] User is Pro; skipping interstitial ad.');
      onDismissed?.call();
      return;
    }

    // Cooldown check: prevent popping up ads within 4 seconds of each other
    if (_lastInterstitialShownTime != null &&
        DateTime.now().difference(_lastInterstitialShownTime!) < const Duration(seconds: 4)) {
      debugPrint('[AdMob] Interstitial ad displayed recently; skipping duplicate popup.');
      onDismissed?.call();
      return;
    }

    // If an ad is already loaded in memory, show it immediately
    if (_interstitialAd != null) {
      _showLoadedInterstitial(onDismissed: onDismissed);
      return;
    }

    // If an ad is currently loading, wait up to 1200ms
    if (_isLoadingInterstitial) {
      debugPrint('[AdMob] Interstitial ad is loading; waiting up to 1200ms...');
      int waitedMs = 0;
      while (_isLoadingInterstitial && waitedMs < 1200) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitedMs += 100;
      }
      if (_interstitialAd != null) {
        _showLoadedInterstitial(onDismissed: onDismissed);
        return;
      }
    }

    // If not available, kick off preload for next conversion and dismiss
    debugPrint('[AdMob] Interstitial ad was not ready in time. Preloading for next conversion.');
    preloadInterstitialAd();
    onDismissed?.call();
  }

  static void _showLoadedInterstitial({VoidCallback? onDismissed}) {
    final ad = _interstitialAd;
    if (ad == null) {
      onDismissed?.call();
      return;
    }

    _interstitialAd = null;
    _lastInterstitialShownTime = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdMob] Interstitial ad displayed on screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] Interstitial ad dismissed by user.');
        ad.dispose();
        preloadInterstitialAd(); // Preload next one immediately
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        debugPrint('[AdMob] Interstitial ad failed to show: code=${error.code}, message="${error.message}"');
        ad.dispose();
        preloadInterstitialAd();
        onDismissed?.call();
      },
      onAdImpression: (ad) => debugPrint('[AdMob] Interstitial ad recorded impression.'),
      onAdClicked: (ad) => debugPrint('[AdMob] Interstitial ad clicked.'),
    );

    ad.show();
  }
}

