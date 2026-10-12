import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/pro_provider.dart';
import 'store_models.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _listenToErrors() {
    ref.listen<AsyncValue<String>>(purchaseErrorProvider, (previous, next) {
      next.whenData((errorMsg) {
        if (mounted && errorMsg.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    });
  }

  Future<void> _handlePurchase(StoreProduct item, List<ProductDetails> storeProducts) async {
    final storeService = ref.read(storeServiceProvider);

    // Look for matching Play Store product
    ProductDetails? playProduct;
    try {
      playProduct = storeProducts.firstWhere((p) => p.id == item.id);
    } catch (_) {
      playProduct = null;
    }

    if (playProduct != null) {
      await storeService.buyProduct(playProduct);
    } else {
      // In sandbox/testing mode when Play Store products are pending review in Console
      _showDevSimulationDialog(item);
    }
  }

  void _showDevSimulationDialog(StoreProduct item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(item.icon, color: item.color),
            const SizedBox(width: 8),
            Expanded(child: Text(item.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product ID: ${item.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: ${item.defaultPrice}',
              style: TextStyle(fontWeight: FontWeight.w600, color: item.color),
            ),
            const SizedBox(height: 8),
            Text(
              'This product is configured for Google Play Billing (INR). In development before Play Console approval, you can simulate this purchase:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: item.color),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Simulating grant for local testing
              await ref.read(storeServiceProvider).initialize();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Testing: Unlocked ${item.title}!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Simulate Purchase'),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    final service = ref.read(storeServiceProvider);
    await service.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking Google Play for previous purchases...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    _listenToErrors();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final proStatusAsync = ref.watch(proStatusProvider);
    final isPending = ref.watch(purchasePendingProvider).value ?? false;
    final storeProducts = ref.watch(storeProductsProvider).value ?? [];

    final proStatus = proStatusAsync.value ?? const ProStatus();

    final subscriptionPlans = kCatalogProducts
        .where((p) => p.type == ProductType.subscription || p.id == StoreProductIds.lifetimePro)
        .toList();

    final bundleProducts = kCatalogProducts
        .where((p) => p.type == ProductType.nonConsumable && p.id != StoreProductIds.lifetimePro)
        .toList();

    final creditPacks = kCatalogProducts
        .where((p) => p.type == ProductType.consumable)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convertix Store'),
        actions: [
          TextButton.icon(
            onPressed: isPending ? null : _restorePurchases,
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
            label: const Text('Restore'),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Hero Banner with INR styling
              _buildHeroHeader(context, proStatus),
              const SizedBox(height: 16),

              // Tab Selector: 3 Tabs (Plans, Bundles, Credits)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: colorScheme.onPrimary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'Pro Plans'),
                    Tab(text: 'Feature Packs'),
                    Tab(text: 'Credit Packs'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab contents
              SizedBox(
                height: 520,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlansList(subscriptionPlans, storeProducts, proStatus),
                    _buildPlansList(bundleProducts, storeProducts, proStatus),
                    _buildPlansList(creditPacks, storeProducts, proStatus),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildFeatureComparison(context),
              const SizedBox(height: 24),
              _buildFooterLegal(context),
              const SizedBox(height: 32),
            ],
          ),
          if (isPending)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Connecting to Google Play...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, ProStatus status) {
    final theme = Theme.of(context);
    final isPro = status.isPro;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPro
              ? [const Color(0xFF10B981), const Color(0xFF047857)]
              : [const Color(0xFF4F46E5), const Color(0xFF7C3AED), const Color(0xFFC026D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPro ? const Color(0xFF10B981) : const Color(0xFF6366F1))
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPro ? LucideIcons.badgeCheck : LucideIcons.crown,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro ? 'CONVERTIX PRO ACTIVE' : 'CONVERTIX PRO STORE',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      isPro
                          ? 'Unlimited Pro access active'
                          : 'Affordable Pro Tools & Conversion Credits',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureBadge('🚫 Ad-Free', isPro || status.isAdsRemoved),
              _buildFeatureBadge('🎬 10 LOG Profiles', isPro || status.canUseFilmmaker),
              _buildFeatureBadge('🖥️ 4K Video', isPro || status.canUseFilmmaker),
              _buildFeatureBadge('📑 Unlimited Size', isPro || status.canUseDocumentPro),
              if (status.creditsBalance > 0)
                _buildFeatureBadge('🪙 ${status.creditsBalance} Credits', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPlansList(
    List<StoreProduct> items,
    List<ProductDetails> storeProducts,
    ProStatus status,
  ) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isConsumable = item.type == ProductType.consumable;
        final isOwned = !isConsumable && _checkIsOwned(item.id, status);

        // Resolve real price from Google Play if available
        String displayPrice = item.defaultPrice;
        try {
          final playProduct = storeProducts.firstWhere((p) => p.id == item.id);
          displayPrice = playProduct.price;
        } catch (_) {}

        return _buildProductCard(item, displayPrice, isOwned, storeProducts);
      },
    );
  }

  bool _checkIsOwned(String id, ProStatus status) {
    if (status.isLifetimePro) return true;
    if (status.hasActiveSubscription) {
      if (id == StoreProductIds.proMonthly || id == StoreProductIds.proYearly) {
        return status.activeSubscriptionId == id;
      }
      return true;
    }
    if (id == StoreProductIds.removeAds && status.isAdsRemovedOnly) return true;
    if (id == StoreProductIds.bundleFilmmaker && status.hasFilmmakerPack) return true;
    if (id == StoreProductIds.bundleDocPro && status.hasDocumentPack) return true;
    return false;
  }

  Widget _buildProductCard(
    StoreProduct item,
    String displayPrice,
    bool isOwned,
    List<ProductDetails> storeProducts,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConsumable = item.type == ProductType.consumable;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: item.badge != null ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.badge != null
              ? item.color.withValues(alpha: 0.6)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: item.badge != null ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        item.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...item.features.map(
              (feat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.check,
                      size: 16,
                      color: item.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feat,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayPrice,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: item.color,
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isOwned ? Colors.grey : item.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isOwned
                      ? null
                      : () => _handlePurchase(item, storeProducts),
                  child: Text(
                    isOwned
                        ? 'Purchased'
                        : (isConsumable ? 'Buy Credits' : 'Get Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final comparison = [
      ('In-App Ads', 'Banner Ads', 'No Ads Forever'),
      ('Video Tone Mapping', 'Standard SDR', 'All 10 LOG Profiles'),
      ('Video Max Resolution', '1080p', '4K & 2K Ultra HD'),
      ('Document File Size', 'Max 50 MB', 'Unlimited'),
      ('Server Processing', 'Standard', 'VIP Priority Queue'),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Comparison',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.4),
                2: FlexColumnWidth(1.8),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Free', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Pro / Bundles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                    ),
                  ],
                ),
                ...comparison.map(
                  (row) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(row.$1, style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(row.$2, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(row.$3, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLegal(BuildContext context) {
    return Column(
      children: [
        Text(
          'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in Google Play Store > Subscriptions.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _launchUrl('https://convertix.app/terms'),
              child: const Text('Terms of Service', style: TextStyle(fontSize: 11)),
            ),
            const Text('•', style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () => _launchUrl('https://convertix.app/privacy'),
              child: const Text('Privacy Policy', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }
}
