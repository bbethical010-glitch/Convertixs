import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ProductType {
  subscription,
  nonConsumable,
  consumable,
}

class StoreProduct {
  final String id;
  final String title;
  final String description;
  final String defaultPrice;
  final ProductType type;
  final IconData icon;
  final Color color;
  final String? badge;
  final List<String> features;
  final int? creditsAmount;

  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.defaultPrice,
    required this.type,
    required this.icon,
    required this.color,
    this.badge,
    required this.features,
    this.creditsAmount,
  });
}

class ProStatus {
  final bool isLifetimePro;
  final bool hasActiveSubscription;
  final String? activeSubscriptionId;
  final bool isAdsRemovedOnly;
  final bool hasFilmmakerPack;
  final bool hasDocumentPack;
  final int creditsBalance;

  const ProStatus({
    this.isLifetimePro = false,
    this.hasActiveSubscription = false,
    this.activeSubscriptionId,
    this.isAdsRemovedOnly = false,
    this.hasFilmmakerPack = false,
    this.hasDocumentPack = false,
    this.creditsBalance = 0,
  });

  /// User has full VIP access to everything
  bool get isPro => isLifetimePro || hasActiveSubscription;

  /// User has ads removed
  bool get isAdsRemoved => isPro || isAdsRemovedOnly;

  /// User can use advanced LOG/HDR profiles and 4K exports
  bool get canUseFilmmaker => isPro || hasFilmmakerPack;

  /// User can use advanced document batch and high-capacity conversions
  bool get canUseDocumentPro => isPro || hasDocumentPack;

  /// Has any positive credit balance
  bool get hasCredits => creditsBalance > 0;
}

/// Defined Play Store product identifiers
class StoreProductIds {
  // Subscriptions
  static const String proMonthly = 'convertix_pro_monthly';
  static const String proYearly = 'convertix_pro_yearly';

  // One-time purchases (Non-consumable)
  static const String lifetimePro = 'convertix_lifetime_pro';
  static const String removeAds = 'convertix_remove_ads';
  static const String bundleFilmmaker = 'convertix_bundle_filmmaker';
  static const String bundleDocPro = 'convertix_bundle_doc_pro';

  // One-time purchases (Consumable credit packs)
  static const String credits50 = 'convertix_credits_50';
  static const String credits200 = 'convertix_credits_200';
  static const String credits500 = 'convertix_credits_500';

  static const Set<String> allIds = {
    proMonthly,
    proYearly,
    lifetimePro,
    removeAds,
    bundleFilmmaker,
    bundleDocPro,
    credits50,
    credits200,
    credits500,
  };

  static const Set<String> subscriptionIds = {
    proMonthly,
    proYearly,
  };

  static const Set<String> inAppProductIds = {
    lifetimePro,
    removeAds,
    bundleFilmmaker,
    bundleDocPro,
    credits50,
    credits200,
    credits500,
  };

  static const Set<String> consumableIds = {
    credits50,
    credits200,
    credits500,
  };
}

/// Catalog definitions tailored for Indian mobile market (INR ₹)
final List<StoreProduct> kCatalogProducts = [
  // 1. Subscriptions
  const StoreProduct(
    id: StoreProductIds.proYearly,
    title: 'Pro Annual Pass',
    description: 'Complete unrestricted access, billed annually (~₹25/mo)',
    defaultPrice: '₹299 / year',
    type: ProductType.subscription,
    icon: LucideIcons.crown,
    color: Color(0xFFEAB308), // Gold
    badge: 'BEST VALUE • SAVE 50%',
    features: [
      'All Pro features & future updates',
      'Completely Ad-Free experience',
      'All 10 Camera LOG/HDR Profiles',
      '4K & 2K Ultra HD video conversions',
      'Unlimited document & PDF file size',
      'Priority high-speed cloud queue',
    ],
  ),
  const StoreProduct(
    id: StoreProductIds.proMonthly,
    title: 'Pro Monthly Pass',
    description: 'Complete unrestricted access, flexible monthly billing',
    defaultPrice: '₹49 / month',
    type: ProductType.subscription,
    icon: LucideIcons.sparkles,
    color: Color(0xFF6366F1), // Indigo
    features: [
      'All Pro features included',
      'Completely Ad-Free experience',
      'All 10 Camera LOG/HDR Profiles',
      '4K & 2K Ultra HD video conversions',
      'Unlimited document file sizes',
      'Cancel anytime via Google Play',
    ],
  ),

  // 2. One-time permanent purchases
  const StoreProduct(
    id: StoreProductIds.lifetimePro,
    title: 'Lifetime All-Access',
    description: 'Pay once, own all current & future Pro features forever',
    defaultPrice: '₹499 once',
    type: ProductType.nonConsumable,
    icon: LucideIcons.gem,
    color: Color(0xFFEC4899), // Pink
    badge: 'PAY ONCE • NEVER PAY AGAIN',
    features: [
      'Lifetime access with zero recurring fees',
      'All current & upcoming Pro features',
      'Permanent Ad removal forever',
      'All camera LOG tone mapping & 4K exports',
      'Unlimited document conversion file limits',
      'Works across all your Android devices',
    ],
  ),
  const StoreProduct(
    id: StoreProductIds.removeAds,
    title: 'Remove Ads Permanently',
    description: 'Enjoy a clean, fast, distraction-free app experience',
    defaultPrice: '₹29 once',
    type: ProductType.nonConsumable,
    icon: LucideIcons.shieldCheck,
    color: Color(0xFF8B5CF6), // Purple
    badge: 'POPULAR',
    features: [
      'Permanently removes all banner ads',
      'Faster screen loading & less mobile data usage',
      'Single one-time payment for life',
    ],
  ),
  const StoreProduct(
    id: StoreProductIds.bundleFilmmaker,
    title: 'Filmmaker Video Pack',
    description: 'Advanced LOG tone mapping & high-resolution video tools',
    defaultPrice: '₹149 once',
    type: ProductType.nonConsumable,
    icon: LucideIcons.video,
    color: Color(0xFF06B6D4), // Cyan
    badge: 'CREATOR SPECIAL',
    features: [
      'All 10 Sony, Canon, DJI, Panasonic LOG profiles',
      'BT.709 Hable & Reinhard HDR tone mapping',
      'Ultra HD 4K & 2K video resolution exports',
      'High-bitrate audio retention',
    ],
  ),
  const StoreProduct(
    id: StoreProductIds.bundleDocPro,
    title: 'Document Master Pack',
    description: 'High-capacity PDF, Office & text document conversion suite',
    defaultPrice: '₹99 once',
    type: ProductType.nonConsumable,
    icon: LucideIcons.fileText,
    color: Color(0xFF10B981), // Emerald
    features: [
      'No 50MB file size limit for documents',
      'Priority Cloud LibreOffice conversion engine',
      'Fast multi-page PDF splitting and merging',
      'Direct high-fidelity vector PDF preservation',
    ],
  ),

  // 3. Consumable Credit Packs
  const StoreProduct(
    id: StoreProductIds.credits50,
    title: '50 Conversion Credits',
    description: '50 Pro conversion activities & priority tasks',
    defaultPrice: '₹19',
    type: ProductType.consumable,
    icon: LucideIcons.coins,
    color: Color(0xFFF97316), // Orange
    creditsAmount: 50,
    features: [
      '50 High-priority conversions',
      'Use for large documents or 4K video exports',
      'Credits never expire',
      'Can be repurchased anytime',
    ],
  ),
  const StoreProduct(
    id: StoreProductIds.credits200,
    title: '200 Conversion Credits',
    description: '200 Pro conversion activities & priority tasks',
    defaultPrice: '₹49',
    type: ProductType.consumable,
    icon: LucideIcons.coins,
    color: Color(0xFFE11D48), // Rose
    badge: 'MOST POPULAR PACK',
    creditsAmount: 200,
    features: [
      '200 High-priority conversions',
      'Great for batch PDF & media operations',
      'Credits never expire',
      'Can be repurchased anytime',
    ],
  ),
  const StoreProduct(
    id: StoreProductIds.credits500,
    title: '500 Conversion Credits',
    description: '500 Pro conversion activities & bulk tasks',
    defaultPrice: '₹99',
    type: ProductType.consumable,
    icon: LucideIcons.coins,
    color: Color(0xFF7C3AED), // Violet
    badge: 'BEST VALUE PACK',
    creditsAmount: 500,
    features: [
      '500 High-priority conversions',
      'Maximum value per credit (just ~₹0.19/credit)',
      'Credits never expire',
      'Can be repurchased anytime',
    ],
  ),
];
