import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../shared/constants/ad_constants.dart';
import '../providers/pro_provider.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoading && _retryAttempts == 0) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    if (kIsWeb) return;

    final isAdsRemoved = ref.read(proStatusProvider).value?.isAdsRemoved ?? false;
    if (isAdsRemoved) return;
    if (_isLoading || _bannerAd != null) return;

    _isLoading = true;

    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      // Anchored adaptive banners increase match rate significantly compared to fixed 320x50,
      // as they allow AdMob's auction to consider all responsive and varied-sized creatives.
      final AdSize? adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      final adSize = adaptiveSize ?? AdSize.banner;

      if (!mounted) {
        _isLoading = false;
        return;
      }

      final adUnitId = _getAdUnitId();

      final bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            final banner = ad as BannerAd;
            debugPrint('[AdMob] Banner ad loaded (${banner.size.width}x${banner.size.height})');
            if (mounted) {
              setState(() {
                _bannerAd = banner;
                _isLoaded = true;
                _isLoading = false;
                _retryAttempts = 0;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              '[AdMob] Banner ad failed to load: code=${error.code}, '
              'message="${error.message}", domain="${error.domain}"',
            );
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isLoaded = false;
                _isLoading = false;
              });

              // Exponential backoff retry for transient network (code 2) or no-fill (code 3) failures.
              if (_retryAttempts < _maxRetryAttempts) {
                _retryAttempts++;
                final delaySec = _retryAttempts * 10;
                debugPrint('[AdMob] Scheduling ad reload retry #$_retryAttempts in ${delaySec}s');
                Future.delayed(Duration(seconds: delaySec), () {
                  if (mounted && _bannerAd == null && !_isLoading) {
                    _loadAd();
                  }
                });
              }
            }
          },
          onAdOpened: (ad) => debugPrint('[AdMob] Banner ad opened'),
          onAdClosed: (ad) => debugPrint('[AdMob] Banner ad closed'),
          onAdImpression: (ad) => debugPrint('[AdMob] Banner ad recorded impression'),
        ),
      );

      await bannerAd.load();
    } catch (e) {
      debugPrint('[AdMob] Error loading banner ad: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAdUnitId() {
    if (Platform.isAndroid) {
      return androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return iosBannerAdUnitId;
    }
    return androidBannerAdUnitId;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proStatus = ref.watch(proStatusProvider).value;
    if (proStatus?.isAdsRemoved == true) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
