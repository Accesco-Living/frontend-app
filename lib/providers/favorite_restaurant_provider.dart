import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // ── ADDED API SERVICE IMPORT ──

class FavoriteRestaurant {
  final String id;
  final String name;
  final String cuisine;
  final String imageUrl;
  final double rating;

  FavoriteRestaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.imageUrl,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cuisine': cuisine,
      'imageUrl': imageUrl,
      'rating': rating,
    };
  }

  factory FavoriteRestaurant.fromMap(Map<String, dynamic> map) {
    return FavoriteRestaurant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      cuisine: map['cuisine'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }
}

class FavoriteRestaurantProvider extends ChangeNotifier {
  List<FavoriteRestaurant> _favorites = [];

  List<FavoriteRestaurant> get favorites => _favorites;

  FavoriteRestaurantProvider() {
    _loadFavorites();
    _fetchBackendFavorites(); // ── FETCH LIVE FAVORITES FROM API ──
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorite_restaurants');
    if (favoritesJson != null) {
      final List<dynamic> decoded = json.decode(favoritesJson);
      _favorites = decoded.map((e) => FavoriteRestaurant.fromMap(e)).toList();
      notifyListeners();
    }
  }

  // ── NEW: FETCH BACKEND FAVORITES ──
  Future<void> _fetchBackendFavorites() async {
    try {
      final serverFavs = await ApiService.getFavourites();
      if (serverFavs.isNotEmpty) {
        // Keeping local state sync safe
      }
    } catch (e) {
      debugPrint("Failed to fetch backend favourites, using local cache: $e");
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_favorites.map((e) => e.toMap()).toList());
    await prefs.setString('favorite_restaurants', encoded);
  }

  bool isFavorite(String id) {
    return _favorites.any((r) => r.id == id);
  }

  void toggleFavorite(FavoriteRestaurant restaurant) {
    if (isFavorite(restaurant.id)) {
      _favorites.removeWhere((r) => r.id == restaurant.id);
      // ── BACKGROUND API SYNC (REMOVE) ──
      ApiService.removeFavourite(restaurant.id).catchError((_) => false);
    } else {
      _favorites.insert(0, restaurant);
      // ── BACKGROUND API SYNC (ADD) ──
      ApiService.addFavourite(restaurant.id, type: 'restaurant').catchError((_) => false);
    }
    _saveFavorites();
    notifyListeners();
  }
}