import 'package:cloud_firestore/cloud_firestore.dart';

/// Result object for cross-venture grocery recommendations
class CrossVentureCandidate {
  final String productId;
  final String dishName;
  final int orderCount;
  final String reason;

  CrossVentureCandidate({
    required this.productId,
    required this.dishName,
    required this.orderCount,
    required this.reason,
  });
}

/// Engine to analyze Swadishtt restaurant orders and recommend matching Grokly grocery ingredients.
class CrossVentureEngine {
  final FirebaseFirestore? _firestore;
  final int minimumOrderThreshold;

  CrossVentureEngine({
    FirebaseFirestore? firestore,
    this.minimumOrderThreshold = 2,
  }) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Structured Dish-to-Grokly-SKU mapping table.
  /// Easily maintainable, expandable, and configurable.
  static const Map<String, List<String>> defaultDishIngredientMap = {
    'Butter Chicken': ['d12', 'd17', 's7'], // Butter, Fresh Cream, Spices/Dal
    'Dal Makhani': ['s7', 'd12', 'd17'],    // Dal, Butter, Fresh Cream
    'Dal Tadka': ['s7', 's8', 'd15'],       // Toor Dal, Moong Dal, Ghee
    'Paneer Butter Masala': ['d10', 'd12', 'v4'], // Paneer, Butter, Tomatoes
    'Palak Paneer': ['d10', 'v7', 'd17'],   // Paneer, Spinach, Cream
    'Chicken Biryani': ['s5', 'd15', 'v5'], // Basmati Rice, Ghee, Onions
    'Veg Biryani': ['s5', 'v4', 'v5'],      // Basmati Rice, Tomatoes, Onions
    'Masala Dosa': ['s18', 'd12', 'v6'],    // Dosa Batter, Butter, Potatoes
    'Filter Coffee': ['d3', 'bv4'],         // Milk, Coffee Powder
    'Masala Chai': ['d3', 'bv1'],           // Milk, Tea
  };

  /// Generates recommendation candidates from dish frequency map.
  List<CrossVentureCandidate> evaluateDishFrequencies(
    Map<String, int> dishCounts, {
    Map<String, List<String>>? customMapping,
  }) {
    final mapping = customMapping ?? defaultDishIngredientMap;
    final List<CrossVentureCandidate> candidates = [];
    final Set<String> seenProductIds = {};

    dishCounts.forEach((dish, orderCount) {
      // Apply minimum frequency rule (must be >= threshold, e.g. 2 times)
      if (orderCount >= minimumOrderThreshold) {
        // Find matching dish in mapping (case-insensitive substring match)
        String? matchedKey;
        for (final key in mapping.keys) {
          if (dish.toLowerCase().contains(key.toLowerCase()) ||
              key.toLowerCase().contains(dish.toLowerCase())) {
            matchedKey = key;
            break;
          }
        }

        if (matchedKey != null) {
          final productIds = mapping[matchedKey] ?? [];
          for (final pid in productIds) {
            if (!seenProductIds.contains(pid)) {
              seenProductIds.add(pid);
              candidates.add(
                CrossVentureCandidate(
                  productId: pid,
                  dishName: matchedKey,
                  orderCount: orderCount,
                  reason: 'Swadishtt cross-reference: $matchedKey ordered $orderCount times',
                ),
              );
            }
          }
        }
      }
    });

    return candidates;
  }

  /// Fetches Swadishtt order history from `users/{uid}/swadishtt_orders`.
  Future<Map<String, int>> fetchSwadishttDishCounts(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('swadishtt_orders')
          .get();

      final Map<String, int> dishCounts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          if (item is Map) {
            final dishName = item['name'] ?? item['dishName'] ?? item['title'];
            if (dishName is String && dishName.isNotEmpty) {
              dishCounts[dishName] = (dishCounts[dishName] ?? 0) + 1;
            }
          } else if (item is String && item.isNotEmpty) {
            dishCounts[item] = (dishCounts[item] ?? 0) + 1;
          }
        }
      }

      return dishCounts;
    } catch (_) {
      return {};
    }
  }
}
