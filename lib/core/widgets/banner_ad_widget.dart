import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
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
  String? _adUnitId;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) {
      return;
    }

    final isAdsRemoved = ref.read(proStatusProvider).value?.isAdsRemoved ?? false;
    if (isAdsRemoved) {
      return;
    }

    _adUnitId = _getAdUnitId();

    _bannerAd = BannerAd(
      adUnitId: _adUnitId!,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    );

    _bannerAd!.load();
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

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
