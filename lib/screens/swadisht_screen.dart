import 'dart:async';
import 'dart:ui';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/location_service.dart';
import 'package:accesco_living_app/screens/instant_catering_screen.dart'
    show InstantCateringPage;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/bookmark_provider.dart';
import '../providers/favorite_restaurant_provider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import '../widgets/app_drawer.dart';
import 'cart_screen.dart';
import 'dinex_screen.dart';
import 'smart_menu_discovery_screen.dart';
import 'swipe_eats_screen.dart';
import 'category_products_screen.dart';
import 'all_categories_screen.dart';
import 'payment_screen.dart';
import 'swadisht_orders_screen.dart';
import 'swadisht_food_detail_screen.dart';
import '../widgets/swadisht_customize_order_bottom_sheet.dart';
import '../widgets/dish_details_popup.dart';
import '../models/products_data.dart';
import 'main_dashboard.dart';
import 'swadisht_profile_screen.dart';

// ─────────────────────────────────────────────
// Menu Item model — id is int to match CartProvider
// ─────────────────────────────────────────────
class SwadishMenuItem {
  final int id;
  final String name, description, imageUrl;
  final double price;
  final bool isVeg;

  const SwadishMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.isVeg,
  });
}

// ─────────────────────────────────────────────
// Restaurant model — now carries live Places data
// ─────────────────────────────────────────────
class SwadistRestaurant {
  final String id; // Google Place ID
  final String name, cuisine, imageUrl, offer;
  final double rating, distance; // distance in km from user
  final int ratingCount, deliveryTime;
  final bool isPureVeg, isPromoted;
  final List<SwadishMenuItem> menuItems;
  final double lat, lng; // restaurant coordinates

  SwadistRestaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.imageUrl,
    required this.rating,
    required this.ratingCount,
    required this.distance,
    required this.deliveryTime,
    required this.offer,
    required this.isPureVeg,
    required this.isPromoted,
    required this.menuItems,
    required this.lat,
    required this.lng,
  });
}

// ─────────────────────────────────────────────
// Food Category chip model
// ─────────────────────────────────────────────
class _FoodCategory {
  final String name, imageUrl;
  const _FoodCategory({required this.name, required this.imageUrl});
}

// ─────────────────────────────────────────────
// Google Places API removed — search bar is display-only
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// Cuisine-based menu generator
// Google Places API has no menu data — we generate
// realistic cuisine-appropriate items for each restaurant
// ─────────────────────────────────────────────
class _MenuGenerator {
  static int _idCounter =
      9000; // start high to avoid collision with other screens

  static List<SwadishMenuItem> generate(
      List<String> placeTypes, String restaurantName) {
    _idCounter += 10;
    final base = _idCounter;

    // Determine dominant cuisine from Google Places types
    if (_hasType(placeTypes, 'pizza_restaurant')) {
      return _pizzaMenu(base);
    } else if (_hasType(placeTypes, 'chinese_restaurant')) {
      return _chineseMenu(base);
    } else if (_hasType(placeTypes, 'south_indian_restaurant') ||
        restaurantName.toLowerCase().contains('dosa') ||
        restaurantName.toLowerCase().contains('idli') ||
        restaurantName.toLowerCase().contains('udupi')) {
      return _southIndianMenu(base);
    } else if (_hasType(placeTypes, 'north_indian_restaurant') ||
        restaurantName.toLowerCase().contains('dhaba') ||
        restaurantName.toLowerCase().contains('punjabi')) {
      return _northIndianMenu(base);
    } else if (_hasType(placeTypes, 'burger_restaurant') ||
        restaurantName.toLowerCase().contains('burger')) {
      return _burgerMenu(base);
    } else if (_hasType(placeTypes, 'biryani_restaurant') ||
        restaurantName.toLowerCase().contains('biryani') ||
        restaurantName.toLowerCase().contains('dum')) {
      return _biryaniMenu(base);
    } else if (_hasType(placeTypes, 'cafe') ||
        _hasType(placeTypes, 'coffee_shop') ||
        restaurantName.toLowerCase().contains('cafe') ||
        restaurantName.toLowerCase().contains('coffee')) {
      return _cafeMenu(base);
    } else if (_hasType(placeTypes, 'fast_food_restaurant')) {
      return _fastFoodMenu(base);
    } else {
      return _multiCuisineMenu(base);
    }
  }

  static bool _hasType(List<String> types, String type) =>
      types.any((t) => t.toLowerCase() == type.toLowerCase());

  static List<SwadishMenuItem> _biryaniMenu(int base) => [
        SwadishMenuItem(
          id: base,
          name: 'Chicken Dum Biryani',
          description:
              'Slow-cooked basmati rice layered with spiced chicken, saffron & caramelised onions',
          imageUrl:
              'https://images.unsplash.com/photo-1701579231305-d84d8af9a3fd?w=400&fit=crop',
          price: 249,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 1,
          name: 'Mutton Biryani',
          description:
              'Tender mutton pieces cooked in aromatic spices with long-grain basmati',
          imageUrl:
              'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&fit=crop',
          price: 319,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 2,
          name: 'Veg Dum Biryani',
          description:
              'Seasonal vegetables & paneer dum-cooked with fragrant basmati',
          imageUrl:
              'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&fit=crop',
          price: 189,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 3,
          name: 'Raita',
          description: 'Chilled yoghurt with cucumber, cumin & fresh coriander',
          imageUrl:
              'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&fit=crop',
          price: 59,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 4,
          name: 'Egg Biryani',
          description:
              'Perfectly boiled eggs layered in spiced rice with fresh herbs',
          imageUrl:
              'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400&fit=crop',
          price: 199,
          isVeg: false,
        ),
      ];

  static List<SwadishMenuItem> _southIndianMenu(int base) => [
        SwadishMenuItem(
          id: base,
          name: 'Masala Dosa',
          description:
              'Crisp golden dosa filled with spiced potato bhaji, served with sambar & chutneys',
          imageUrl:
              'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=400&fit=crop',
          price: 109,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 1,
          name: 'Idli Sambar (3 pcs)',
          description:
              'Steamed rice-lentil idlis with tangy sambar & coconut chutney',
          imageUrl:
              'https://images.unsplash.com/photo-1630383249896-424e482df921?w=400&fit=crop',
          price: 89,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 2,
          name: 'Rava Uttapam',
          description:
              'Thick semolina pancake topped with onion, tomato & green chilli',
          imageUrl:
              'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&fit=crop',
          price: 119,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 3,
          name: 'Chettinad Chicken Curry',
          description:
              'Fiery Chettinad-style chicken curry with freshly ground spices',
          imageUrl:
              'https://images.unsplash.com/photo-1598103442097-8b74394b95c8?w=400&fit=crop',
          price: 219,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 4,
          name: 'Filter Coffee',
          description:
              'Classic South Indian filter coffee with chicory, served in a dabarah-tumbler',
          imageUrl:
              'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&fit=crop',
          price: 49,
          isVeg: true,
        ),
      ];

  static List<SwadishMenuItem> _northIndianMenu(int base) => [
    SwadishMenuItem(
      id: base,
      name: 'Mangalorean Sukka',
      description: 'Tender Chicken cooked with roasted spices.',
      imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400&fit=crop',
      price: 260,
      isVeg: false, // Triggers your red chilli icons
    ),
    SwadishMenuItem(
      id: base + 1,
      name: 'Egg Curry',
      description: 'Traditional Mangalorean egg curry with spices.',
      imageUrl: 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=400&fit=crop',
      price: 259,
      isVeg: true, // Triggers your green veg dot
    ),
    SwadishMenuItem(
      id: base + 2,
      name: 'Neer Dosa (3 pcs)',
      description: 'Soft and delicate rice crepes. Perfect with any curry',
      imageUrl: 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=400&fit=crop',
      price: 150,
      isVeg: true,
    ),
  ];

  static List<SwadishMenuItem> _pizzaMenu(int base) => [
        SwadishMenuItem(
          id: base,
          name: 'Margherita Pizza',
          description:
              'Classic tomato base, fresh mozzarella & basil on hand-tossed crust',
          imageUrl:
              'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&fit=crop',
          price: 269,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 1,
          name: 'Pepperoni Pizza',
          description:
              'Generous pepperoni slices, mozzarella & oregano on rich tomato base',
          imageUrl:
              'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=400&fit=crop',
          price: 349,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 2,
          name: 'BBQ Chicken Pizza',
          description: 'Smoky BBQ sauce, grilled chicken, red onion & cheddar',
          imageUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&fit=crop',
          price: 329,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 3,
          name: 'Pasta Arrabbiata',
          description: 'Penne in spicy tomato-garlic sauce with fresh basil',
          imageUrl:
              'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=400&fit=crop',
          price: 199,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 4,
          name: 'Cheesy Garlic Bread',
          description:
              'Toasted baguette loaded with mozzarella, herbs & roasted garlic',
          imageUrl:
              'https://images.unsplash.com/photo-1549931319-a545dcf3bc7b?w=400&fit=crop',
          price: 149,
          isVeg: true,
        ),
      ];

  static List<SwadishMenuItem> _burgerMenu(int base) => [
        SwadishMenuItem(
          id: base,
          name: 'Classic Chicken Burger',
          description:
              'Crispy fried chicken thigh, lettuce, pickles & house mayo in a brioche bun',
          imageUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&fit=crop',
          price: 219,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 1,
          name: 'BBQ Smash Burger',
          description:
              'Double smash patty, cheddar, crispy bacon & smoky BBQ sauce',
          imageUrl:
              'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400&fit=crop',
          price: 289,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 2,
          name: 'Aloo Tikki Burger',
          description:
              'Spiced potato patty, mint chutney, shredded slaw in a sesame bun',
          imageUrl:
              'https://images.unsplash.com/photo-1585238342024-78d387f4a707?w=400&fit=crop',
          price: 159,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 3,
          name: 'Loaded Fries',
          description:
              'Crispy fries topped with cheese sauce, jalapeños & spring onions',
          imageUrl:
              'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&fit=crop',
          price: 139,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 4,
          name: 'Chicken Wings (6 pcs)',
          description: 'Tossed in buffalo sauce, served with ranch dip',
          imageUrl:
              'https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=400&fit=crop',
          price: 249,
          isVeg: false,
        ),
      ];

  static List<SwadishMenuItem> _cafeMenu(int base) => [
        SwadishMenuItem(
          id: base,
          name: 'Cappuccino',
          description:
              'Double espresso with velvety steamed milk foam, dusted with cocoa',
          imageUrl:
              'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&fit=crop',
          price: 129,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 1,
          name: 'Avocado Toast',
          description:
              'Sourdough with smashed avocado, cherry tomatoes, feta & chilli flakes',
          imageUrl:
              'https://images.unsplash.com/photo-1603046891744-76e6300f82ef?w=400&fit=crop',
          price: 199,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 2,
          name: 'Club Sandwich',
          description:
              'Triple-decker with grilled chicken, egg, cheese, lettuce & tomato',
          imageUrl:
              'https://images.unsplash.com/photo-1481070555726-e2fe8357725f?w=400&fit=crop',
          price: 239,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 3,
          name: 'Brownie Sundae',
          description:
              'Warm chocolate brownie with vanilla gelato & hot fudge sauce',
          imageUrl:
              'https://images.unsplash.com/photo-1545249390-6bdfa286032f?w=400&fit=crop',
          price: 179,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 4,
          name: 'Cold Brew Coffee',
          description:
              'Steeped 18 hours, served over ice with a splash of oat milk',
          imageUrl:
              'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&fit=crop',
          price: 149,
          isVeg: true,
        ),
      ];

  static List<SwadishMenuItem> _chineseMenu(int base) => [
        SwadishMenuItem(
          id: base,
          name: 'Veg Hakka Noodles',
          description:
              'Wok-tossed noodles with crunchy vegetables & dark soy sauce',
          imageUrl:
              'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=400&fit=crop',
          price: 159,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 1,
          name: 'Chicken Fried Rice',
          description:
              'Egg-fried rice with diced chicken, spring onions & soy-chilli sauce',
          imageUrl:
              'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400&fit=crop',
          price: 189,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 2,
          name: 'Manchurian Gravy',
          description:
              'Crispy vegetable balls in tangy Manchurian sauce with peppers & onions',
          imageUrl:
              'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&fit=crop',
          price: 179,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 3,
          name: 'Crispy Chilli Chicken',
          description:
              'Battered chicken strips tossed in fiery red chilli & garlic sauce',
          imageUrl:
              'https://images.unsplash.com/photo-1598103442097-8b74394b95c8?w=400&fit=crop',
          price: 219,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 4,
          name: 'Hot & Sour Soup',
          description:
              'Tangy clear broth with mushrooms, tofu, vinegar & white pepper',
          imageUrl:
              'https://images.unsplash.com/photo-1547592180-85f173990554?w=400&fit=crop',
          price: 99,
          isVeg: true,
        ),
      ];

  static List<SwadishMenuItem> _fastFoodMenu(int base) => [
        SwadishMenuItem(
          id: base,
          name: 'Veg Wrap',
          description:
              'Grilled paneer tikka, fresh vegetables & mint chutney in a wheat tortilla',
          imageUrl:
              'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=400&fit=crop',
          price: 149,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 1,
          name: 'Chicken Roll',
          description:
              'Juicy grilled chicken strips, caramelised onions & spicy sauce in a paratha',
          imageUrl:
              'https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=400&fit=crop',
          price: 179,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 2,
          name: 'Pav Bhaji',
          description:
              'Spiced mixed vegetable mash with buttered pav & onion-lemon garnish',
          imageUrl:
              'https://images.unsplash.com/photo-1585237421612-70a008356fbe?w=400&fit=crop',
          price: 129,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 3,
          name: 'Masala Fries',
          description:
              'Crispy fries tossed with chaat masala, lemon & fresh coriander',
          imageUrl:
              'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&fit=crop',
          price: 109,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 4,
          name: 'Mango Lassi',
          description: 'Thick chilled yoghurt blended with Alphonso mango pulp',
          imageUrl:
              'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=400&fit=crop',
          price: 79,
          isVeg: true,
        ),
      ];

  static List<SwadishMenuItem> _multiCuisineMenu(int base) => [
        SwadishMenuItem(
          id: base,
          name: 'Paneer Butter Masala',
          description:
              'Velvety tomato-cream gravy with golden paneer cubes & kasuri methi',
          imageUrl:
              'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400&fit=crop',
          price: 229,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 1,
          name: 'Chicken Biryani',
          description:
              'Aromatic basmati layered with spiced chicken, fried onions & saffron',
          imageUrl:
              'https://images.unsplash.com/photo-1701579231305-d84d8af9a3fd?w=400&fit=crop',
          price: 259,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 2,
          name: 'Veg Fried Rice',
          description:
              'Wok-tossed basmati with seasonal vegetables, eggs & soy sauce',
          imageUrl:
              'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&fit=crop',
          price: 169,
          isVeg: true,
        ),
        SwadishMenuItem(
          id: base + 3,
          name: 'Tandoori Chicken (half)',
          description:
              'Marinated in yoghurt & spices, roasted in clay tandoor — smoky & juicy',
          imageUrl:
              'https://images.unsplash.com/photo-1598103442097-8b74394b95c8?w=400&fit=crop',
          price: 289,
          isVeg: false,
        ),
        SwadishMenuItem(
          id: base + 4,
          name: 'Gulab Jamun (2 pcs)',
          description:
              'Soft milk-solid dumplings soaked in rose-cardamom sugar syrup',
          imageUrl:
              'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=400&fit=crop',
          price: 89,
          isVeg: true,
        ),
      ];
}

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────
class SwadistScreen extends StatefulWidget {
  final String initialSearchQuery;
  const SwadistScreen({super.key, this.initialSearchQuery = ''});
  @override
  State<SwadistScreen> createState() => _SwadistScreenState();
}

class _SwadistScreenState extends State<SwadistScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedCategory = 'All';

  final List<String> _filters = [
    'All',
    'Pure Veg',
    'Offers',
    'Fast Delivery',
    'Ratings 4.0+',
  ];

  // ── NEW API VARIABLES ──
  bool _isLoadingApi = true;
  List<dynamic> _apiCategories = [];
  List<SwadistRestaurant> _apiRestaurants = [];
 

Timer? _restaurantSearchDebounce;
List<SwadistRestaurant> _restaurantSearchResults = [];
bool _isSearchingRestaurants = false;
int _restaurantSearchRequestId = 0;

  final List<_FoodCategory> _categories = [
    const _FoodCategory(name: 'All', imageUrl: ''),
    const _FoodCategory(
      name: 'Biryani',
      imageUrl:
      'https://images.unsplash.com/photo-1701579231305-d84d8af9a3fd?w=200&fit=crop',
    ),
    const _FoodCategory(
      name: 'Chicken',
      imageUrl:
      'https://images.unsplash.com/photo-1598103442097-8b74394b95c8?w=200&fit=crop',
    ),
    const _FoodCategory(
      name: 'North Indian',
      imageUrl:
      'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=200&fit=crop',
    ),
    const _FoodCategory(
      name: 'Pizza',
      imageUrl:
      'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200&fit=crop',
    ),
    const _FoodCategory(
      name: 'Burgers',
      imageUrl:
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&fit=crop',
    ),
    const _FoodCategory(
      name: 'South Indian',
      imageUrl:
      'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=200&fit=crop',
    ),
    const _FoodCategory(
      name: 'Pasta',
      imageUrl:
      'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=200&fit=crop',
    ),
  ];

  // Location display — dynamic GPS fetch
  String _locationName = 'Fetching location...';
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Banner
  final PageController _bannerCtrl = PageController(viewportFraction: 1.0);
  int _bannerIndex = 0;
  Timer? _bannerTimer;
  bool _bannerUserScrolling = false;

  // Using the same banner images from the original file
  final List<String> _bannerImages = [
    'assets/images/swadisht_banner_1.png',
    'assets/images/swadisht_banner_2.png',
    'assets/images/swadisht_banner_3.PNG', // "Curated Meals For You!" banner
  ];

  // Scroll controller + per-card keys for auto-scroll from dashboard
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _restaurantKeys = {};

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initGpsLocation();
    _startBannerAutoPlay();
    _fetchApiData(); // ── NEW API CALL ──
    if (widget.initialSearchQuery.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery;
    }
    
      _searchController.addListener(() {
  if (mounted) setState(() {});
  _onRestaurantSearchChanged(_searchController.text);
});
      
  }

  // ── NEW API FETCH LOGIC WITH FALLBACK ──
  Future<void> _fetchApiData() async {
    try {
      final categoriesData = await ApiService.getSwadishtCategories();
      final itemsData = await ApiService.getFoodItems(category: '', page: 1);

      if (mounted) {
        setState(() {
          _apiCategories = categoriesData is List ? categoriesData : [];
          _apiRestaurants = _convertApiItemsToRestaurants(itemsData is List ? itemsData : []);
          _isLoadingApi = false;
        });
      }
    } catch (e) {
      debugPrint("API Fetch failed, using fallback data: $e");
      if (mounted) {
        setState(() {
          _isLoadingApi = false;
        });
      }
    }
  }
  void _onRestaurantSearchChanged(String value) {
    _restaurantSearchDebounce?.cancel();
    final query = value.trim();
    final requestId = ++_restaurantSearchRequestId;

    if (query.isEmpty) {
      setState(() {
        _restaurantSearchResults = [];
        _isSearchingRestaurants = false;
      });
      return;
    }

    setState(() {
      _isSearchingRestaurants = true;
      _restaurantSearchResults = [];
    });

    _restaurantSearchDebounce = Timer(
      const Duration(milliseconds: 500),
      () async {
        if (!mounted || requestId != _restaurantSearchRequestId) return;

        try {
          // Swadisht's verified backend search route is /api/s/food/items?search=...
          // It returns a paginated map containing an "items" list.
          final response = await ApiService.getSwadishtItems(
            search: query,
            page: 1,
            limit: 100,
          );

          if (!mounted || requestId != _restaurantSearchRequestId) return;

          final dynamic rawItems = response['items'];
          final items = rawItems is List ? rawItems : <dynamic>[];
          final results = _convertApiItemsToRestaurants(items);

          setState(() {
            _restaurantSearchResults = results;
            _isSearchingRestaurants = false;
          });
        } catch (e) {
          debugPrint('Swadisht food search failed: $e');
          if (!mounted || requestId != _restaurantSearchRequestId) return;
          setState(() {
            _restaurantSearchResults = [];
            _isSearchingRestaurants = false;
          });
        }
      },
    );
  }

  // ── HELPER: CONVERT API ITEMS TO UI RESTAURANTS ──
  List<SwadistRestaurant> _convertApiItemsToRestaurants(List<dynamic> apiItems) {
    if (apiItems.isEmpty) return [];

    // Group items by category (treating categories as virtual 'restaurants' for now)
    Map<String, List<SwadishMenuItem>> groupedItems = {};
    for (var item in apiItems) {
      final category = item['category']?['name'] ?? 'Other';
      final menuItem = SwadishMenuItem(
        id: int.tryParse(item['id'].toString()) ?? item.hashCode,
        name: item['name'] ?? 'Unknown Item',
        description: item['description'] ?? '',
        imageUrl: item['image_url'] ?? 'https://via.placeholder.com/150',
        price: (item['price'] as num?)?.toDouble() ?? 0.0,
        isVeg: item['is_veg'] ?? true,
      );

      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(menuItem);
    }

    // Create a 'Restaurant' card for each category grouping
    List<SwadistRestaurant> mapped = [];
    int idCounter = 1;
    groupedItems.forEach((categoryName, menuItems) {
      bool isPureVeg = menuItems.every((item) => item.isVeg);

      mapped.add(SwadistRestaurant(
        id: 'api_rest_$idCounter',
        name: 'Swadishtt $categoryName',
        cuisine: categoryName,
        imageUrl: menuItems.first.imageUrl, // Use first item's image
        rating: 4.5,
        ratingCount: 120,
        distance: 2.5,
        deliveryTime: 30,
        offer: '10% OFF on APIs',
        isPureVeg: isPureVeg,
        isPromoted: idCounter == 1,
        menuItems: menuItems,
        lat: 0.0,
        lng: 0.0,
      ));
      idCounter++;
    });

    return mapped;
  }


  void _initGpsLocation() async {
    final loc = await LocationService.fetchCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _locationName = loc.city.isNotEmpty ? '\${loc.city}, \${loc.state}' : loc.fullFormattedAddress;
      });
    }
  }

  void _listenVoice() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                _searchController.text = val.recognizedWords;
              });
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _startBannerAutoPlay() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_bannerUserScrolling && _bannerCtrl.hasClients) {
        final next = (_bannerIndex + 1) % _bannerImages.length;
        _bannerCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onBannerScrollStart() {
    _bannerUserScrolling = true;
    _bannerTimer?.cancel();
  }

  void _onBannerScrollEnd() {
    _bannerUserScrolling = false;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startBannerAutoPlay();
    });
  }

  @override
  void dispose() {
    _restaurantSearchDebounce?.cancel();
    _bannerTimer?.cancel();
    _bannerCtrl.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────
  String _guessLabel(List<String> types) {
    const map = {
      'biryani_restaurant': 'Biryani',
      'south_indian_restaurant': 'South Indian',
      'north_indian_restaurant': 'North Indian',
      'pizza_restaurant': 'Pizza',
      'burger_restaurant': 'Burgers',
      'chinese_restaurant': 'Chinese',
      'cafe': 'Café',
      'coffee_shop': 'Coffee',
      'fast_food_restaurant': 'Fast Food',
      'vegetarian_restaurant': 'Pure Veg',
      'seafood_restaurant': 'Seafood',
      'barbecue_restaurant': 'BBQ & Grill',
      'indian_restaurant': 'Indian',
    };
    for (final t in types) {
      if (map.containsKey(t)) return map[t]!;
    }
    return 'Multi Cuisine';
  }

  String _cleanCuisineLabel(String raw) {
    return raw
        .replaceAll('_restaurant', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '\${w[0].toUpperCase()}\${w.substring(1)}')
        .join(' ');
  }

  String _defaultFoodImage(List<String> types) {
    if (types.contains('pizza_restaurant')) {
      return 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&fit=crop';
    } else if (types.contains('south_indian_restaurant')) {
      return 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=600&fit=crop';
    } else if (types.contains('biryani_restaurant')) {
      return 'https://images.unsplash.com/photo-1701579231305-d84d8af9a3fd?w=600&fit=crop';
    } else if (types.contains('burger_restaurant')) {
      return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&fit=crop';
    } else if (types.contains('cafe') || types.contains('coffee_shop')) {
      return 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&fit=crop';
  }

  String _generateOffer(double rating, String priceLevel, int ratingCount) {
    if (rating >= 4.5) return '20% OFF on first order';
    if (priceLevel == 'PRICE_LEVEL_INEXPENSIVE') return 'Flat ₹30 OFF on ₹199+';
    if (ratingCount > 500) return '15% OFF | Use SWAD15';
    return 'Free delivery on ₹249+';
  }

  // ── Filtering (UPDATED TO USE API DATA IF AVAILABLE) ────────────────────────────────────
  List<SwadistRestaurant> get _filteredRestaurants {
    final query = _searchController.text.trim().toLowerCase();

    // ── USE API DATA IF AVAILABLE, ELSE FALLBACK ──
    final sourceList = query.isNotEmpty
    ? _restaurantSearchResults
    : (_apiRestaurants.isNotEmpty
        ? _apiRestaurants
        : _fallbackPopularRestaurants);

    return sourceList.where((r) {
      // Search query filter (restaurant name, cuisine, or menu items)
      if (query.isNotEmpty) {
        final nameMatch = r.name.toLowerCase().contains(query);
        final cuisineMatch = r.cuisine.toLowerCase().contains(query);
        final menuMatch = r.menuItems.any((item) =>
        item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query));
        if (!nameMatch && !cuisineMatch && !menuMatch) return false;
      }

      // Category filter (cuisine-based)
      if (_selectedCategory != 'All') {
        final c = _selectedCategory.toLowerCase();
        if (!r.cuisine.toLowerCase().contains(c) &&
            !r.name.toLowerCase().contains(c)) return false;
      }

      // Filter chips
      switch (_selectedFilter) {
        case 'Pure Veg':
          if (!r.isPureVeg) return false;
          break;
        case 'Offers':
          if (r.offer.isEmpty) return false;
          break;
        case 'Fast Delivery':
          if (r.deliveryTime > 30) return false;
          break;
        case 'Ratings 4.0+':
          if (r.rating < 4.0) return false;
          break;
      }

      return true;
    }).toList();
  }


  List<SwadistRestaurant> get _fallbackPopularRestaurants {
    final fallback = [
      (
        id: 'r_01',
        name: 'Swadishtt Kitchen',
        cuisine: 'North Indian • Mughlai • Tandoor',
        image: 'assets/restaraunt/swadishtt kitchen.png',
        rating: 4.5,
        time: 35,
        isVeg: false,
        types: ['north_indian_restaurant'],
      ),
      (
        id: 'r_02',
        name: 'Green Leaf Pure Veg',
        cuisine: 'South Indian • North Indian • Chinese',
        image: 'assets/restaraunt/green leaf pure veg.png',
        rating: 4.3,
        time: 30,
        isVeg: true,
        types: ['south_indian_restaurant'],
      ),
      (
        id: 'r_03',
        name: 'Biryani House',
        cuisine: 'Biryani • Hyderabadi • Mughlai',
        image: 'assets/restaraunt/biryani house.png',
        rating: 4.6,
        time: 40,
        isVeg: false,
        types: ['biryani_restaurant'],
      ),
      (
        id: 'r_04',
        name: 'Dosa Point',
        cuisine: 'South Indian • Breakfast • Pure Veg',
        image: 'assets/restaraunt/dosa point.png',
        rating: 4.4,
        time: 25,
        isVeg: true,
        types: ['south_indian_restaurant'],
      ),
      (
        id: 'r_05',
        name: 'Pizza Corner',
        cuisine: 'Pizza • Fast Food • Italian',
        image: 'assets/restaraunt/pizza corner.png',
        rating: 4.2,
        time: 35,
        isVeg: false,
        types: ['pizza_restaurant'],
      ),
      (
        id: 'r_06',
        name: 'Sweet Treats',
        cuisine: 'Desserts • Bakery • Ice Cream',
        image: 'assets/restaraunt/sweet treats.png',
        rating: 4.4,
        time: 30,
        isVeg: false,
        types: ['dessert_restaurant'],
      ),
      (
        id: 'r_07',
        name: 'Burger Junction',
        cuisine: 'Burgers • Fast Food • American',
        image: 'assets/restaraunt/burger junction.png',
        rating: 4.3,
        time: 30,
        isVeg: false,
        types: ['burger_restaurant'],
      ),
      (
        id: 'r_08',
        name: 'Royal Tandoor',
        cuisine: 'North Indian • Tandoor • Mughlai',
        image: 'assets/restaraunt/royal tandoor.png',
        rating: 4.6,
        time: 40,
        isVeg: false,
        types: ['north_indian_restaurant'],
      ),
      (
        id: 'r_09',
        name: 'Punjabi Dhaba',
        cuisine: 'Punjabi • North Indian • Tandoor',
        image: 'assets/restaraunt/punjabi dhaba.png',
        rating: 4.5,
        time: 35,
        isVeg: false,
        types: ['north_indian_restaurant'],
      ),
      (
        id: 'r_10',
        name: 'Kerala Spice Garden',
        cuisine: 'Kerala • South Indian • Seafood',
        image: 'assets/restaraunt/kerala spice garden.png',
        rating: 4.6,
        time: 40,
        isVeg: false,
        types: ['south_indian_restaurant'],
      ),
      (
        id: 'r_11',
        name: 'Rolls & Wraps Co.',
        cuisine: 'Rolls • Fast Food • Wraps',
        image: 'assets/restaraunt/rolls & wraps co..png',
        rating: 4.2,
        time: 25,
        isVeg: false,
        types: ['fast_food_restaurant'],
      ),
      (
        id: 'r_12',
        name: 'Chettinad Palace',
        cuisine: 'Chettinad • South Indian • Spicy',
        image: 'assets/restaraunt/chettinad palace.png',
        rating: 4.7,
        time: 40,
        isVeg: false,
        types: ['south_indian_restaurant'],
      ),
      (
        id: 'r_13',
        name: 'China Wok Express',
        cuisine: 'Chinese • Asian • Noodles',
        image: 'assets/restaraunt/china wok express.png',
        rating: 4.1,
        time: 35,
        isVeg: false,
        types: ['chinese_restaurant'],
      ),
      (
        id: 'r_14',
        name: 'Cafe Mocha',
        cuisine: 'Cafe • Beverages • Desserts',
        image: 'assets/restaraunt/cafe mocha.png',
        rating: 4.7,
        time: 25,
        isVeg: false,
        types: ['cafe'],
      ),
      (
        id: 'r_15',
        name: 'Andhra Spice',
        cuisine: 'Andhra • South Indian • Spicy',
        image: 'assets/restaraunt/andhra spice.png',
        rating: 4.5,
        time: 40,
        isVeg: false,
        types: ['south_indian_restaurant'],
      ),
      (
        id: 'r_16',
        name: 'Mumbai Street Bites',
        cuisine: 'Street Food • North Indian • Chaat',
        image: 'assets/restaraunt/mumbai streets bites.png',
        rating: 4.4,
        time: 25,
        isVeg: false,
        types: ['street_food_restaurant'],
      ),
      (
        id: 'r_17',
        name: 'Thali Express',
        cuisine: 'Thali • North Indian • Rajasthani',
        image: 'assets/restaraunt/thali express.png',
        rating: 4.3,
        time: 35,
        isVeg: false,
        types: ['north_indian_restaurant'],
      ),
      (
        id: 'r_18',
        name: 'Oven Fresh Bakehouse',
        cuisine: 'Bakery • Cafe • Healthy',
        image: 'assets/restaraunt/oven fresh bakehouse.png',
        rating: 4.6,
        time: 30,
        isVeg: false,
        types: ['bakery'],
      ),
      (
        id: 'r_19',
        name: 'Kebab & Grill House',
        cuisine: 'Mughlai • Kebab • Grills',
        image: 'assets/restaraunt/kebab & grill house.png',
        rating: 4.4,
        time: 40,
        isVeg: false,
        types: ['mughlai_restaurant'],
      ),
      (
        id: 'r_20',
        name: 'Noodle Bar Asia',
        cuisine: 'Pan Asian • Japanese • Thai',
        image: 'assets/restaraunt/noodle bar asia.png',
        rating: 4.3,
        time: 35,
        isVeg: false,
        types: ['asian_restaurant'],
      ),
      (
        id: 'r_21',
        name: 'Malabar Mess',
        cuisine: 'Malabar • South Indian • Seafood',
        image: 'assets/restaraunt/malabar mess.png',
        rating: 4.5,
        time: 40,
        isVeg: false,
        types: ['south_indian_restaurant'],
      ),
      (
        id: 'r_22',
        name: 'Pasta & More',
        cuisine: 'Italian • Pasta • Mediterranean',
        image: 'assets/restaraunt/pasta & more.png',
        rating: 4.4,
        time: 35,
        isVeg: false,
        types: ['italian_restaurant'],
      ),
    ];

    return fallback.map((r) {
      return SwadistRestaurant(
        id: r.id,
        name: r.name,
        cuisine: r.cuisine,
        imageUrl: r.image,
        rating: r.rating,
        ratingCount: 1800,
        distance: 1.2,
        deliveryTime: r.time,
        offer: '',
        isPureVeg: r.isVeg,
        isPromoted: false,
        menuItems: _MenuGenerator.generate(r.types, r.name),
        lat: 12.9716,
        lng: 77.5946,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartCount = cart.totalItemsCount;
    final visibleRestaurants = _filteredRestaurants;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        extendBody: true,
      bottomNavigationBar: _buildBottomNav(cartCount),
      backgroundColor: Colors.grey.shade100,
      drawer: const AppDrawer(),
      body: _currentIndex == 1
          ? SwadishtOrdersScreen(
              onBackToHome: () => setState(() => _currentIndex = 0),
            )
          : _currentIndex == 2
              ? const CartScreen()
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // ── New red hero header (brand + search + banner + quick tiles)
                    SliverToBoxAdapter(child: _buildNewHeroSection(cartCount)),

                    // ── Categories section
                    SliverToBoxAdapter(child: _buildCategoriesSection()),

                    // ── Trending Near You
                    SliverToBoxAdapter(
                        child: _buildTrendingNearYou(visibleRestaurants)),

                    // ── Filter chips
                    SliverToBoxAdapter(child: _buildFilterSection()),

                    // ── "Restaurants near you" / "Search results" header
                    SliverToBoxAdapter(
                        child: _buildSectionHeader(visibleRestaurants.length)),

                    // ── Restaurant list
                    if (_isSearchingRestaurants)
  const SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  )
else if (visibleRestaurants.isEmpty)
  SliverToBoxAdapter(child: _buildEmptyState())
else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final r = visibleRestaurants[index];
                              _restaurantKeys[index] ??= GlobalKey();
                              return KeyedSubtree(
                                key: _restaurantKeys[index],
                                child: _buildGridRestaurantCard(r),
                              );
                            },
                            childCount: visibleRestaurants.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // NEW HERO SECTION — banner bg image + header + banner + quick tiles
  // ─────────────────────────────────────────────────
  Widget _buildNewHeroSection(int cartCount) {
    return Stack(
      children: [
        // ── Full-bleed banner background image covers entire hero section
        Positioned.fill(
          child: Image.asset(
            'assets/Swadishtt/banner background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color.fromARGB(255, 197, 8, 5)),
          ),
        ),

        // ── All hero content on top of the background
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top app bar
            _buildRedAppBar(cartCount),
            const SizedBox(height: 4),

            // ── Search bar
            _buildRedSearchBar(),
            const SizedBox(height: 10),

            // ── Full-width hero banner (no horizontal padding)
            _buildHeroBanner(),

            // ── Quick-access tiles & Background Transition
            Stack(
              children: [
                // White rounded top background (starts partially down the tiles)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -2, // Slight overlap to prevent 1px gap
                  top:
                      75, // Adjust this so white starts near bottom of tile images
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                  ),
                ),

                // The tiles themselves
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: _buildQuickAccessTiles(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Top app bar on red background
  Widget _buildRedAppBar(int cartCount) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand + delivery info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Swadishtt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    '20 Mins',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  GestureDetector(
                    onTap: _initGpsLocation,
                    child: Row(
                      children: [
                        const Text(
                          'To Home –  ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.my_location, color: Colors.white, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Notification bell
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Profile avatar
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SwadishtProfileScreen()),
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar on red background (functional live search)
  Widget _buildRedSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Color(0xFFB0B0B0), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search for restaurants or dishes...',
                  hintStyle: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {});
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.clear, color: Colors.grey, size: 18),
                ),
              ),
            // Mic button
            GestureDetector(
              onTap: _listenVoice,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isListening ? const Color(0xFF8B1C1C) : const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isListening ? Colors.white : const Color(0xFF8B1C1C),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  // ── Hero Banner (full-width, food images float on red bg)
  Widget _buildHeroBanner() {
    return SizedBox(
      width: double.infinity,
      height: 255,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Black decorative blob — bottom-right corner

          // ── HUNGERRR! giant white text
          const Positioned(
            top: 46,
            left: 0,
            right: 0,
            child: Text(
              'HUNGERRR!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -1.5,
              ),
            ),
          ),

          // ── Food images (burger + fried chicken) floating right side
          Positioned(
            right: 0,
            left: 0,
            top: 0,
            bottom: 35,
            child: SizedBox(
              width: 210,
              child: Image.asset(
                'assets/Swadishtt/banner.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ── HOT DEAL badge (white pill, red border + red text)
          Positioned(
            top: 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE53935),
                  width: 1.5,
                ),
              ),
              child: const Text(
                'HOT DEAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE53935),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // ── "Order Now ›" pill button — bottom-left
          Positioned(
            bottom: 12,
            left: 16,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  600,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE53935),
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  'Order Now ›',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
            ),
          ),

          // ── UP TO 20% OFF circle badge — bottom-right, over the blob
          Positioned(
            bottom: 8,
            right: 14,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'UP TO',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE53935),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '20%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE53935),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'OFF',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE53935),
                      letterSpacing: 1,
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

  // ── Quick Access Tiles (4 colored rounded-square tiles)
  Widget _buildQuickAccessTiles() {
    final tiles = [
      (
        label: 'Swipe Eats',
        image: 'assets/Swadishtt/swipe eats.png',
        color: const Color(0xFFAD2A6E),
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SwipeEatsScreen()),
            ),
      ),
      (
        label: 'Instant Catering',
        image: 'assets/Swadishtt/instant catering.png',
        color: const Color(0xFF2E7D32),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InstantCateringPage(),
            ),
          );
        },
      ),
      (
        label: 'Regional Soul',
        image: 'assets/Swadishtt/regional soul.png',
        color: const Color(0xFF512DA8),
        onTap: () {},
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(tiles.length, (i) {
          final tile = tiles[i];
          return Expanded(
            child: GestureDetector(
              onTap: tile.onTap,
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 12,
                  right: i == tiles.length - 1 ? 0 : 12,
                ),
                child: Column(
                  children: [
                    // Tile image
                    AspectRatio(
                      aspectRatio: 1.0, // Perfect square to prevent elongation
                      child: Container(
                        decoration: BoxDecoration(
                          color: tile.color,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            tile.image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.restaurant_menu,
                              color: Colors.white.withOpacity(0.7),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tile.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // NEW CATEGORIES SECTION
  // ─────────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    final List<Map<String, String>> cats = [
      {
        'name': 'pizza',
        'label': 'Pizza',
        'image':
            'https://i.pinimg.com/1200x/f2/8f/cc/f28fcc4e0b34bab096d0df3d528a23a4.jpg',
      },
      {
        'name': 'Indian main course',
        'label': 'Indian Main Course',
        'image':
            'https://img.freepik.com/premium-photo/delicious-paneer-butter-masala-photography_928503-851.jpg?w=2000&fit=crop',
      },
      {
        'name': 'south Indian',
        'label': 'South Indian',
        'image':
            'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=400&fit=crop',
      },
      {
        'name': 'burgers and sandwiches',
        'label': 'Burgers & Sandwiches',
        'image':
            'https://i.pinimg.com/736x/5c/c7/55/5cc7553605366cacf1a5cd1758d386dd.jpg',
      },
      {
        'name': 'pasta and noodles',
        'label': 'Pasta & Noodles',
        'image':
            'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=400&fit=crop',
      },
      {
        'name': 'snacks and starters',
        'label': 'Snacks & Starters',
        'image':
            'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&fit=crop',
      },
      {
        'name': 'desserts',
        'label': 'Desserts',
        'image':
            'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&fit=crop',
      },
      {
        'name': 'beverages',
        'label': 'Beverages',
        'image':
            'https://images.unsplash.com/photo-1546173159-315724a31696?w=400&fit=crop',
      },
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AllCategoriesScreen(categories: cats),
                      ),
                    );
                  },
                  child: const Text(
                    'See all ›',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 255, 0, 0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scrollable category circles
          SizedBox(
            height: 115,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final cat = cats[i];
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryProductsScreen(
                          categoryName: cat['name']!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade100,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFE53935)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              cat['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.restaurant,
                                color: const Color(0xFFE53935),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['label'] ?? cat['name']!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFFE53935)
                                : Colors.black87,
                            height: 1.2,
                          ),
                        ),
                      ],
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

  // ─────────────────────────────────────────────────
  // TRENDING NEAR YOU — horizontal cards
  // ─────────────────────────────────────────────────
  Widget _buildTrendingNearYou(List<SwadistRestaurant> restaurants) {
    // Use shuffled trending products from products_data
    final trendingDishes = ProductsData.trendingProducts;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Trending Near You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryProductsScreen(
                          categoryName: 'Trending Near You',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'See all ›',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 255, 0, 0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scroll of dish cards
          SizedBox(
            height: 222,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: trendingDishes.length,
              itemBuilder: (_, i) {
                final dish = trendingDishes[i];
                final rating = 4.0 + (dish.id % 9) / 10;
                final reviews = 100 + (dish.id % 20) * 10;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SwadishtFoodDetailScreen(product: dish),
                      ),
                    );
                  },
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 148,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Food image
                          Stack(
                              children: [
                                ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: (dish.imageUrl != null &&
                                    dish.imageUrl!.startsWith('http'))
                                ? Image.network(
                                    dish.imageUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 120,
                                      color: Colors.grey.shade100,
                                      child: Icon(Icons.restaurant,
                                          size: 40,
                                          color: Colors.grey.shade300),
                                    ),
                                  )
                                : Container(
                                    height: 120,
                                    color: Colors.grey.shade100,
                                    child: Center(
                                      child: Text(
                                        dish.emoji,
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    ),
                                  ),
                          ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Consumer<BookmarkProvider>(
                                    builder: (context, provider, _) {
                                      bool isFav = provider.isSwadishttSaved(dish.id);
                                      return GestureDetector(
                                        onTap: () => provider.toggleSwadishtt(dish.id),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            size: 16,
                                            color: isFav ? AppColors.swadistPrimary : Colors.black54,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                          // Info
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dish.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '30 min • 2.1 km',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Color(0xFFFFC107),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      ' ($reviews)',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '₹${dish.price.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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

  // _buildFoodHomeHeader is replaced by _buildNewHeroSection above.
  // Kept as empty stub to avoid breaking any external references.
  Widget _buildFoodHomeHeader(
          int cartCount, List<SwadistRestaurant> filtered) =>
      const SizedBox.shrink();

  // _buildOfferBanner is replaced by _buildHeroBanner (inside _buildNewHeroSection).
  Widget _buildOfferBanner() => const SizedBox.shrink();
  Widget _buildPopularMiniCard(SwadistRestaurant restaurant) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _RestaurantMenuScreen(restaurant: restaurant),
        ),
      ),
      child: Container(
        width: 132,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE8E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildPopularImage(restaurant.imageUrl),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    restaurant.cuisine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${restaurant.deliveryTime} min • ₹₹',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularImage(String imageUrl) {
    Widget fallback() {
      return Container(
        width: 132,
        height: 86,
        color: const Color(0xFFFFEFE6),
        child: Icon(Icons.restaurant, color: AppColors.swadistPrimary),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 132,
        height: 86,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    return Image.network(
      imageUrl,
      width: 132,
      height: 86,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  Widget _buildPopularSkeleton() {
    return Container(
      width: 132,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE8E1)),
      ),
      child: Column(
        children: [
          Container(
            height: 86,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Container(height: 10, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Container(height: 8, color: Colors.grey.shade100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Thali Engine entry — now accessed via _buildQuickAccessTiles
  Widget _buildThaliEngineEntry() => const SizedBox.shrink();

  // ── Smart Menu entry — now accessed via Reels tab in bottom nav
  Widget _buildSmartMenuEntry() => const SizedBox.shrink();

  // ── Legacy hero banner with header — replaced by _buildNewHeroSection
  Widget _buildHeroBannerWithHeader(double topPadding, int cartCount) =>
      const SizedBox.shrink();

  // ── Legacy search bar — replaced by _buildRedSearchBar in hero section
  Widget _buildSearchBar() => const SizedBox.shrink();

  // ── Legacy venture buttons — replaced by _buildQuickAccessTiles
  Widget _buildVentureButtons() => const SizedBox.shrink();

  // ── Legacy category section — replaced by _buildCategoriesSection
  Widget _buildCategorySection() => const SizedBox.shrink();

  // ── Filter chips ─────────────────────────────────
  Widget _buildFilterSection() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color.fromARGB(255, 255, 0, 0)
                    : Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: selected
                      ? const Color.fromARGB(255, 255, 0, 0)
                      : Colors.grey.shade300,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color.fromARGB(255, 255, 0, 0)
                              .withOpacity(0.25),
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section header ───────────────────────────────
  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restaurants near you',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$count places available',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state (kept for completeness) ─────────────────────────
  Widget _buildErrorState() {
    return const SizedBox.shrink();
  }

  // ── Empty state ──────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.restaurant_outlined,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No restaurants match your filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing the category or filter',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  // ── Restaurant card ──────────────────────────────
  Widget _buildGridRestaurantCard(SwadistRestaurant r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _RestaurantMenuScreen(restaurant: r),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            r.imageUrl.startsWith('http')
                ? Image.network(
                    r.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade200),
                  )
                : Image.asset(
                    r.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade200),
                  ),
            // Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black54,
                    Colors.black87,
                  ],
                  stops: [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
            // Rating Pill
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      r.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.star, color: Colors.amber, size: 10),
                  ],
                ),
              ),
            ),
            // Text Details
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    r.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.cuisine,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 10, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _locationName,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${r.deliveryTime}-${r.deliveryTime + 5} mins',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 9),
                      ),
                      Text(
                        '₹${r.deliveryTime * 10} for two',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 9),
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

  Widget _buildRestaurantCard(SwadistRestaurant r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _RestaurantMenuScreen(restaurant: r),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Restaurant photo
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: r.imageUrl.startsWith('http')
                      ? Image.network(
                          r.imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Icon(Icons.restaurant,
                                  size: 48, color: Colors.grey.shade300),
                            ),
                          ),
                        )
                      : Image.asset(
                          r.imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Icon(Icons.restaurant,
                                  size: 48, color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                ),

                // Offer badge
                if (r.offer.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xCC000000), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            r.offer,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Promoted badge
                if (r.isPromoted)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.swadistPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PROMOTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Pure Veg badge
                if (r.isPureVeg)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🌿 PURE VEG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    r.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  // Cuisine
                  Text(
                    r.cuisine,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Stats row — Rating | Distance | Delivery time
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: r.rating >= 4.0
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.white, size: 11),
                            const SizedBox(width: 2),
                            Text(
                              r.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ),

                      // Real distance from user
                      Row(
                        children: [
                          Icon(Icons.near_me_outlined,
                              size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text(
                            r.distance < 1.0
                                ? '${(r.distance * 1000).toStringAsFixed(0)} m'
                                : '${r.distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ),

                      // Delivery time
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text(
                            '${r.deliveryTime} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Rating count
                  if (r.ratingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_formatCount(r.ratingCount)} ratings on Google',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversalRedHeader({bool showSearch = true}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Swadishtt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '20 Mins',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'To Home - Sembakkam, Chennai',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 14),
            _buildRedSearchBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildCartView(CartProvider cart) {
    return Column(
      children: [
        // Universal Topper WITHOUT Search Bar for Cart
        _buildUniversalRedHeader(showSearch: false),

        Expanded(
          child: cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 14),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 0),
                        child: const Text(
                          'Explore Menu',
                          style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    const Text(
                      'Cart Summary',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),

                    // CART ITEMS LIST
                    ...cart.items.map((item) {
                      final lowerName = item.product.name.toLowerCase();
                      final isCustomizable = lowerName.contains('pizza') ||
                          lowerName.contains('burger');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      item.product.imageUrl ??
                                          'assets/Swadishtt/burger.png',
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.fastfood,
                                          color: Color(0xFFE53935)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.product.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('₹${item.product.price.toInt()}',
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w700)),

                                        // BULLET / DOTTED LIST FOR ADD-ONS
                                        if (item.product.selectedAddOns !=
                                                null &&
                                            item.product.selectedAddOns!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          ...item.product.selectedAddOns!.map(
                                            (addOn) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 2),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    '• ',
                                                    style: TextStyle(
                                                      color: Color(0xFFE53935),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      addOn,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFFE53935),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],

                                        if (item.product.specialInstructions !=
                                                null &&
                                            item.product.specialInstructions!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            'Note: ${item.product.specialInstructions}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 11.5,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                        if (item.product.description
                                                .isNotEmpty &&
                                            (item.product.selectedAddOns ==
                                                    null ||
                                                item.product.selectedAddOns!
                                                    .isEmpty)) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.product.description,
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Color(0xFFE53935)),
                                        onPressed: () => cart
                                            .decreaseQuantity(item.product.id),
                                      ),
                                      Text('${item.quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15)),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xFFE53935)),
                                        onPressed: () =>
                                            cart.addItem(item.product),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (isCustomizable) ...[
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Customisable Item',
                                        style: TextStyle(
                                          color: Color(0xFFE53935),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        final cleanName = item.product.name
                                            .replaceAll(' (Customized)', '');
                                        SwadishtCustomizeOrderBottomSheet.show(
                                          context,
                                          itemName: cleanName,
                                          basePrice: item.product.basePrice ??
                                              item.product.price,
                                          itemImage: item.product.imageUrl,
                                          initialInstructions:
                                              item.product.specialInstructions,
                                          initialAddOns:
                                              item.product.selectedAddOns,
                                          existingProductId: item.product.id,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        child: Row(
                                          children: [
                                            Icon(Icons.tune,
                                                size: 14,
                                                color: Color(0xFFE53935)),
                                            SizedBox(width: 4),
                                            Text(
                                              'Edit Customisation',
                                              style: TextStyle(
                                                color: Color(0xFFE53935),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    // ── BILL SUMMARY / INVOICE BREAKDOWN CARD ──
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.receipt_long,
                                  size: 18, color: Color(0xFFE53935)),
                              SizedBox(width: 8),
                              Text(
                                'Bill Details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Item Total',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.grey.shade700)),
                              Text('₹${cart.subtotal.toInt()}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery Fee',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.grey.shade700)),
                              Text(
                                cart.deliveryCharges == 0
                                    ? 'FREE'
                                    : '₹${cart.deliveryCharges.toInt()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cart.deliveryCharges == 0
                                      ? const Color(0xFF2E7D32)
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Taxes & GST (5%)',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.grey.shade700)),
                              Text('₹${cart.tax.toInt()}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: Colors.black12, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'To Pay',
                                style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87),
                              ),
                              Text(
                                '₹${cart.total.toInt()}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
        ),

        // ── PINNED BOTTOM CHECKOUT BUTTON (RIGHT ABOVE FLOATING NAV BAR IN Y-AXIS) ──
        if (cart.items.isNotEmpty)
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 90,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentScreen()),
                  );
                },
                child: Text(
                  'PROCEED TO CHECKOUT  •  ₹${cart.total.toInt()}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNav(int cartCount) {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MainDashboard()),
                );
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
                        _buildCustomNavItem(0, Icons.home_outlined, 'Home'),
                        _buildCustomNavItem(
                            1, Icons.shopping_bag_outlined, 'Order'),
                        _buildCustomCartNavItem(2, cartCount),
                        _buildCustomNavItem(3, Icons.movie_outlined, 'Feeds'),
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

  Widget _buildCustomNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SwipeEatsScreen()),
          );
        } else {
          setState(() => _currentIndex = index);
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

  Widget _buildCustomCartNavItem(int index, int cartCount) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
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

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ─────────────────────────────────────────────
// Restaurant Menu Screen
// ─────────────────────────────────────────────
class _RestaurantMenuScreen extends StatefulWidget {
  final SwadistRestaurant restaurant;
  const _RestaurantMenuScreen({required this.restaurant});

  @override
  State<_RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<_RestaurantMenuScreen> {
  final TextEditingController _menuSearchCtrl = TextEditingController();
  String _menuSearch = '';
  String _menuFilter = 'All';
  String _selectedMenuTab = 'Menu';
  final List<String> _menuFilters = ['All', 'Veg', 'Non-Veg'];
  final List<String> _menuTabs = [
    'Menu',
    'Photos',
    'About',
    'Reviews',
  ];

  // --- NEW CATEGORY VARIABLES ---
  String _selectedMenuCategory = 'Recommended';
  final List<String> _menuCategories = [
    'Recommended',
    'Curries',
    'Rice & Breads',
    'Seafood',
    'Desserts'
  ];

  @override
  void dispose() {
    _menuSearchCtrl.dispose();
    super.dispose();
  }

  List<SwadishMenuItem> get _filteredItems {
    return widget.restaurant.menuItems.where((item) {
      // Search
      if (_menuSearch.isNotEmpty) {
        if (!item.name.toLowerCase().contains(_menuSearch.toLowerCase()))
          return false;
      }
      // Veg filter
      if (_menuFilter == 'Veg' && !item.isVeg) return false;
      if (_menuFilter == 'Non-Veg' && item.isVeg) return false;
      if (_selectedMenuTab == 'Biryani' &&
          !item.name.toLowerCase().contains('biryani')) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final cart = context.watch<CartProvider>();
    final cartCount = cart.totalItemsCount;
    final items = _filteredItems;
    return PopScope(
      canPop: _selectedMenuTab == 'Menu',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedMenuTab != 'Menu') {
          setState(() {
            _selectedMenuTab = 'Menu';
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFAF8),
        body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 285,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            leadingWidth: 62,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _MenuTopButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () {
                  if (_selectedMenuTab != 'Menu') {
                    setState(() {
                      _selectedMenuTab = 'Menu';
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Consumer<FavoriteRestaurantProvider>(
                    builder: (context, provider, child) {
                      final isFavorite = provider.isFavorite(r.id);
                      return _MenuTopButton(
                        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                        iconColor: isFavorite ? const Color(0xFF9B111E) : Colors.black87,
                        onTap: () {
                          final favRest = FavoriteRestaurant(
                            id: r.id,
                            name: r.name,
                            cuisine: r.cuisine,
                            imageUrl: r.imageUrl,
                            rating: r.rating,
                          );
                          provider.toggleFavorite(favRest);
                          
                          if (!isFavorite) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${r.name} added to favourites!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  r.imageUrl.startsWith('http')
                      ? Image.network(
                    r.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(
                          color: const Color(0xFFFFEFE6),
                          child: Icon(
                            Icons.restaurant,
                            size: 70,
                            color: AppColors.swadistPrimary,
                          ),
                        ),
                  )
                      : Image.asset(
                    r.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(
                          color: const Color(0xFFFFEFE6),
                          child: Icon(
                            Icons.restaurant,
                            size: 70,
                            color: AppColors.swadistPrimary,
                          ),
                        ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.22),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: _buildRestaurantInfoPanel(r),
            ),
          ),
          SliverToBoxAdapter(child: _buildMenuTabs()),
          if (_selectedMenuTab == 'Menu') ...[
            SliverToBoxAdapter(child: _buildMenuCategoryPills()),
            // --- THE ACTUAL MENU DISHES ---
            if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No dishes found',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildMenuItemCard(items[index], cart),
                    childCount: items.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: _buildPopularDishesSection()),
            SliverToBoxAdapter(child: _buildStoryAndReviews()),
          ] else if (_selectedMenuTab == 'Photos') ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dummyPhotos = [
                      'assets/Swadishtt/1.png',
                      'assets/Swadishtt/2.jpg',
                      'assets/Swadishtt/3.jpg',
                      'assets/Swadishtt/4.jpg',
                      'assets/Swadishtt/spaghetti bolognese.png',
                      'assets/Swadishtt/lemon herb roasted chicken.png',
                    ];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        dummyPhotos[index % dummyPhotos.length],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                  childCount: 6,
                ),
              ),
            ),
          ] else if (_selectedMenuTab == 'About') ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${r.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome to ${r.name}! We pride ourselves on serving the most authentic and delicious ${r.cuisine} in town. Established to bring joy to every customer, our mission revolves around exceptional flavors, warm hospitality, and a cozy dining experience.\n\nOur ingredients are locally sourced and thoughtfully prepared, ensuring the freshest quality in every bite. Whether you are here for a quick lunch, a grand family dinner, or ordering from home, we promise an unforgettable culinary journey.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (_selectedMenuTab == 'Reviews') ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final reviews = [
                      {'name': 'Arjun K.', 'rating': 5, 'text': 'Absolutely fantastic! The food was served hot and the taste was just mind-blowing. Will definitely order again.'},
                      {'name': 'Sneha R.', 'rating': 4, 'text': 'Great ambiance and very polite staff. The starters were amazing, but the main course took a little longer than expected.'},
                      {'name': 'Vikram M.', 'rating': 5, 'text': 'One of the best places in town for ${r.cuisine}. The flavors were authentic and portions were generous.'},
                      {'name': 'Priya D.', 'rating': 4, 'text': 'Really loved the packaging and the delivery was right on time. A highly recommended restaurant!'},
                    ];
                    final review = reviews[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(review['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Row(
                                children: List.generate(5, (i) => Icon(
                                  i < (review['rating'] as int) ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                )),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review['text'] as String, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
                        ],
                      ),
                    );
                  },
                  childCount: 4,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 92)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Floating margins
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30), // Smooth pill shape
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT SIDE: Delivery Info & Scooter Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF0F0), // Light red background
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delivery_dining, // Scooter icon
                      color: Color(0xFFD32F2F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '35–40 mins',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Delivery time',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // RIGHT SIDE: View Menu Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _FullMenuScreen(restaurant: r),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F), // Figma Dark Maroon
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'View Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildRestaurantInfoPanel(SwadistRestaurant r) {
    return Container(
      // Pulls the entire card up to overlap the image
      transform: Matrix4.translationValues(0.0, -36.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. MAIN INFO & LOGO
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Box
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A0C24), // Figma Dark Maroon
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant, color: Color(0xFFFFC107), size: 28),
                      const SizedBox(height: 2),
                      Text(
                        r.name.toUpperCase().split(' ').take(2).join('\n'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: 0.5
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.5
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.cuisine,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFC107),
                              size: 14),
                          const SizedBox(width: 4),
                          Text(r.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87)),
                          const SizedBox(width: 4),
                          Text('(${r.ratingCount}+ ratings)', style: TextStyle(fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(width: 1,
                                height: 12,
                                color: Colors.grey.shade300),
                          ),
                          Icon(Icons.access_time, color: Colors.grey.shade500,
                              size: 13),
                          const SizedBox(width: 4),
                          Text('${r.deliveryTime} mins', style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. TRUST BADGE CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0EAE1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTrustBadge(Icons.verified_outlined, 'FSSAI Verified',
                    'License No. 21223012045'),
                Container(
                    width: 1.5, height: 32, color: const Color(0xFFF0EAE1)),
                // Vertical divider
                const SizedBox(width: 12),
                _buildTrustBadge(Icons.eco_outlined, 'Hygienic Kitchen',
                    'Regularly Inspected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the separated badges
  Widget _buildTrustBadge(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          // Green Figma icon
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 9,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTabs() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _menuTabs.map((tab) {
          final selected = tab == _selectedMenuTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedMenuTab = tab),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? const Color(0xFFD32F2F) : Colors
                        .transparent, // Figma Maroon
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: selected ? const Color(0xFFD32F2F) : Colors.grey
                      .shade500,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVegFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: _menuFilters.map((f) {
          final selected = _menuFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _menuFilter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppColors.swadistPrimary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppColors.swadistPrimary
                      : const Color(0xFFEDE8E1),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /*
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.cuisine,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      _InfoChip(
                        Icons.star,
                        '${r.rating.toStringAsFixed(1)} (${_shortCount(r.ratingCount)})',
                        r.rating >= 4.0
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 16),
                      _InfoChip(
                        Icons.near_me_outlined,
                        r.distance < 1.0
                            ? '${(r.distance * 1000).toStringAsFixed(0)} m away'
                            : '${r.distance.toStringAsFixed(1)} km away',
                        Colors.blue.shade600,
                      ),
                      const SizedBox(width: 16),
                      _InfoChip(
                        Icons.access_time,
                        '${r.deliveryTime} min',
                        Colors.grey.shade600,
                      ),
                    ],
                  ),

                  if (r.offer.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer,
                              size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 6),
                          Text(
                            r.offer,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Menu search + filter
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _menuSearchCtrl,
                    onChanged: (v) => setState(() => _menuSearch = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search dishes...',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _menuSearch.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _menuSearchCtrl.clear();
                                setState(() => _menuSearch = '');
                              },
                              child: const Icon(Icons.close, size: 16),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _menuFilters.map((f) {
                      final selected = _menuFilter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _menuFilter = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.swadistPrimary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.swadistPrimary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu items
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No dishes found',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMenuItemCard(items[index], cart),
                childCount: items.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      // Bottom cart bar
      bottomNavigationBar: cartCount > 0
          ? SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.swadistPrimary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.swadistPrimary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$cartCount item${cartCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'View Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
  */

  // ── Menu item card ─────────────────────────────
  Widget _buildMenuItemCard(SwadishMenuItem item, CartProvider cart) {
    final cartProduct = Product(
      id: item.id,
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      category: 'Swadisht',
      description: item.description,
      emoji: '',
    );
    final isInCart = cart.getQuantity(item.id) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EAE1)), // Soft border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Image
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>
                    SwadishtFoodDetailScreen(product: cartProduct)),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl.startsWith('http')
                  ? Image.network(
                item.imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      width: 76,
                      height: 76,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
              )
                  : Image.asset(
                item.imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      width: 76,
                      height: 76,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Middle: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isVeg)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(2)),
                        child: const Icon(
                            Icons.circle, color: Colors.green, size: 6),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text('🌶️🌶️', style: TextStyle(fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade500, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${item.price.toInt()}',
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right: ADD Button
          isInCart
              ? Container(
            width: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () => cart.decreaseQuantity(item.id),
                  child: const Padding(padding: EdgeInsets.all(4),
                      child: Icon(Icons.remove, color: Colors.white, size: 14)),
                ),
                Text('${cart.getQuantity(item.id)}', style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13)),
                InkWell(
                  onTap: () => cart.addItem(cartProduct),
                  child: const Padding(padding: EdgeInsets.all(4),
                      child: Icon(Icons.add, color: Colors.white, size: 14)),
                ),
              ],
            ),
          )
              : GestureDetector(
            onTap: () {
              // Triggers the bottom sheet for customization, or adds to cart
              SwadishtCustomizeOrderBottomSheet.show(
                context,
                itemName: item.name,
                basePrice: item.price.toDouble(),
                itemImage: item.imageUrl,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F), // Figma Red
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('+Add', style: TextStyle(color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  // String _shortCount(int n) {
  //   if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  //   return '$n';
  // }
// --- NEW CATEGORY PILLS SECTION ---
  Widget _buildMenuCategoryPills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
// "Menu" Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Menu',
                style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _FullMenuScreen(restaurant: widget.restaurant),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text('View Full Menu', style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD32F2F))),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 10, color: Color(0xFFD32F2F)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
// Horizontal Scrollable Pills
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _menuCategories.length,
            itemBuilder: (context, index) {
              final cat = _menuCategories[index];
              final isSelected = cat == _selectedMenuCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedMenuCategory = cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFD32F2F) : Colors.white,
                    // Figma Red
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFD32F2F) : const Color(
                          0xFFE5E5E5),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight
                          .w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

// --- POPULAR DISHES & BANNER SECTION (Figma Match) ---
  Widget _buildPopularDishesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Popular Dishes',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _FullMenuScreen(restaurant: widget.restaurant),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text('See All', style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD32F2F))),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 10, color: Color(0xFFD32F2F)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Big Cards Horizontal Scroll
        SizedBox(
          height: 215,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.restaurant.menuItems.length > 5 ? 5 : widget.restaurant.menuItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = widget.restaurant.menuItems[index];
              return _buildPopularBigCard(item);
            },
          ),
        ),

        const SizedBox(height: 24),
        // "Why you'll love this dish" Promo Banner
        _buildWhyYoullLoveThisBanner(),
      ],
    );
  }

  Widget _buildPopularBigCard(SwadishMenuItem item) {
    final cartProduct = Product(
      id: item.id,
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      category: 'Swadisht',
      description: item.description,
      emoji: '',
    );
    final isVeg = item.isVeg;
    final rating = '4.8'; // Dummy rating
    final orders = '456'; // Dummy orders

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SwadishtFoodDetailScreen(product: cartProduct)),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0EAE1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: item.imageUrl.startsWith('http')
                  ? Image.network(
                item.imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(height: 110, color: Colors.grey.shade200),
              )
                  : Image.asset(
                item.imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(height: 110, color: Colors.grey.shade200),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.black87, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        '$rating | $orders orders',
                        style: TextStyle(fontSize: 9,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toInt()}',
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isVeg ? Colors.green : Colors.red, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isVeg ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
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

  Widget _buildWhyYoullLoveThisBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9F9), // Light pink/red background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE8E8), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: Color(0xFFD32F2F),
                          size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Why you'll love this dish",
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Coastal favourite • Medium spicy\nHighly rated by customers",
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Text(
                        "Try this",
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD32F2F)),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 10,
                          color: Color(0xFFD32F2F)),
                    ],
                  ),
                ],
              ),
            ),
            // Right side image & close icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.close, size: 14, color: Colors.black54),
                const SizedBox(height: 4),
                ClipOval(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1559847844-5315695dadae?w=200&fit=crop',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// --- NEW STORY & REVIEWS SECTION ---
  Widget _buildStoryAndReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

// 1. Story Cards Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStoryCard(
                Icons.restaurant, // Chef hat/restaurant icon
                'Kitchen Story',
                'Authentic Mangalorean recipes, made with fresh coastal ingredients and love.',
              ),
              const SizedBox(width: 12),
              _buildStoryCard(
                Icons.location_on_outlined, // Regional pin icon
                'Regional Flavours',
                "Experience the true taste of Karnataka's coastal heritage in every bite.",
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

// 2. Small grey divider pill
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

        const SizedBox(height: 24),

// 3. Inside the Kitchen Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F9), // Pale red background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE8E8), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.cookie_outlined, color: Color(0xFFD32F2F),
                      size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inside the Kitchen', style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text('Verified hygiene • Fresh preparation',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedMenuTab = 'Photos');
                        },
                        child: Row(
                          children: const [
                            Text('See More', style: TextStyle(fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD32F2F))),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 9, color: Color(
                                0xFFD32F2F)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=200&fit=crop',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

// 4. What People Say Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What people say (Feedback)',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Dish-specific feedback",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedMenuTab = 'Reviews');
                },
                child: Row(
                  children: const [
                    Text('See All', style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD32F2F))),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 10,
                        color: Color(0xFFD32F2F)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

// 5. Review Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0EAE1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
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
                          child: const Icon(
                              Icons.person, size: 18, color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ananya R.', style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87)),
                            Text('2 days ago', style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                        SizedBox(width: 4),
                        Text('5.0', style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '"Super fresh prawns and the perfect balance of spices. Loved it!"',
                  style: TextStyle(fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      height: 1.4),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Prawn Ghee Roast',
                    style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD32F2F)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCard(IconData icon, String title, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9F2), // Pale beige background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF6EADF)), // Light border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFFD32F2F)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade700, height: 1.3),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() => _selectedMenuTab = 'About');
              },
              child: Row(
                children: const [
                  Text('Read More', style: TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD32F2F))),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 9, color: Color(0xFF6B0721)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _MenuTopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuTopButton({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? Colors.black87, size: 20),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _FullMenuScreen extends StatelessWidget {
  final SwadistRestaurant restaurant;

  const _FullMenuScreen({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('${restaurant.name} Menu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFBFAF8),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: restaurant.menuItems.length,
        itemBuilder: (context, index) {
          final item = restaurant.menuItems[index];
          return _buildMenuItem(context, item, cart);
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, SwadishMenuItem item, CartProvider cart) {
    final cartProduct = Product(
      id: item.id,
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      category: 'Swadisht',
      description: item.description,
      emoji: '',
    );
    final isInCart = cart.getQuantity(item.id) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EAE1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SwadishtFoodDetailScreen(product: cartProduct)),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl.startsWith('http')
                  ? Image.network(item.imageUrl, width: 76, height: 76, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 76, height: 76, color: Colors.grey.shade100, child: const Icon(Icons.fastfood, color: Colors.grey)))
                  : Image.asset(item.imageUrl, width: 76, height: 76, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 76, height: 76, color: Colors.grey.shade100, child: const Icon(Icons.fastfood, color: Colors.grey))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.description, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('₹${item.price.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (!isInCart) {
                cart.addItem(cartProduct);
              } else {
                cart.removeItem(item.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isInCart ? const Color(0xFFFFF0F0) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isInCart ? const Color(0xFFD32F2F) : const Color(0xFFD32F2F).withOpacity(0.3),
                  width: isInCart ? 1.5 : 1,
                ),
              ),
              child: Text(
                isInCart ? 'ADDED' : 'ADD',
                style: TextStyle(
                  color: const Color(0xFFD32F2F),
                  fontSize: 11,
                  fontWeight: isInCart ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}