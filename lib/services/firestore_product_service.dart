import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class FirestoreProductService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of all active restaurants in Swadisht
  static Stream<List<Map<String, dynamic>>> getRestaurantsStream() {
    return _db
        .collection('restaurants')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetch all active restaurants once
  static Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      final snapshot = await _db
          .collection('restaurants')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching restaurants from Firestore: $e');
      return [];
    }
  }

  /// Stream of food items / dishes for Swadisht
  static Stream<List<Product>> getFoodItemsStream({String? category, String? restaurantId}) {
    Query query = _db.collection('food_items');

    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      query = query.where('category', isEqualTo: category.toLowerCase());
    }

    if (restaurantId != null && restaurantId.isNotEmpty) {
      query = query.where('restaurantId', isEqualTo: restaurantId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromJson(data);
      }).toList();
    });
  }

  /// Fetch all food items once with optional filtering
  static Future<List<Product>> getFoodItems({String? category, String? restaurantId}) async {
    try {
      Query query = _db.collection('food_items');

      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        query = query.where('category', isEqualTo: category.toLowerCase());
      }

      if (restaurantId != null && restaurantId.isNotEmpty) {
        query = query.where('restaurantId', isEqualTo: restaurantId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching food items from Firestore: $e');
      return [];
    }
  }

  /// Stream of products from Firestore
  static Stream<List<Product>> getProductsStream({String? category}) {
    Query query = _db.collection('products');
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      query = query.where('category', isEqualTo: category.toLowerCase());
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromJson(data);
      }).toList();
    });
  }

  /// Stream of Grokly grocery products
  static Stream<List<Map<String, dynamic>>> getGroklyProductsStream({String? category}) {
    Query query = _db.collection('grokly_products');
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      query = query.where('category', isEqualTo: category.toLowerCase());
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }



  /// Fetch categories list
  static Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    try {
      Query query = _db.collection('categories');
      if (type != null && type.isNotEmpty) {
        query = query.where('type', isEqualTo: type);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching categories from Firestore: $e');
      return [];
    }
  }
}
