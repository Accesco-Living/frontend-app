import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_restaurant_provider.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import 'swadisht_screen.dart';
import 'swadisht_food_detail_screen.dart';
import 'cart_screen.dart';
import '../widgets/swadisht_customize_order_bottom_sheet.dart';
import '../services/api_service.dart';
// ─────────────────────────────────────────────────────────────
//  RestaurantMenuScreen
// ─────────────────────────────────────────────────────────────
class RestaurantMenuScreen extends StatefulWidget {
  final SwadistRestaurant restaurant;
  const RestaurantMenuScreen({super.key, required this.restaurant});

  @override
  State<RestaurantMenuScreen> createState() => RestaurantMenuScreenState();
}

class RestaurantMenuScreenState extends State<RestaurantMenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  String _selectedCategory = 'Recommended';
  bool _showWhyLoveCard = true;

  final List<String> _tabs = ['Menu', 'Photos', 'About', 'Reviews'];
  final List<String> _categories = [
    'Recommended',
    'Curries',
    'Rice & Breads',
    'Seafood',
    'Desserts',
  ];

  // Key to scroll to the menu section when "View Menu" is tapped
  final GlobalKey _menuHeaderKey = GlobalKey();

  List<SwadishMenuItem> _liveMenuItems = [];
  bool _isLoadingMenu = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _scrollController = ScrollController();
    _fetchLiveMenu(); // <-- Fetch Live Data on Load
  }

  Future<void> _fetchLiveMenu() async {
    try {
      final data = await ApiService.getFoodItems(forceRefresh: true);
      if (data.isNotEmpty) {
        final List<SwadishMenuItem> parsed = data.map((json) {
          return SwadishMenuItem(
            id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
            name: json['name']?.toString() ?? 'Food Item',
            description: json['description']?.toString() ?? '',
            price: (json['price'] != null) ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
            imageUrl: json['image_url']?.toString() ?? json['image']?.toString() ?? 'assets/Swadishtt/burger.png',
            isVeg: json['is_veg'] ?? json['isVeg'] ?? true,
          );
        }).toList();
        if (mounted) {
          setState(() {
            _liveMenuItems = parsed;
            _isLoadingMenu = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoadingMenu = false);
      }
    } catch (e) {
      debugPrint("Menu API Fetch failed, using fallback data: \$e");
      if (mounted) setState(() => _isLoadingMenu = false);
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<SwadishMenuItem> get _filteredItems {
    // 🔥 LIVE DATA PRIORITY WITH LOCAL FALLBACK
    final all = _liveMenuItems.isNotEmpty ? _liveMenuItems : widget.restaurant.menuItems;

    List<SwadishMenuItem> filtered;
    if (_selectedCategory == 'Recommended') {
      filtered = all;
    } else if (_selectedCategory == 'Curries') {
      filtered = all.where((item) {
        final name = item.name.toLowerCase();
        final desc = item.description.toLowerCase();
        return name.contains('curry') ||
            name.contains('sukka') ||
            name.contains('gravy') ||
            name.contains('masala') ||
            name.contains('roast') ||
            desc.contains('curry');
      }).toList();
      if (filtered.isEmpty) filtered = all.take(3).toList();
    } else if (_selectedCategory == 'Rice & Breads') {
      filtered = all.where((item) {
        final name = item.name.toLowerCase();
        final desc = item.description.toLowerCase();
        return name.contains('rice') ||
            name.contains('dosa') ||
            name.contains('roti') ||
            name.contains('naan') ||
            name.contains('biryani') ||
            name.contains('bread') ||
            desc.contains('rice');
      }).toList();
      if (filtered.isEmpty) filtered = all.skip(1).take(3).toList();
    } else if (_selectedCategory == 'Seafood') {
      filtered = all.where((item) {
        final name = item.name.toLowerCase();
        final desc = item.description.toLowerCase();
        return name.contains('fish') ||
            name.contains('prawn') ||
            name.contains('crab') ||
            name.contains('sea') ||
            desc.contains('fish') ||
            desc.contains('prawn') ||
            desc.contains('coastal');
      }).toList();
      if (filtered.isEmpty) {
        filtered = all.where((item) => !item.isVeg).toList();
      }
    } else {
      // Desserts or others
      filtered = all.where((item) {
        final name = item.name.toLowerCase();
        return name.contains('sweet') ||
            name.contains('dessert') ||
            name.contains('ice') ||
            name.contains('halwa') ||
            name.contains('kheer');
      }).toList();
      if (filtered.isEmpty) filtered = all.take(2).toList();
    }

    return filtered;
  }

  String _fmtCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  void _scrollToMenu() {
    final context = _menuHeaderKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final cart = context.watch<CartProvider>();
    final cartCount = cart.totalItemsCount;
    final items = _filteredItems;
    final popularItems = widget.restaurant.menuItems.take(5).toList();

    return PopScope(
      canPop: _tabController.index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // ── Scrollable content ──
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. Hero Image + Overlapping Info Panel + FSSAI Badge
              SliverToBoxAdapter(child: _buildHeroSection(r)),

              // 2. TabBar
              SliverToBoxAdapter(child: _buildTabBar()),

              ..._buildTabSlivers(r, cart, items, popularItems),
            ],
          ),

          // ── Pinned Top Navigation Buttons (Always visible) ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TopButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  Consumer<FavoriteRestaurantProvider>(
                    builder: (context, provider, child) {
                      final isFavorite = provider.isFavorite(widget.restaurant.id);
                      return _TopButton(
                        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                        iconColor: isFavorite ? const Color(0xFF9B111E) : Colors.black87,
                        onTap: () {
                          final favRest = FavoriteRestaurant(
                            id: widget.restaurant.id,
                            name: widget.restaurant.name,
                            cuisine: widget.restaurant.cuisine,
                            imageUrl: widget.restaurant.imageUrl,
                            rating: widget.restaurant.rating,
                          );
                          provider.toggleFavorite(favRest);
                          
                          if (!isFavorite) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${widget.restaurant.name} added to favourites!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Floating Bottom Bar ──
      bottomNavigationBar:
          cartCount > 0 ? _buildCartBar(cartCount, cart) : _buildDeliveryBar(r),
      ),
    );
  }

  List<Widget> _buildTabSlivers(
    SwadistRestaurant restaurant,
    CartProvider cart,
    List<SwadishMenuItem> items,
    List<SwadishMenuItem> popularItems,
  ) {
    if (_tabController.index != 0) {
      return [
        SliverToBoxAdapter(
          child: _buildSecondaryTab(_tabController.index, restaurant),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 105)),
      ];
    }

    return [
      SliverToBoxAdapter(
        key: _menuHeaderKey,
        child: _buildMenuHeader(),
      ),
      items.isEmpty
          ? const SliverToBoxAdapter(child: _buildEmptyState)
          : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildMenuItemCard(items[i], cart),
                  childCount: items.length,
                ),
              ),
            ),
      if (popularItems.isNotEmpty)
        SliverToBoxAdapter(child: _buildPopularDishes(popularItems)),
      if (_showWhyLoveCard) SliverToBoxAdapter(child: _buildWhyLoveCard()),
      SliverToBoxAdapter(child: _buildStoryAndRegionalCards()),
      SliverToBoxAdapter(child: _buildInsideKitchen(restaurant)),
      SliverToBoxAdapter(child: _buildFeedbackSection()),
      const SliverToBoxAdapter(child: SizedBox(height: 105)),
    ];
  }

  Widget _buildSecondaryTab(int tabIndex, SwadistRestaurant restaurant) {
    final title = _tabs[tabIndex];
    if (tabIndex == 1) {
      final images = [restaurant.imageUrl, ...restaurant.menuItems.map((item) => item.imageUrl)];
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(title, 'A closer look at ${restaurant.name}'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (_, index) => ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _itemImage(images[index], double.infinity, 150),
              ),
            ),
          ],
        ),
      );
    }

    if (tabIndex == 2) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('About ${restaurant.name}', 'Good food, thoughtfully prepared'),
            const SizedBox(height: 14),
            _infoPanel(Icons.restaurant, 'Cuisine', restaurant.cuisine),
            _infoPanel(Icons.schedule, 'Delivery', '${restaurant.deliveryTime}-${restaurant.deliveryTime + 5} minutes'),
            _infoPanel(Icons.verified_outlined, 'Trust', 'FSSAI verified and regularly inspected kitchen'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Reviews', '${restaurant.rating.toStringAsFixed(1)} average rating'),
          const SizedBox(height: 14),
          _buildReviewCard(const _Review(
            name: 'Ananya R.',
            rating: 5.0,
            time: '2 days ago',
            text: 'Super fresh prawns and the perfect balance of spices. Loved it.',
            dish: 'Prawn Ghee Roast',
          )),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      );

  Widget _infoPanel(IconData icon, String label, String value) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0EAE1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD32F2F)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(value, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildHeroSection(SwadistRestaurant r) {
    final logoText =
        r.name.split(' ').take(2).map((w) => w.toUpperCase()).join('\n');
    final ratingStr = _fmtCount(r.ratingCount);

    return Stack(
      children: [
        // 1. Cover Image (Positioned to sit behind)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _itemImage(r.imageUrl, double.infinity, 250),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. White Content Card
        Container(
          margin: const EdgeInsets.only(top: 218), // Overlaps image by 32px
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Text Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 88 + 16), // Space for logo + gap
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.cuisine,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        color: Color(0xFFFFC107), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      r.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '($ratingStr ratings)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Container(
                                        width: 1,
                                        height: 12,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    Icon(Icons.access_time_filled,
                                        size: 13, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${r.deliveryTime}–${r.deliveryTime + 5} mins',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1A1A),
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
                  ),
                  // Floating Logo
                  Positioned(
                    left: 20,
                    top: -24,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A0C24), // deep rich maroon
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.park_rounded,
                              color: Color(0xFFFFC107), size: 32),
                          const SizedBox(height: 2),
                          Text(
                            logoText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // FSSAI & Hygienic Kitchen Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTrustBadges(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FSSAI & HYGIENIC KITCHEN TRUST BADGES
  // ─────────────────────────────────────────────────────────────
  Widget _buildTrustBadges() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE5E1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: FSSAI Verified
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_good_outlined,
                    size: 22, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'FSSAI Verified',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'License No. 21223012045',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: Hygienic Kitchen
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.eco_outlined,
                    size: 22, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Hygienic Kitchen',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Regularly Inspected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
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

  // ─────────────────────────────────────────────────────────────
  // 2. TAB BAR (Menu / Photos / About / Reviews)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFD32F2F),
        unselectedLabelColor: const Color(0xFF666666),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicatorColor: const Color(0xFFD32F2F),
        indicatorWeight: 2.5,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
        onTap: (_) => setState(() {}),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. MENU HEADER & CATEGORY PILLS
  // ─────────────────────────────────────────────────────────────
  Widget _buildMenuHeader() {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _tabController.animateTo(0);
                  setState(() {});
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMenu());
                },
                child: const Row(
                  children: [
                    Text(
                      'View Full Menu',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward,
                        size: 11, color: Color(0xFFD32F2F)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final sel = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFD32F2F) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFFDCDCDC),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                          color: sel ? Colors.white : const Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const Widget _buildEmptyState = Padding(
    padding: EdgeInsets.all(40),
    child: Center(
      child: Text(
        'No dishes found in this category',
        style: TextStyle(color: Colors.grey, fontSize: 13),
      ),
    ),
  );

  // ─────────────────────────────────────────────────────────────
  // 4. MENU ITEM CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildMenuItemCard(SwadishMenuItem item, CartProvider cart) {
    final cartProduct = _toProduct(item);
    final qty = cart.getQuantity(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EAE1), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dish Image
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SwadishtFoodDetailScreen(product: cartProduct),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _itemImage(item.imageUrl, 80, 80),
              ),
            ),
            const SizedBox(width: 12),
            // Dish Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      item.isVeg
                          ? _vegDot()
                          : const Text('🌶️🌶️',
                              style: TextStyle(fontSize: 10.5)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade500,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      qty > 0
                          ? _QtyControl(
                              qty: qty,
                              onIncrease: () => cart.addItem(cartProduct),
                              onDecrease: () => cart.decreaseQuantity(item.id),
                            )
                          : _AddBtn(
                              onTap: () {
                                SwadishtCustomizeOrderBottomSheet.show(
                                  context,
                                  itemName: item.name,
                                  basePrice: item.price,
                                  itemImage: item.imageUrl,
                                );
                              },
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. POPULAR DISHES (Horizontal Scroll)
  // ─────────────────────────────────────────────────────────────
  Widget _buildPopularDishes(List<SwadishMenuItem> items) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 0, 18),
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Dishes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward,
                          size: 11, color: Color(0xFFD32F2F)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 188,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (ctx, i) => _buildPopularCard(items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCard(SwadishMenuItem item) {
    final fakeRating = '4.${(item.id % 3) + 6}';
    final fakeOrders = 456 + (item.id % 500);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SwadishtFoodDetailScreen(product: _toProduct(item)),
        ),
      ),
      child: Container(
        width: 154,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0EAE1), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: SizedBox(
                height: 112,
                width: double.infinity,
                child: _itemImage(item.imageUrl, 154, 112),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFFC107), size: 11),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '$fakeRating | $fakeOrders orders',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      // Veg or Non-Veg square dot
                      item.isVeg ? _vegSquareBadge() : _nonVegSquareBadge(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. WHY YOU'LL LOVE THIS DISH (Promo Card)
  // ─────────────────────────────────────────────────────────────
  Widget _buildWhyLoveCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EAE1), width: 1.2),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF0F0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome,
                                size: 14, color: Color(0xFFD32F2F)),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Why you'll love this dish",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Coastal favourite • Medium spicy\nHighly rated by customers',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text(
                            'Try this',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward,
                              size: 11, color: Color(0xFFD32F2F)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Dish image in circular pan shape
                ClipRRect(
                  borderRadius: BorderRadius.circular(37),
                  child: SizedBox(
                    width: 74,
                    height: 74,
                    child: _itemImage(widget.restaurant.imageUrl, 74, 74),
                  ),
                ),
              ],
            ),
          ),
          // Close button at top right
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => setState(() => _showWhyLoveCard = false),
              child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 7. KITCHEN STORY & REGIONAL FLAVOURS (Side by Side)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStoryAndRegionalCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  icon: Icons.soup_kitchen_outlined,
                  iconBg: const Color(0xFFFFF4EC),
                  iconColor: const Color(0xFFE65100),
                  title: 'Kitchen Story',
                  subtitle: 'Coastal recipes, made with tradition.',
                  cta: 'Our Story',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoCard(
                  icon: Icons.workspace_premium_outlined,
                  iconBg: const Color(0xFFFCE4EC),
                  iconColor: const Color(0xFFC2185B),
                  title: 'Regional Flavours',
                  subtitle: 'Authentic flavours from the Mangalorean coast.',
                  cta: 'Explore',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Small centered divider handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String cta,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EAE1), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              color: Colors.grey.shade500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                cta,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward,
                  size: 9, color: Color(0xFFD32F2F)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 8. INSIDE THE KITCHEN (Horizontal Card)
  // ─────────────────────────────────────────────────────────────
  Widget _buildInsideKitchen(SwadistRestaurant r) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EAE1), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.soup_kitchen_outlined,
                          size: 16, color: Color(0xFFD32F2F)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Inside the Kitchen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Verified hygiene • Fresh preparation',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text(
                      'See More',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward,
                        size: 11, color: Color(0xFFD32F2F)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Kitchen Photo on the right
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 95,
              height: 72,
              child: _itemImage(r.imageUrl, 95, 72),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 9. WHAT PEOPLE SAY (Feedback / Reviews)
  // ─────────────────────────────────────────────────────────────
  Widget _buildFeedbackSection() {
    final reviews = [
      const _Review(
        name: 'Ananya R.',
        rating: 5.0,
        time: '2 days ago',
        text: 'Super fresh prawns and the perfect balance of spices. Loved it.',
        dish: 'Prawn Ghee Roast',
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'What people say (Feedback)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward,
                        size: 11, color: Color(0xFFD32F2F)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...reviews.map(_buildReviewCard),
        ],
      ),
    );
  }

  Widget _buildReviewCard(_Review rev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EAE1), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade200,
                    child:
                        const Icon(Icons.person, color: Colors.grey, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rev.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        rev.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFC107), size: 13),
                  const SizedBox(width: 2),
                  Text(
                    rev.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${rev.text}"',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              rev.dish,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD32F2F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 10. BOTTOM FLOATING BARS (Delivery Bar / Cart Bar)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCartBar(int count, CartProvider cart) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count item${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const Text(
                'View Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Text(
                '₹${cart.subtotal.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryBar(SwadistRestaurant r) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.moped_outlined,
                      color: Color(0xFFD32F2F), size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.deliveryTime}–${r.deliveryTime + 5} mins',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Delivery time',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: _scrollToMenu,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Text(
                      'View Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 13),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS & SUB-WIDGETS
  // ─────────────────────────────────────────────────────────────
  Product _toProduct(SwadishMenuItem item) => Product(
        id: item.id,
        name: item.name,
        price: item.price,
        imageUrl: item.imageUrl,
        category: 'Swadisht',
        description: item.description,
        emoji: '',
        isVeg: item.isVeg,
      );

  Widget _itemImage(String url, double w, double h) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgPlaceholder(w, h),
      );
    }
    return Image.asset(
      url,
      width: w,
      height: h,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imgPlaceholder(w, h),
    );
  }

  Widget _imgPlaceholder([double? w, double? h]) => Container(
        width: w,
        height: h,
        color: const Color(0xFFFFEFE6),
        child: const Icon(Icons.restaurant,
          size: 36, color: AppColors.swadistPrimary),
      );

  Widget _vegDot() => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Icon(Icons.circle, color: Color(0xFF2E7D32), size: 7),
      );

  Widget _vegSquareBadge() => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Icon(Icons.circle, color: Color(0xFF2E7D32), size: 7),
      );

  Widget _nonVegSquareBadge() => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD32F2F), width: 1.2),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Icon(Icons.circle, color: Color(0xFFD32F2F), size: 7),
      );
}

// ─────────────────────────────────────────────────────────────
// Simple Review Model
// ─────────────────────────────────────────────────────────────
class _Review {
  final String name, time, text, dish;
  final double rating;
  const _Review({
    required this.name,
    required this.rating,
    required this.time,
    required this.text,
    required this.dish,
  });
}

// ─────────────────────────────────────────────────────────────
// Stepper Qty Control Widget
// ─────────────────────────────────────────────────────────────
class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _QtyControl({
    required this.qty,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onDecrease,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.remove, color: Colors.white, size: 14),
              ),
            ),
            Text(
              '$qty',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            InkWell(
              onTap: onIncrease,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.add, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// +Add Button Widget
// ─────────────────────────────────────────────────────────────
class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '+Add',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Floating Top Icon Button
// ─────────────────────────────────────────────────────────────
class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _TopButton({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFF1A1A1A), size: 20),
        ),
      );
}
