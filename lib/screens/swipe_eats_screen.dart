import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../utils/app_colors.dart';
import 'dart:ui';
import '../models/products_data.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';
import 'swadisht_screen.dart';
import 'cart_screen.dart';

class SwipeDish {
  final String id;
  final String name;
  final String restaurantName;
  final String restaurantLocation;
  final String description;
  final String hashtags;
  final String imageUrl;
  final double rating;
  final int reviews;
  final double price;
  final double originalPrice;
  final String deliveryTime;
  final String likes;
  final bool isVeg;

  SwipeDish({
    required this.id,
    required this.name,
    required this.restaurantName,
    required this.restaurantLocation,
    required this.description,
    required this.hashtags,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.originalPrice,
    required this.deliveryTime,
    required this.likes,
    required this.isVeg,
  });
}

class SwipeEatsScreen extends StatefulWidget {
  const SwipeEatsScreen({super.key});

  @override
  State<SwipeEatsScreen> createState() => _SwipeEatsScreenState();
}

class _SwipeEatsScreenState extends State<SwipeEatsScreen> {
  List<SwipeDish> _allDishes = [];
  List<SwipeDish> _currentDishes = [];
  String _selectedTab = 'All';

  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  static const Color _bgPink = Color(0xFFFFF4F4); // app header/bg peach
  static const Color _cardInfoBg = Color(0xFFFFEBEB); // card info pink
  static const Color _redTheme = Color(0xFFE13D3D); // coral red
  static const Color _arrowGrey = Color(0xFFB9B9B9); // swipe hint arrows

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  void _loadDishes() {
    _allDishes = ProductsData.activeFoodProducts.map((product) {
      final String cat = product.category;
      final String capCat =
          cat.isNotEmpty ? cat[0].toUpperCase() + cat.substring(1) : 'Food';
      return SwipeDish(
        id: product.id.toString(),
        name: product.name,
        restaurantName: 'The $capCat House',
        restaurantLocation: 'Mumbai',
        description: product.description,
        hashtags: product.tags != null ? product.tags!.map((t) => '#$t').join(' ') : '',
        imageUrl: product.imageUrl ?? '',
        rating: 4.5,
        reviews: 1000,
        price: product.price.toDouble(),
        originalPrice: (product.price * 1.2).toDouble(),
        deliveryTime: '30 mins',
        likes: '',
        isVeg: product.isVeg,
      );
    }).toList();
    _allDishes.shuffle();
    _currentDishes = List.from(_allDishes);

    _listenLiveFirestoreDishes();
  }

  void _listenLiveFirestoreDishes() {
    FirebaseService.getFoodItemsStream().listen((items) {
      if (items.isNotEmpty && mounted) {
        final liveList = items.map((data) {
          final name = data['name']?.toString() ?? 'Delicious Dish';
          final desc = data['description']?.toString() ?? '';
          final price = (data['price'] as num?)?.toDouble() ?? 199.0;
          final isVeg = data['isVeg'] == true;
          final img = data['imageUrl']?.toString() ?? '';
          return SwipeDish(
            id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            restaurantName: data['restaurantName']?.toString() ?? 'Swadishtt Special',
            restaurantLocation: 'Bengaluru',
            description: desc,
            hashtags: '#Swadishtt #Delicious',
            imageUrl: img,
            rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
            reviews: 500,
            price: price,
            originalPrice: price * 1.25,
            deliveryTime: '25 mins',
            likes: '1.2k',
            isVeg: isVeg,
          );
        }).toList();

        setState(() {
          final Set<String> existingIds = liveList.map((e) => e.id).toSet();
          _allDishes = [
            ...liveList,
            ..._allDishes.where((d) => !existingIds.contains(d.id)),
          ];
          _setTab(_selectedTab);
        });
      }
    });
  }

  void _setTab(String tab) {
    setState(() {
      _selectedTab = tab;
      if (tab == 'Pure-Veg') {
        _currentDishes = _allDishes.where((d) => d.isVeg).toList();
      } else {
        _currentDishes = List.from(_allDishes);
      }
      _currentIndex = 0;
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  void _nextCard() {
    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
      if (_currentIndex < _currentDishes.length - 1) {
        _currentIndex++;
      }
    });
  }

  void _addToCartAndNext() {
    final dish = _currentDishes[_currentIndex];
    final provider = context.read<CartProvider>();

    // Find the original product from ProductsData
    final product = ProductsData.getAllProducts().firstWhere(
      (p) => p.id.toString() == dish.id,
      orElse: () => Product(
        id: int.parse(dish.id),
        name: dish.name,
        description: dish.description,
        price: dish.price,
        category: 'Food',
        emoji: '🍽️',
        imageUrl: dish.imageUrl,
        isVeg: dish.isVeg,
      ),
    );

    provider.addItem(product);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${dish.name} added to cart!'),
      duration: const Duration(seconds: 1),
      backgroundColor: _redTheme,
    ));
    _nextCard();
  }

  void _triggerSwipe(bool right) {
    setState(() {
      _dragOffset = Offset(right ? 400 : -400, 0);
      _isDragging = false;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (right) {
        _addToCartAndNext();
      } else {
        _nextCard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPink,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabs(),
            _buildFilters(),
            const SizedBox(height: 16),
            _buildRemainingBadge(),
            const SizedBox(height: 16),

            // Card Stack Area
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Bottom-most card (index + 2)
                  if (_currentIndex < _currentDishes.length - 2)
                    Transform.translate(
                      offset: const Offset(0, 36),
                      child: Transform.scale(
                        scale: 0.90,
                        child: Transform.rotate(
                          angle: -0.06,
                          child: _buildCard(_currentDishes[_currentIndex + 2]),
                        ),
                      ),
                    ),

                  // Middle background card (index + 1)
                  if (_currentIndex < _currentDishes.length - 1)
                    Transform.translate(
                      offset: const Offset(0, 18),
                      child: Transform.scale(
                        scale: 0.95,
                        child: Transform.rotate(
                          angle: 0.06, // Tilted slightly to the right
                          child: _buildCard(_currentDishes[_currentIndex + 1]),
                        ),
                      ),
                    ),

                  // ── Left swipe hint (arrow + dislike button) ─────────────
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 150,
                            child: CustomPaint(painter: _SwipeArrowPainter()),
                          ),
                          const SizedBox(height: 12),
                          _buildSideButton(
                            icon: Icons.close,
                            onTap: () => _triggerSwipe(false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Right swipe hint (arrow + add-to-cart button) ──
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 150,
                            child: CustomPaint(
                                painter: _SwipeArrowPainter(mirrored: true)),
                          ),
                          const SizedBox(height: 12),
                          _buildSideButton(
                            icon: Icons.shopping_cart_outlined,
                            onTap: () => _triggerSwipe(true),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Current Card (foreground)
                  if (_currentIndex < _currentDishes.length)
                    GestureDetector(
                      onPanStart: (details) =>
                          setState(() => _isDragging = true),
                      onPanUpdate: (details) {
                        setState(() {
                          _dragOffset += details.delta;
                        });
                      },
                      onPanEnd: (details) {
                        if (_dragOffset.dx > 100) {
                          setState(() {
                            _dragOffset = Offset(
                                MediaQuery.of(context).size.width + 200,
                                _dragOffset.dy);
                          });
                          Future.delayed(const Duration(milliseconds: 250), () {
                            if (mounted) _addToCartAndNext();
                          });
                        } else if (_dragOffset.dx < -100) {
                          setState(() {
                            _dragOffset = Offset(
                                -(MediaQuery.of(context).size.width + 200),
                                _dragOffset.dy);
                          });
                          Future.delayed(const Duration(milliseconds: 250), () {
                            if (mounted) _nextCard();
                          });
                        } else {
                          setState(() {
                            _isDragging = false;
                            _dragOffset = Offset.zero;
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: _isDragging
                            ? Duration.zero
                            : const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        transform: Matrix4.translationValues(
                            _dragOffset.dx, _dragOffset.dy, 0)
                          ..rotateZ(_dragOffset.dx / 1000),
                        child: Stack(
                          children: [
                            _buildCard(_currentDishes[_currentIndex]),
                            if (_dragOffset.dx > 0)
                              Positioned(
                                top: 40,
                                left: 30,
                                child: Opacity(
                                  opacity: (_dragOffset.dx / 50).clamp(0.0, 1.0),
                                  child: Transform.rotate(
                                    angle: -0.2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.green, width: 4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('ADD TO CART',
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              ),
                            if (_dragOffset.dx < 0)
                              Positioned(
                                top: 40,
                                right: 30,
                                child: Opacity(
                                  opacity: (-_dragOffset.dx / 50).clamp(0.0, 1.0),
                                  child: Transform.rotate(
                                    angle: 0.2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.red, width: 4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('NOPE',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text("You're all caught up!",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                          const SizedBox(height: 8),
                          Text("Try changing your filters or come back later.",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Controls
            const SizedBox(height: 24),
            _buildBottomControls(),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined, size: 16, color: Colors.black54),
                SizedBox(width: 8),
                Text('Swipe to discover more Dishes',
                    style: TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),

            // View Cart Button
            _buildViewCartButton(),
            const SizedBox(height: 16),

            // Bottom Nav
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Center(
        child: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'Swipe', style: TextStyle(color: _redTheme)),
              TextSpan(
                  text: 'Eats', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['All', 'Pure-Veg'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: tabs.map((t) {
            final isSelected = t == _selectedTab;
            return GestureDetector(
              onTap: () => _setTab(t),
              child: Container(
                margin: const EdgeInsets.only(right: 24),
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: isSelected ? _redTheme : Colors.transparent,
                          width: 2)),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.black54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['Sort', 'Price'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            return GestureDetector(
              onTap: () {
                if (f == 'Sort') {
                  _showSortOptions();
                } else if (f == 'Price') {
                  _showPriceOptions();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    if (f == 'Sort')
                      const Icon(Icons.swap_vert, size: 14, color: Colors.black87),
                    if (f == 'Sort') const SizedBox(width: 4),
                    Text(f,
                        style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down,
                        size: 16, color: Colors.black54),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Sort by',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Relevance'),
              _buildSortOption('Popularity'),
              _buildSortOption('Price low to high'),
              _buildSortOption('Price high to low'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pop(context);
        _applySort(label);
      },
    );
  }

  void _applySort(String option) {
    setState(() {
      if (option == 'Price low to high') {
        _currentDishes.sort((a, b) => a.price.compareTo(b.price));
      } else if (option == 'Price high to low') {
        _currentDishes.sort((a, b) => b.price.compareTo(a.price));
      } else if (option == 'Popularity') {
        _currentDishes.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (option == 'Relevance') {
        if (_selectedTab == 'Pure-Veg') {
          _currentDishes = _allDishes.where((d) => d.isVeg).toList();
        } else {
          _currentDishes = List.from(_allDishes);
        }
      }
      _currentIndex = 0;
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }


  void _showPriceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Price Range',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
              const SizedBox(height: 16),
              _buildPriceOption('All Prices', 0, double.infinity),
              _buildPriceOption('₹0 - ₹100', 0, 100),
              _buildPriceOption('₹100 - ₹200', 100, 200),
              _buildPriceOption('₹200 - ₹300', 200, 300),
              _buildPriceOption('₹300 - ₹400', 300, 400),
              _buildPriceOption('₹400 - ₹500', 400, 500),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceOption(String label, double minPrice, double maxPrice) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pop(context);
        _applyPriceFilter(minPrice, maxPrice);
      },
    );
  }

  void _applyPriceFilter(double minPrice, double maxPrice) {
    setState(() {
      List<SwipeDish> baseList = _selectedTab == 'Pure-Veg'
          ? _allDishes.where((d) => d.isVeg).toList()
          : List.from(_allDishes);

      _currentDishes = baseList.where((d) => d.price >= minPrice && d.price <= maxPrice).toList();
      _currentIndex = 0;
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  Widget _buildRemainingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _bgPink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _redTheme.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('${_currentDishes.length - _currentIndex} remaining',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCard(SwipeDish dish) {
    List<String> tags = dish.hashtags.isNotEmpty ? dish.hashtags.split(' ') : [];
    List<String> pillTags = tags.length > 2 ? tags.sublist(2) : [];
    List<String> topTags = tags.length > 2 ? tags.sublist(0, 2) : tags;

    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.height * 0.52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image part
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: CachedNetworkImage(
                    imageUrl: dish.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: Icon(Icons.fastfood, color: Colors.grey, size: 40)),
                  ),
                ),
                if (topTags.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: topTags.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildTag(t.replaceAll('#', '').toUpperCase(), _redTheme, Colors.white),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
          // Info part
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _cardInfoBg,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // size to content
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dish.restaurantName.toUpperCase(),
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                    const Icon(Icons.favorite_border,
                        size: 20, color: Colors.black54),
                  ],
                ),
                const SizedBox(height: 4),
                Text(dish.name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('₹${dish.price.toInt()}',
                        style: const TextStyle(
                            color: _redTheme,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    if (dish.isVeg) ...[
                      const Icon(Icons.circle, color: Colors.green, size: 10),
                      const SizedBox(width: 4),
                      Text('Veg', style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                    ],
                    Text(dish.deliveryTime,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                if (pillTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pillTags.map((t) => _buildPillTag(t.replaceAll('#', '').toUpperCase())).toList(),
                  )
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTag(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: bg == _redTheme
            ? Border.all(color: Colors.white, width: 1.5)
            : null,
      ),
      child: Text(text,
          style: TextStyle(
              color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPillTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5D6DA), // slightly darker pink
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Color(0xFF9A1B22), // darker red text
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSideButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: _redTheme.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: _redTheme, size: 24),
      ),
    );
  }

  Widget _buildNeumorphicButton({
    required IconData icon,
    required double size,
    required double padding,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: size, color: Colors.black),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      decoration: BoxDecoration(
        color: _bgPink,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: _redTheme.withValues(alpha: 0.15)),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNeumorphicButton(
            icon: Icons.close,
            size: 28,
            padding: 16,
            onTap: () => _triggerSwipe(false),
          ),
          const SizedBox(width: 24),
          _buildNeumorphicButton(
            icon: Icons.undo,
            size: 24,
            padding: 12,
            onTap: () {},
          ),
          const SizedBox(width: 24),
          _buildNeumorphicButton(
            icon: Icons.check,
            size: 28,
            padding: 16,
            onTap: () => _triggerSwipe(true),
          ),
        ],
      ),
    );
  }

  void _showCartScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  Widget _buildViewCartButton() {
    final cartProvider = context.watch<CartProvider>();
    final hasItems = cartProvider.items.isNotEmpty;
    final lastImageUrl =
        hasItems && cartProvider.items.last.product.imageUrl != null
            ? cartProvider.items.last.product.imageUrl!
            : '';

    return GestureDetector(
      onTap: _showCartScreen,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _bgPink,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _redTheme.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade300,
              ),
              clipBehavior: Clip.hardEdge,
              child: hasItems && lastImageUrl.isNotEmpty
                  ? Image.network(lastImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.fastfood, size: 16))
                  : const Icon(Icons.fastfood, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('View Cart',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${cartProvider.totalItemsCount} items',
                    style: const TextStyle(color: _redTheme, fontSize: 11)),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4)
                ],
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  size: 12, color: Colors.black),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final int cartCount = context.watch<CartProvider>().totalItemsCount;
    const int currentIndex = 3; // Reels is active

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── Floating Logo Button ──
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context); // Go back home
              },
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBA1B68), Color(0xFF8C0B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBA1B68).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      'assets/Swadishtt/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Floating Glass Pill ──
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.09),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCustomNavItem(
                            0, Icons.home_outlined, 'Home', currentIndex),
                        _buildCustomNavItem(1, Icons.shopping_bag_outlined,
                            'Order', currentIndex),
                        _buildCustomCartNavItem(2, cartCount, currentIndex),
                        _buildCustomNavItem(
                            3, Icons.movie_outlined, 'Feed', currentIndex),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavItem(
      int index, IconData icon, String label, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (index != 3) {
          Navigator.pop(context);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 24,
                color:
                    isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color:
                    isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade600,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 3,
              width: isSelected ? 14 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFFBA1B68),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCartNavItem(int index, int cartCount, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showCartScreen();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: 24,
                    color: isSelected
                        ? const Color(0xFF1A1A1A)
                        : Colors.grey.shade600,
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Container(
                        key: ValueKey<int>(cartCount),
                        padding: const EdgeInsets.all(3),
                        constraints:
                            const BoxConstraints(minWidth: 17, minHeight: 17),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC1111),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFCC1111)
                                  .withValues(alpha: 0.45),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          '$cartCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color:
                    isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade600,
              ),
              child: const Text('Cart'),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 3,
              width: isSelected ? 14 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFFBA1B68),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a curved dashed swipe-hint arrow with an arrowhead.
class _SwipeArrowPainter extends CustomPainter {
  final bool mirrored;
  _SwipeArrowPainter({this.mirrored = false});

  @override
  void paint(Canvas canvas, Size size) {
    const c = Color(0xFFB9B9B9);
    final w = size.width;
    final h = size.height;

    // Curve from the top (card side) down to the bottom (button side).
    final start = Offset(mirrored ? w * 0.2 : w * 0.8, 0);
    final ctrl = Offset(mirrored ? w * 1.05 : -w * 0.05, h * 0.55);
    final end = Offset(mirrored ? w * 0.72 : w * 0.28, h);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

    final dash = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      final len = metric.length;
      double distance = 0;
      while (distance < len) {
        final a = metric.getTangentForOffset(distance)!.position;
        final b = metric.getTangentForOffset(distance + 6.0)!.position;
        canvas.drawLine(a, b, dash);
        distance += 12.0;
      }

      // Arrowhead pointing toward the button.
      final t = metric.getTangentForOffset(len)!;
      final tip = t.position;
      final dir = t.vector;
      final norm = Offset(-dir.dy, dir.dx);
      final base = tip - Offset(dir.dx, dir.dy) * 16.0;
      final fill = Paint()..color = c;
      final tri = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx + norm.dx * 7.0, base.dy + norm.dy * 7.0)
        ..lineTo(base.dx - norm.dx * 7.0, base.dy - norm.dy * 7.0)
        ..close();
      canvas.drawPath(tri, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _SwipeArrowPainter oldDelegate) =>
      oldDelegate.mirrored != mirrored;
}
