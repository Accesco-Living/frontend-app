
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'api_service.dart';
import '../screens/grokly_screen.dart';
import '../models/products_data.dart';
import '../models/product.dart';

class CatalogSyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> syncCatalogs() async {
    // Your task: Grokly uses the VPS API.
    await _syncGroklyFromApi();

    // Swadishtt remains on Firebase.
    await _syncSwadishttFromFirebase();
  }

  static Future<void> _syncGroklyFromApi() async {
    try {
      debugPrint('Fetching Grokly products from VPS...');

      final List<GroklyProduct> loadedGrokly = [];
      var page = 1;
      var totalPages = 1;

      do {
        final response = await ApiService.fetchData(
          endpoint: '/g/products',
          queryParams: {
            'page': page.toString(),
            'limit': '100',
          },
          forceRefresh: true,
        );

        if (response is! Map || response['items'] is! List) {
          throw Exception(
            'Unexpected response from /g/products',
          );
        }

        final items = response['items'] as List;

        for (final item in items) {
          if (item is! Map) continue;

          final data = Map<String, dynamic>.from(item);

          double? toDouble(dynamic value) {
            if (value is num) return value.toDouble();
            return double.tryParse(value?.toString() ?? '');
          }

          int? toInt(dynamic value) {
            if (value is num) return value.toInt();
            return int.tryParse(value?.toString() ?? '');
          }

          final id =
              (data['id'] ?? data['product_id'] ?? '').toString();

          if (id.isEmpty) continue;

          loadedGrokly.add(
            GroklyProduct(
              id: id,
              name: (
                data['name'] ??
                data['product_name'] ??
                ''
              ).toString(),
              category: (
                data['category_name'] ??
                data['category'] ??
                ''
              ).toString(),
              subCategory: (
                data['sub_category'] ??
                data['subCategory'] ??
                data['subcategory'] ??
                ''
              ).toString(),
              size: (
                data['size'] ??
                data['unit'] ??
                ''
              ).toString(),
              brand: (data['brand'] ?? '').toString(),
              price: toDouble(
                data['price'] ?? data['selling_price'],
              ) ?? 0.0,
              imageUrl: (
                data['image_url'] ??
                data['imageUrl'] ??
                data['image'] ??
                ''
              ).toString(),
              mrp: toDouble(
                data['mrp'] ?? data['original_price'],
              ),
              rating: toDouble(data['rating']),
              ratingCount: toInt(
                data['rating_count'] ?? data['ratingCount'],
              ),
            ),
          );
        }

        totalPages = int.tryParse(
  response['totalPages']?.toString() ?? '',
) ?? page;
        page++;
      } while (page <= totalPages);

      if (loadedGrokly.isNotEmpty) {
        GroklyCatalog.dynamicAll = loadedGrokly;
        GroklyCatalog.isLoadedFromFirebase = true;
      }

      debugPrint(
        'Loaded ${loadedGrokly.length} Grokly products from VPS.',
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to fetch Grokly products from VPS: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Existing Swadishtt Firebase implementation preserved.
  static Future<void> _syncSwadishttFromFirebase() async {
    try {
      debugPrint('Fetching Swadishtt products from Firebase...');

      final foodSnap = await _db.collection('food_items').get();
      if (foodSnap.docs.isEmpty) return;

      final List<Product> loadedFood = [];

      for (final doc in foodSnap.docs) {
        final data = doc.data();

        data['id'] =
            data['id'] ?? ApiService.strongHashInt(doc.id);

        loadedFood.add(Product.fromJson(data));
      }

      ProductsData.dynamicFoodProducts = loadedFood;
      ProductsData.isLoadedFromFirebase = true;

      debugPrint(
        'Loaded ${loadedFood.length} Swadishtt products from Firebase.',
      );
    } catch (e) {
      debugPrint(
        'Error syncing Swadishtt products from Firebase: $e',
      );
    }
  }
}
