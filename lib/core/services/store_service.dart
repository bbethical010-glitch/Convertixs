import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/store/store_models.dart';

class StoreService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final _proStatusController = StreamController<ProStatus>.broadcast();
  Stream<ProStatus> get proStatusStream => _proStatusController.stream;

  final _purchaseErrorController = StreamController<String>.broadcast();
  Stream<String> get purchaseErrorStream => _purchaseErrorController.stream;

  final _purchasePendingController = StreamController<bool>.broadcast();
  Stream<bool> get purchasePendingStream => _purchasePendingController.stream;

  ProStatus _currentStatus = const ProStatus();
  ProStatus get currentStatus => _currentStatus;

  List<ProductDetails> _availableProducts = [];
  List<ProductDetails> get availableProducts => _availableProducts;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Future<void> initialize() async {
    await _loadSavedEntitlements();

    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        _purchaseErrorController.add('Purchase stream error: $error');
      },
    );

    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      await loadProducts();
    }
  }

  void dispose() {
    _subscription?.cancel();
    _proStatusController.close();
    _purchaseErrorController.close();
    _purchasePendingController.close();
  }

  Future<void> loadProducts() async {
    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(StoreProductIds.allIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[StoreService] Products not found on Play Console: ${response.notFoundIDs}');
      }

      _availableProducts = response.productDetails;
    } catch (e) {
      debugPrint('[StoreService] Failed to query product details: $e');
    }
  }

  ProductDetails? getProductDetails(String productId) {
    try {
      return _availableProducts.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    _purchasePendingController.add(true);
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    try {
      if (StoreProductIds.consumableIds.contains(product.id)) {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _purchasePendingController.add(false);
      _purchaseErrorController.add('Failed to initiate purchase: $e');
    }
  }

  Future<void> restorePurchases() async {
    _purchasePendingController.add(true);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _purchasePendingController.add(false);
      _purchaseErrorController.add('Failed to restore purchases: $e');
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _purchasePendingController.add(true);
      } else {
        _purchasePendingController.add(false);

        if (purchase.status == PurchaseStatus.error) {
          _purchaseErrorController.add(purchase.error?.message ?? 'Purchase failed');
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _grantEntitlement(purchase.productID);
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _grantEntitlement(String productId) async {
    final prefs = await SharedPreferences.getInstance();

    bool isLifetimePro = _currentStatus.isLifetimePro;
    bool hasActiveSubscription = _currentStatus.hasActiveSubscription;
    String? activeSub = _currentStatus.activeSubscriptionId;
    bool isAdsRemovedOnly = _currentStatus.isAdsRemovedOnly;
    bool hasFilmmakerPack = _currentStatus.hasFilmmakerPack;
    bool hasDocumentPack = _currentStatus.hasDocumentPack;
    int creditsBalance = _currentStatus.creditsBalance;

    switch (productId) {
      case StoreProductIds.lifetimePro:
        isLifetimePro = true;
        await prefs.setBool('entitlement_lifetime_pro', true);
        break;
      case StoreProductIds.proMonthly:
      case StoreProductIds.proYearly:
        hasActiveSubscription = true;
        activeSub = productId;
        await prefs.setBool('entitlement_has_subscription', true);
        await prefs.setString('entitlement_subscription_id', productId);
        break;
      case StoreProductIds.removeAds:
        isAdsRemovedOnly = true;
        await prefs.setBool('entitlement_remove_ads', true);
        break;
      case StoreProductIds.bundleFilmmaker:
        hasFilmmakerPack = true;
        await prefs.setBool('entitlement_bundle_filmmaker', true);
        break;
      case StoreProductIds.bundleDocPro:
        hasDocumentPack = true;
        await prefs.setBool('entitlement_bundle_doc_pro', true);
        break;
      case StoreProductIds.credits50:
        creditsBalance += 50;
        await prefs.setInt('entitlement_credits_balance', creditsBalance);
        break;
      case StoreProductIds.credits200:
        creditsBalance += 200;
        await prefs.setInt('entitlement_credits_balance', creditsBalance);
        break;
      case StoreProductIds.credits500:
        creditsBalance += 500;
        await prefs.setInt('entitlement_credits_balance', creditsBalance);
        break;
    }

    _currentStatus = ProStatus(
      isLifetimePro: isLifetimePro,
      hasActiveSubscription: hasActiveSubscription,
      activeSubscriptionId: activeSub,
      isAdsRemovedOnly: isAdsRemovedOnly,
      hasFilmmakerPack: hasFilmmakerPack,
      hasDocumentPack: hasDocumentPack,
      creditsBalance: creditsBalance,
    );

    _proStatusController.add(_currentStatus);
  }

  /// Deducts [amount] credits from the user balance if available.
  Future<bool> consumeCredit([int amount = 1]) async {
    if (_currentStatus.isPro) {
      // Pro users have unlimited access, don't consume credits
      return true;
    }
    if (_currentStatus.creditsBalance < amount) {
      return false;
    }

    final newBalance = _currentStatus.creditsBalance - amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('entitlement_credits_balance', newBalance);

    _currentStatus = ProStatus(
      isLifetimePro: _currentStatus.isLifetimePro,
      hasActiveSubscription: _currentStatus.hasActiveSubscription,
      activeSubscriptionId: _currentStatus.activeSubscriptionId,
      isAdsRemovedOnly: _currentStatus.isAdsRemovedOnly,
      hasFilmmakerPack: _currentStatus.hasFilmmakerPack,
      hasDocumentPack: _currentStatus.hasDocumentPack,
      creditsBalance: newBalance,
    );

    _proStatusController.add(_currentStatus);
    return true;
  }

  /// Adds [amount] free credits (e.g. from Daily Loot or Reward Box).
  Future<void> addFreeCredits(int amount) async {
    final newBalance = _currentStatus.creditsBalance + amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('entitlement_credits_balance', newBalance);

    _currentStatus = _currentStatus.copyWith(creditsBalance: newBalance);
    _proStatusController.add(_currentStatus);
  }

  Future<void> _loadSavedEntitlements() async {
    final prefs = await SharedPreferences.getInstance();

    final isLifetimePro = prefs.getBool('entitlement_lifetime_pro') ?? false;
    final hasActiveSubscription = prefs.getBool('entitlement_has_subscription') ?? false;
    final activeSub = prefs.getString('entitlement_subscription_id');
    final isAdsRemovedOnly = prefs.getBool('entitlement_remove_ads') ?? false;
    final hasFilmmakerPack = prefs.getBool('entitlement_bundle_filmmaker') ?? false;
    final hasDocumentPack = prefs.getBool('entitlement_bundle_doc_pro') ?? false;
    final creditsBalance = prefs.getInt('entitlement_credits_balance') ?? 0;

    _currentStatus = ProStatus(
      isLifetimePro: isLifetimePro,
      hasActiveSubscription: hasActiveSubscription,
      activeSubscriptionId: activeSub,
      isAdsRemovedOnly: isAdsRemovedOnly,
      hasFilmmakerPack: hasFilmmakerPack,
      hasDocumentPack: hasDocumentPack,
      creditsBalance: creditsBalance,
    );

    _proStatusController.add(_currentStatus);
  }
}

final storeService = StoreService();
