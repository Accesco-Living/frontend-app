import 'package:accesco_living_app/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/app_colors.dart';

class SmartDish {
  final int id;
  final String name;
  final String restaurant;
  final String reason;
  final String imageUrl;
  final double price;
  final List<String> tags;
  final bool isVeg;

  const SmartDish({
    required this.id,
    required this.name,
    required this.restaurant,
    required this.reason,
    required this.imageUrl,
    required this.price,
    required this.tags,
    required this.isVeg,
  });
}

class SmartMenuDiscoveryScreen extends StatefulWidget {
  const SmartMenuDiscoveryScreen({super.key});

  @override
  State<SmartMenuDiscoveryScreen> createState() =>
      _SmartMenuDiscoveryScreenState();
}

class _SmartMenuDiscoveryScreenState extends State<SmartMenuDiscoveryScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Set<int> _savedDishIds = {};
  final Set<int> _skippedDishIds = {};

  static const List<SmartDish> _dishes = [
    SmartDish(
      id: 6101,
      name: 'Butter Chicken Dinner Bowl',
      restaurant: 'Swadishtt Picks',
      reason: 'Dinner comfort pick based on your North Indian taste.',
      imageUrl:
          'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=900&fit=crop',
      price: 289,
      tags: ['Dinner', 'Comfort', 'Popular'],
      isVeg: false,
    ),
    SmartDish(
      id: 6102,
      name: 'Masala Dosa with Filter Coffee',
      restaurant: 'South Soul Kitchen',
      reason: 'Light, crisp and fast when you want something familiar.',
      imageUrl:
          'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=900&fit=crop',
      price: 159,
      tags: ['Breakfast', 'Crispy', 'Veg'],
      isVeg: true,
    ),
    SmartDish(
      id: 6103,
      name: 'Hyderabadi Chicken Biryani',
      restaurant: 'Dum House',
      reason: 'Trending near you and good for high-craving orders.',
      imageUrl:
          'https://images.unsplash.com/photo-1701579231305-d84d8af9a3fd?w=900&fit=crop',
      price: 269,
      tags: ['Trending', 'Spicy', 'Dum'],
      isVeg: false,
    ),
    SmartDish(
      id: 6104,
      name: 'Paneer Butter Masala Combo',
      restaurant: 'Tandoor Story',
      reason: 'Rich veg combo with naan when you want a filling meal.',
      imageUrl:
          'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=900&fit=crop',
      price: 249,
      tags: ['Veg', 'Creamy', 'Combo'],
      isVeg: true,
    ),
    SmartDish(
      id: 6105,
      name: 'Macher Jhol Rice Plate',
      restaurant: 'Bengal Table',
      reason: 'Regional soul pick with rice, mustard and homestyle curry.',
      imageUrl:
          'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=900&fit=crop',
      price: 299,
      tags: ['Regional', 'Rice', 'Fish'],
      isVeg: false,
    ),
    SmartDish(
      id: 6106,
      name: 'Gujarati Kadhi Khichdi',
      restaurant: 'Thali Engine',
      reason: 'Balanced, warm and easy for a no-confusion lunch.',
      imageUrl:
          'https://images.unsplash.com/photo-1626776876729-bab4369a5a5a?w=900&fit=crop',
      price: 179,
      tags: ['Lunch', 'Balanced', 'Veg'],
      isVeg: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().totalItemsCount;
    final currentDish = _dishes[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _dishes.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (_, index) => _SmartDishReelCard(dish: _dishes[index]),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _RoundActionButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Smart Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    _RoundActionButton(
                      icon: Icons.shopping_cart_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 138,
            child: Column(
              children: [
                _VerticalReelAction(
                  icon: _savedDishIds.contains(currentDish.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: 'Save',
                  active: _savedDishIds.contains(currentDish.id),
                  onTap: () => setState(() {
                    if (_savedDishIds.contains(currentDish.id)) {
                      _savedDishIds.remove(currentDish.id);
                    } else {
                      _savedDishIds.add(currentDish.id);
                    }
                  }),
                ),
                const SizedBox(height: 14),
                _VerticalReelAction(
                  icon: Icons.close,
                  label: 'Skip',
                  active: _skippedDishIds.contains(currentDish.id),
                  onTap: _skipCurrent,
                ),
                const SizedBox(height: 14),
                _VerticalReelAction(
                  icon: Icons.add_shopping_cart,
                  label: 'Add',
                  active: false,
                  onTap: () => _addDish(currentDish),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _skipCurrent() {
    final currentDish = _dishes[_currentIndex];
    setState(() => _skippedDishIds.add(currentDish.id));
    if (_currentIndex < _dishes.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _addDish(SmartDish dish) {
    context.read<CartProvider>().addItem(
          Product(
            id: dish.id,
            name: dish.name,
            description: '${dish.reason} From ${dish.restaurant}.',
            price: dish.price,
            category: 'Swadisht Smart Menu',
            emoji: '',
            imageUrl: dish.imageUrl,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${dish.name} added!'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF388E3C),
      ),
    );
  }
}

class _SmartDishReelCard extends StatelessWidget {
  final SmartDish dish;

  const _SmartDishReelCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          dish.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF171719),
            child:
                const Icon(Icons.restaurant, color: Colors.white24, size: 72),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.42),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.88),
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 82,
          bottom: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _VegMark(isVeg: dish.isVeg),
                  const SizedBox(width: 8),
                  Text(
                    dish.restaurant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dish.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dish.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TagChip(label: 'Rs ${dish.price.toStringAsFixed(0)}'),
                  ...dish.tags.map((tag) => _TagChip(label: tag)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.48),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _VerticalReelAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _VerticalReelAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.swadistPrimary
                  : Colors.black.withValues(alpha: 0.50),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VegMark extends StatelessWidget {
  final bool isVeg;

  const _VegMark({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? Colors.greenAccent.shade400 : Colors.redAccent;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
