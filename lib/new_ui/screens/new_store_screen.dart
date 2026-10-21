import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/pro_provider.dart';
import '../../features/store/store_models.dart';
import '../theme/brutalist_theme.dart';

class NewStoreScreen extends ConsumerStatefulWidget {
  const NewStoreScreen({super.key});

  @override
  ConsumerState<NewStoreScreen> createState() => _NewStoreScreenState();
}

class _NewStoreScreenState extends ConsumerState<NewStoreScreen> {
  String _selectedCategory = 'all'; // all, passes, credits, packs, unlocks
  bool _showQuickRefill = false;
  bool _dailyRewardClaimed = false;
  bool _supplyDropClaimed = false;

  Future<void> _purchaseProduct(String targetId) async {
    final storeService = ref.read(storeServiceProvider);
    final products = ref.read(storeProductsProvider).value ?? [];

    ProductDetails? product;
    try {
      product = products.firstWhere((p) => p.id == targetId);
    } catch (_) {
      try {
        product = products.firstWhere((p) => p.id.contains(targetId));
      } catch (_) {
        product = null;
      }
    }

    if (product != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contacting Google Play for ${product.title}...'),
          backgroundColor: BrutalColors.black,
        ),
      );
      await storeService.buyProduct(product);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store catalog is syncing with Google Play. Please try again in a moment.'),
            backgroundColor: BrutalColors.black,
          ),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    final storeService = ref.read(storeServiceProvider);
    await storeService.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored successfully from Google Play.'),
          backgroundColor: BrutalColors.black,
        ),
      );
    }
  }

  void _claimDailyLoot() async {
    if (_dailyRewardClaimed) return;
    setState(() => _dailyRewardClaimed = true);
    await ref.read(storeServiceProvider).addFreeCredits(10);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ +10 Free Conversions added to your wallet!'),
          backgroundColor: BrutalColors.black,
        ),
      );
    }
  }

  void _claimSupplyDrop() async {
    if (_supplyDropClaimed) return;
    setState(() => _supplyDropClaimed = true);
    await ref.read(storeServiceProvider).addFreeCredits(15);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎁 Daily bonus claimed! +15 Free Conversions added.'),
          backgroundColor: BrutalColors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proStatus = ref.watch(proStatusProvider).value;
    final isPro = proStatus?.isPro ?? false;
    final credits = proStatus?.creditsBalance ?? 450;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: BrutalColors.white,
            border: Border(
              bottom: BorderSide(color: BrutalColors.black, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: BrutalColors.black,
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: BrutalColors.white,
                            border: BrutalTheme.brutalBorder,
                            boxShadow: BrutalTheme.brutalShadowSm,
                          ),
                          child: const Icon(LucideIcons.arrowLeft, size: 18, color: BrutalColors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: BrutalColors.black,
                          border: BrutalTheme.brutalBorderSm,
                        ),
                        child: const Center(
                          child: Text(
                            'CX',
                            style: TextStyle(
                              color: BrutalColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'STORE',
                        style: BrutalTheme.headline(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Pass / Balance Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: BrutalColors.white,
                          border: BrutalTheme.brutalBorder,
                          boxShadow: BrutalTheme.brutalShadowSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isPro ? LucideIcons.crown : LucideIcons.zap, size: 13, color: BrutalColors.black),
                            const SizedBox(width: 4),
                            Text(
                              isPro ? 'UNLIMITED' : '$credits FILES',
                              style: BrutalTheme.headline(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profile Indicator
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: BrutalColors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.user, size: 16, color: BrutalColors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 14, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Status HUD Matrix
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Pro Pass Active Status Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: BrutalColors.white,
                            border: BrutalTheme.brutalBorder,
                            boxShadow: BrutalTheme.brutalShadowSm,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(isPro ? LucideIcons.crown : LucideIcons.award, size: 20, color: BrutalColors.black),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'CONVERTIX PASS',
                                        style: BrutalTheme.label(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        isPro ? '● PRO MEMBER' : '● FREE PLAN',
                                        style: BrutalTheme.headline(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                color: BrutalColors.black,
                                child: Text(
                                  isPro ? 'UNLIMITED' : 'STANDARD',
                                  style: BrutalTheme.label(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: BrutalColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Daily Loot Claim Button
                      Expanded(
                        child: GestureDetector(
                          onTap: _claimDailyLoot,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: BrutalColors.white,
                              border: BrutalTheme.brutalBorder,
                              boxShadow: BrutalTheme.brutalShadowSm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.gift, size: 20, color: BrutalColors.black),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'DAILY BONUS',
                                          style: BrutalTheme.label(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _dailyRewardClaimed ? 'CLAIMED' : '⚡ READY',
                                          style: BrutalTheme.headline(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  color: BrutalColors.black,
                                  child: Text(
                                    _dailyRewardClaimed ? '+10 FILES' : 'FREE',
                                    style: BrutalTheme.label(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: BrutalColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Category Filter Pills (Horizontal Scroller)
                _buildCategoryPills(),

                const SizedBox(height: 12),

                // 3. FEATURED HERO BUNDLE (Ultimate Maker Chest)
                if (_selectedCategory == 'all' || _selectedCategory == 'passes' || _selectedCategory == 'unlocks') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFeaturedHeroBundle(),
                  ),
                  const SizedBox(height: 18),
                ],

                // 4. HORIZONTAL SHELF 1: CONVERSION PACKS
                if (_selectedCategory == 'all' || _selectedCategory == 'credits') ...[
                  _buildShelfHeader(
                    badge: 'HUD // 01',
                    title: 'CONVERSION PACKS',
                    subtitle: 'Quick top-ups to convert videos, photos & documents',
                  ),
                  const SizedBox(height: 8),
                  _buildCreditChestsShelf(),
                  const SizedBox(height: 18),
                ],

                // 5. HORIZONTAL SHELF 2: PASSES & UNLOCKS
                if (_selectedCategory == 'all' || _selectedCategory == 'passes' || _selectedCategory == 'packs') ...[
                  _buildShelfHeader(
                    badge: 'HUD // 02',
                    title: 'PASSES & UNLOCKS',
                    subtitle: 'Unlimited conversions with zero ad interruptions',
                  ),
                  const SizedBox(height: 8),
                  _buildPassesShelf(),
                  const SizedBox(height: 18),
                ],

                // 6. DAILY LOOT & REWARD BOX SECTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDailySupplyDropCard(),
                ),

                const SizedBox(height: 18),

                // 7. FOOTER: VERIFIED & SECURITY SIGNALS
                _buildSecurityFooter(),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // 8. FLOATING QUICK-ACCESS STORE WIDGET & POPOVER
          Positioned(
            right: 16,
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showQuickRefill) ...[
                  Container(
                    width: 260,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: BrutalColors.white,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: BrutalTheme.brutalShadowLg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: BrutalColors.black,
                              child: Text(
                                'QUICK PASS',
                                style: BrutalTheme.label(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: BrutalColors.white,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _showQuickRefill = false),
                              child: const Icon(LucideIcons.x, size: 16, color: BrutalColors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Need extra conversions for your files? Instant tap refill.',
                          style: BrutalTheme.body(
                            fontSize: 11,
                            color: BrutalColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            _purchaseProduct(StoreProductIds.credits50);
                            setState(() => _showQuickRefill = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: const BoxDecoration(
                              color: BrutalColors.black,
                              border: BrutalTheme.brutalBorderSm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '⚡ 50 FAST CONVERSIONS',
                                  style: BrutalTheme.headline(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: BrutalColors.white,
                                  ),
                                ),
                                Text(
                                  '₹19',
                                  style: BrutalTheme.headline(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: BrutalColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Floating Trigger Button
                GestureDetector(
                  onTap: () => setState(() => _showQuickRefill = !_showQuickRefill),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: BrutalColors.black,
                          border: BrutalTheme.brutalBorder,
                          boxShadow: BrutalTheme.brutalShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.zap, size: 18, color: BrutalColors.white),
                            const SizedBox(width: 6),
                            Text(
                              'QUICK PASS',
                              style: BrutalTheme.headline(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: BrutalColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -6,
                        left: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: const BoxDecoration(
                            color: BrutalColors.white,
                            border: Border.fromBorderSide(
                              BorderSide(color: BrutalColors.black, width: 1.5),
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style: BrutalTheme.label(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: BrutalColors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    final categories = [
      {'id': 'all', 'label': '[ ★ ALL PLANS ]'},
      {'id': 'passes', 'label': '[ PASSES & SUBS ]'},
      {'id': 'credits', 'label': '[ CONVERSION PACKS ]'},
      {'id': 'packs', 'label': '[ POPULAR ]'},
      {'id': 'unlocks', 'label': '[ UNLOCKS ]'},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['id']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? BrutalColors.black : BrutalColors.white,
                border: BrutalTheme.brutalBorder,
                boxShadow: BrutalTheme.brutalShadowSm,
              ),
              child: Text(
                cat['label']!,
                style: BrutalTheme.label(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? BrutalColors.white : BrutalColors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedHeroBundle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: BrutalColors.black,
        border: BrutalTheme.brutalBorder,
        boxShadow: BrutalTheme.brutalShadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: BrutalColors.white,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.award, size: 13, color: BrutalColors.black),
                    const SizedBox(width: 4),
                    Text(
                      'SPECIAL OFFER // 60% OFF',
                      style: BrutalTheme.label(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: BrutalColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'LIMITED TIME OFFER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'CONVERTIX ALL-ACCESS PASS',
            style: BrutalTheme.headline(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: BrutalColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unlock unlimited file conversions, zero ads, batch tools, and save phone storage effortlessly.',
            style: BrutalTheme.body(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          // 2x2 Perks Matrix
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.8,
            children: [
              _buildBundlePerk('Unlimited Fast Conversions'),
              _buildBundlePerk('All Video, Photo & Audio'),
              _buildBundlePerk('100% Ad-Free Experience'),
              _buildBundlePerk('No File Size Restrictions'),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _purchaseProduct(StoreProductIds.lifetimePro),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: BrutalColors.white,
                border: BrutalTheme.brutalBorder,
                boxShadow: BrutalTheme.brutalShadowWhite,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.lockKeyholeOpen, size: 18, color: BrutalColors.black),
                      const SizedBox(width: 6),
                      Text(
                        'UNLOCK LIFETIME ACCESS',
                        style: BrutalTheme.headline(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: BrutalColors.black,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: BrutalColors.black,
                    child: Text(
                      '₹499',
                      style: BrutalTheme.headline(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: BrutalColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundlePerk(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.checkSquare, size: 14, color: BrutalColors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BrutalTheme.label(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: BrutalColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfHeader({
    required String badge,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    color: BrutalColors.black,
                    child: Text(
                      badge,
                      style: BrutalTheme.label(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: BrutalColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: BrutalTheme.headline(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: BrutalTheme.body(
                  fontSize: 11,
                  color: BrutalColors.textMuted,
                ),
              ),
            ],
          ),
          Text(
            'SWIPE >>',
            style: BrutalTheme.label(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: BrutalColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditChestsShelf() {
    final chests = [
      {
        'tier': 'TIER 1',
        'title': 'Starter Pack',
        'amount': '50 FILES',
        'desc': '50 Fast File Conversions',
        'price': '₹19',
        'id': StoreProductIds.credits50,
        'badge': null,
      },
      {
        'tier': 'TIER 2',
        'title': 'Everyday Pack',
        'amount': '220 FILES',
        'bonus': '+20 BONUS',
        'desc': '200 + 20 Bonus Conversions',
        'price': '₹49',
        'id': StoreProductIds.credits200,
        'badge': '★ POPULAR',
      },
      {
        'tier': 'TIER 3',
        'title': 'Mega Pack',
        'amount': '600 FILES',
        'bonus': '+100 BONUS',
        'desc': '500 + 100 Bonus for Batches',
        'price': '₹99',
        'id': StoreProductIds.credits500,
        'badge': 'BEST VALUE',
      },
      {
        'tier': 'TIER 4',
        'title': 'Family Pack',
        'amount': '1,500 FILES',
        'desc': 'Large photo & video library',
        'price': '₹249',
        'id': StoreProductIds.credits500,
        'badge': null,
      },
    ];

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chests.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final c = chests[index];
          final badge = c['badge'];

          return Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: BrutalColors.white,
              border: BrutalTheme.brutalBorder,
              boxShadow: BrutalTheme.brutalShadow,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (badge != null)
                  Positioned(
                    top: -18,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: BrutalColors.black,
                      child: Text(
                        badge,
                        style: BrutalTheme.label(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: BrutalColors.white,
                        ),
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              color: BrutalColors.surfaceContainerHigh,
                              child: Text(
                                c['tier'] as String,
                                style: BrutalTheme.label(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (c['bonus'] != null)
                              Text(
                                c['bonus'] as String,
                                style: BrutalTheme.label(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: BrutalColors.black,
                                ),
                              )
                            else
                              const Icon(LucideIcons.coins, size: 16, color: BrutalColors.black),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 56,
                          width: double.infinity,
                          color: BrutalColors.surfaceContainerLow,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.circleDollarSign, size: 22, color: BrutalColors.black),
                              const SizedBox(height: 2),
                              Text(
                                c['amount'] as String,
                                style: BrutalTheme.headline(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c['title'] as String,
                          style: BrutalTheme.headline(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c['desc'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BrutalTheme.body(
                            fontSize: 10,
                            color: BrutalColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _purchaseProduct(c['id'] as String),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: const BoxDecoration(
                          color: BrutalColors.black,
                          border: BrutalTheme.brutalBorderSm,
                          boxShadow: BrutalTheme.brutalShadowSm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'BUY ',
                              style: BrutalTheme.headline(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: BrutalColors.white,
                              ),
                            ),
                            Text(
                              c['price'] as String,
                              style: BrutalTheme.headline(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: BrutalColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPassesShelf() {
    return SizedBox(
      height: 250,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Pass Card 1: Annual Pass (Featured Black)
          Container(
            width: 230,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: BrutalColors.black,
              border: BrutalTheme.brutalBorder,
              boxShadow: BrutalTheme.brutalShadowLg,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -18,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: BrutalColors.white,
                    child: Text(
                      'MOST POPULAR',
                      style: BrutalTheme.label(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: BrutalColors.black,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              color: BrutalColors.white,
                              child: Text(
                                '365 DAYS',
                                style: BrutalTheme.label(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: BrutalColors.black,
                                ),
                              ),
                            ),
                            const Icon(LucideIcons.crown, size: 18, color: BrutalColors.white),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Annual Pass',
                          style: BrutalTheme.headline(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: BrutalColors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '₹299/yr',
                              style: BrutalTheme.headline(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: BrutalColors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '(~₹25/mo)',
                              style: TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildPassBullet('100% Ad-Free Experience', isDark: true),
                        _buildPassBullet('Instant Fast Processing', isDark: true),
                        _buildPassBullet('Unlimited Batch Conversions', isDark: true),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _purchaseProduct(StoreProductIds.proYearly),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          color: BrutalColors.white,
                          border: BrutalTheme.brutalBorderSm,
                        ),
                        child: Center(
                          child: Text(
                            'GET ANNUAL PASS',
                            style: BrutalTheme.headline(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: BrutalColors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pass Card 2: Monthly Pass
          _buildPassWhiteCard(
            tierBadge: '30 DAYS',
            icon: LucideIcons.calendar,
            title: 'Monthly Pass',
            price: '₹49/mo',
            desc: 'Unlimited file conversions & active ad shield for everyday smooth workflows.',
            btnText: 'GET PASS',
            id: StoreProductIds.proMonthly,
          ),

          // Pass Card 3: Document & Media Pack
          _buildPassWhiteCard(
            tierBadge: 'PERMANENT',
            icon: LucideIcons.files,
            title: 'Document & Media Pack',
            price: '₹149 once',
            desc: 'Full access to all PDF, office, video and photo tools forever.',
            btnText: 'PURCHASE',
            id: StoreProductIds.bundleFilmmaker,
          ),

          // Pass Card 4: Ad Blocker Shield
          _buildPassWhiteCard(
            tierBadge: 'LIFETIME',
            icon: LucideIcons.shield,
            title: 'Ad Shield',
            price: '₹29 forever',
            desc: '100% Zero banners, popups, or interstitial ads across the entire app.',
            btnText: 'GET SHIELD',
            id: StoreProductIds.removeAds,
          ),
        ],
      ),
    );
  }

  Widget _buildPassWhiteCard({
    required String tierBadge,
    required IconData icon,
    required String title,
    required String price,
    required String desc,
    required String btnText,
    required String id,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: BrutalColors.white,
        border: BrutalTheme.brutalBorder,
        boxShadow: BrutalTheme.brutalShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    color: BrutalColors.black,
                    child: Text(
                      tierBadge,
                      style: BrutalTheme.label(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: BrutalColors.white,
                      ),
                    ),
                  ),
                  Icon(icon, size: 18, color: BrutalColors.black),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: BrutalTheme.headline(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                price,
                style: BrutalTheme.headline(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: BrutalTheme.body(
                  fontSize: 10.5,
                  color: BrutalColors.textMuted,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _purchaseProduct(id),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: const BoxDecoration(
                color: BrutalColors.black,
                border: BrutalTheme.brutalBorderSm,
                boxShadow: BrutalTheme.brutalShadowSm,
              ),
              child: Center(
                child: Text(
                  btnText,
                  style: BrutalTheme.headline(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: BrutalColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassBullet(String text, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(LucideIcons.check, size: 12, color: isDark ? BrutalColors.white : BrutalColors.black),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : BrutalColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySupplyDropCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: BrutalColors.white,
        border: BrutalTheme.brutalBorder,
        boxShadow: BrutalTheme.brutalShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.gift, size: 18, color: BrutalColors.black),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    color: BrutalColors.black,
                    child: Text(
                      'DAILY REFRESH',
                      style: BrutalTheme.label(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: BrutalColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'RESET IN 06:12:44',
                style: BrutalTheme.label(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: BrutalColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'FREE DAILY BONUS',
            style: BrutalTheme.headline(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Watch 1 quick sponsor video to immediately collect +10 Free File Conversions.',
            style: BrutalTheme.body(
              fontSize: 11,
              color: BrutalColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _claimSupplyDrop,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _supplyDropClaimed ? BrutalColors.surfaceContainerHigh : BrutalColors.white,
                border: BrutalTheme.brutalBorder,
                boxShadow: BrutalTheme.brutalShadowSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _supplyDropClaimed ? LucideIcons.checkCheck : LucideIcons.playCircle,
                    size: 16,
                    color: BrutalColors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _supplyDropClaimed ? 'BONUS REDEEMED (+15 FILES)' : 'CLAIM FREE BONUS (READY)',
                    style: BrutalTheme.headline(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: BrutalColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFooterBadge(LucideIcons.lock, '256-BIT CRYPTO')),
              const SizedBox(width: 8),
              Expanded(child: _buildFooterBadge(LucideIcons.rotateCcw, '1-TAP REFUND')),
              const SizedBox(width: 8),
              Expanded(child: _buildFooterBadge(LucideIcons.shieldCheck, 'PLAY VERIFIED')),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'All purchases sync across your devices via Google Play Services. No subscriptions autorenew without explicit consent.',
            textAlign: TextAlign.center,
            style: BrutalTheme.body(
              fontSize: 10,
              color: BrutalColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'CONVERTIX PRO // GOOGLE PLAY VERIFIED',
            style: BrutalTheme.label(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: BrutalColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _handleRestore,
            child: Text(
              'Restore Purchases',
              style: BrutalTheme.headline(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: BrutalColors.white,
        border: BrutalTheme.brutalBorderSm,
        boxShadow: BrutalTheme.brutalShadowSm,
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: BrutalColors.black),
          const SizedBox(height: 3),
          Text(
            label,
            style: BrutalTheme.label(
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
