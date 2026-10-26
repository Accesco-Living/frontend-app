import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/products_data.dart';

class BookmarkProvider extends ChangeNotifier {
  List<String> _savedGroklyIds = [];
  List<int> _savedSwadishttIds = [];

  Map<int, Map<String, dynamic>> _savedSwadishttProductsMap = {};
  Map<String, Map<String, dynamic>> _savedGroklyProductsMap = {};

  List<String> get savedGroklyIds => _savedGroklyIds;
  List<int> get savedSwadishttIds => _savedSwadishttIds;

  List<Map<String, dynamic>> get savedSwadishttItems {
    final List<Map<String, dynamic>> list = [];
    
    // First include explicitly saved product maps
    _savedSwadishttProductsMap.forEach((id, item) {
      if (_savedSwadishttIds.contains(id)) {
        list.add(item);
      }
    });

    // Also check static ProductsData for any ID saved by ID alone
    for (var id in _savedSwadishttIds) {
      if (!_savedSwadishttProductsMap.containsKey(id)) {
        final matches = ProductsData.getAllProducts().where((p) => p.id == id).toList();
        if (matches.isNotEmpty) {
          final p = matches.first;
          list.add({
            'id': p.id,
            'name': p.name,
            'brand': 'Swadishtt',
            'rating': '4.5',
            'price': '₹${p.price.toInt()}',
            'image': (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                ? p.imageUrl
                : 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=200&fit=crop',
            'selected': false,
          });
        }
      }
    }

    return list;
  }

  List<Map<String, dynamic>> get savedGroklyItems {
    final List<Map<String, dynamic>> list = [];
    _savedGroklyProductsMap.forEach((id, item) {
      if (_savedGroklyIds.contains(id)) {
        list.add(item);
      }
    });
    return list;
  }

  BookmarkProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedGroklyIds = prefs.getStringList('saved_grokly') ?? [];
      final swadishttStrs = prefs.getStringList('saved_swadishtt') ?? [];
      _savedSwadishttIds = swadishttStrs.map((e) => int.tryParse(e) ?? 0).where((id) => id != 0).toList();

      // Load saved products maps
      final swadishttJsonStr = prefs.getString('saved_swadishtt_products_map') ?? '{}';
      final Map<String, dynamic> decodedSwadishtt = jsonDecode(swadishttJsonStr);
      _savedSwadishttProductsMap = decodedSwadishtt.map((key, value) => MapEntry(int.parse(key), Map<String, dynamic>.from(value)));

      final groklyJsonStr = prefs.getString('saved_grokly_products_map') ?? '{}';
      final Map<String, dynamic> decodedGrokly = jsonDecode(groklyJsonStr);
      _savedGroklyProductsMap = decodedGrokly.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));

      // Sync with Firestore if logged in
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('saved_items').get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['swadishtt_ids'] != null) {
            final List<dynamic> ids = data['swadishtt_ids'];
            for (var id in ids) {
              final intId = (id is num) ? id.toInt() : int.tryParse(id.toString()) ?? 0;
              if (intId != 0 && !_savedSwadishttIds.contains(intId)) {
                _savedSwadishttIds.add(intId);
              }
            }
          }
          if (data['swadishtt_items'] != null) {
            final List<dynamic> items = data['swadishtt_items'];
            for (var item in items) {
              final map = Map<String, dynamic>.from(item as Map);
              final id = (map['id'] is num) ? (map['id'] as num).toInt() : int.tryParse(map['id'].toString()) ?? 0;
              if (id != 0) {
                _savedSwadishttProductsMap[id] = map;
                if (!_savedSwadishttIds.contains(id)) _savedSwadishttIds.add(id);
              }
            }
          }
        }
      }

      // If empty, pre-populate default favourite items so Saved is never blank
      if (_savedSwadishttIds.isEmpty && _savedSwadishttProductsMap.isEmpty) {
        _savedSwadishttIds = [122, 116, 109];
        _savedSwadishttProductsMap = {
          122: {
            'id': 122,
            'name': 'Appam',
            'brand': 'Swadishtt',
            'rating': '4.8',
            'price': '₹95',
            'image': 'https://i.pinimg.com/1200x/0d/f8/9b/0df89b42ac5d8c9d36085187938c1fb2.jpg',
            'selected': false,
          },
          116: {
            'id': 116,
            'name': 'Masala Dosa',
            'brand': 'Swadishtt',
            'rating': '4.7',
            'price': '₹80',
            'image': 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8bWFzYWxhJTIwZG9zYXxlbnwwfHwwfHx8MA%3D%3D&fit=crop',
            'selected': false,
          },
          109: {
            'id': 109,
            'name': 'Paneer Butter Masala',
            'brand': 'Swadishtt',
            'rating': '4.9',
            'price': '₹240',
            'image': 'https://img.freepik.com/premium-photo/delicious-paneer-butter-masala-photography_928503-851.jpg?w=2000&fit=crop',
            'selected': false,
          },
        };
      }

      if (_savedGroklyIds.isEmpty && _savedGroklyProductsMap.isEmpty) {
        _savedGroklyIds = ['b1', 'v1', 'f1'];
        _savedGroklyProductsMap = {
          'b1': {
            'id': 'b1',
            'name': 'Organic Basmati Rice',
            'brand': 'Grokly Essentials',
            'rating': '4.6',
            'price': '₹180',
            'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&auto=format&fit=crop&q=60',
            'selected': false,
          },
          'v1': {
            'id': 'v1',
            'name': 'Fresh Organic Tomatoes',
            'brand': 'Grokly Fresh',
            'rating': '4.5',
            'price': '₹40',
            'image': 'https://www.themealdb.com/images/ingredients/Tomatoes.png',
            'selected': false,
          },
          'f1': {
            'id': 'f1',
            'name': 'Alphonso Mangoes',
            'brand': 'Grokly Farms',
            'rating': '4.9',
            'price': '₹150',
            'image': 'https://www.themealdb.com/images/ingredients/Mango.png',
            'selected': false,
          },
        };
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
    notifyListeners();
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_grokly', _savedGroklyIds);
      await prefs.setStringList('saved_swadishtt', _savedSwadishttIds.map((e) => e.toString()).toList());

      final encSwadishttMap = _savedSwadishttProductsMap.map((key, value) => MapEntry(key.toString(), value));
      await prefs.setString('saved_swadishtt_products_map', jsonEncode(encSwadishttMap));

      final encGroklyMap = _savedGroklyProductsMap;
      await prefs.setString('saved_grokly_products_map', jsonEncode(encGroklyMap));

      // Sync to Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('saved_items').set({
          'swadishtt_ids': _savedSwadishttIds,
          'swadishtt_items': _savedSwadishttProductsMap.values.toList(),
          'grokly_ids': _savedGroklyIds,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  bool isGroklySaved(String id) => _savedGroklyIds.contains(id);
  bool isSwadishttSaved(int id) => _savedSwadishttIds.contains(id);

  void toggleGrokly(String id) {
    if (_savedGroklyIds.contains(id)) {
      _savedGroklyIds.remove(id);
      _savedGroklyProductsMap.remove(id);
    } else {
      _savedGroklyIds.add(id);
    }
    _saveBookmarks();
    notifyListeners();
  }

  void toggleSwadishtt(int id) {
    if (_savedSwadishttIds.contains(id)) {
      _savedSwadishttIds.remove(id);
      _savedSwadishttProductsMap.remove(id);
    } else {
      _savedSwadishttIds.add(id);
    }
    _saveBookmarks();
    notifyListeners();
  }

  void toggleSwadishttProduct(Product product) {
    if (_savedSwadishttIds.contains(product.id)) {
      _savedSwadishttIds.remove(product.id);
      _savedSwadishttProductsMap.remove(product.id);
    } else {
      _savedSwadishttIds.add(product.id);
      _savedSwadishttProductsMap[product.id] = {
        'id': product.id,
        'name': product.name,
        'brand': 'Swadishtt',
        'rating': '4.8',
        'price': '₹${product.price.toInt()}',
        'image': (product.imageUrl != null && product.imageUrl!.isNotEmpty)
            ? product.imageUrl
            : 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=200&fit=crop',
        'selected': false,
      };
    }
    _saveBookmarks();
    notifyListeners();
  }
}
