import 'package:flutter/material.dart';

class UnifiedCartItem {
  final String id;
  final String name;
  final String subtitle;
  final int unitPrice;
  final IconData? icon;
  final String? imageUrl;
  int qty;

  UnifiedCartItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.unitPrice,
    this.icon,
    this.imageUrl,
    this.qty = 1,
  });

  int get lineTotal => unitPrice * qty;
}

class UnifiedVendor {
  final String name;
  final IconData icon;
  final Color brandColor;
  final String deliveryLine;
  final List<UnifiedCartItem> items;

  UnifiedVendor({
    required this.name,
    required this.icon,
    required this.brandColor,
    required this.deliveryLine,
    required this.items,
  });

  int get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  int get unitCount => items.fold(0, (sum, i) => sum + i.qty);
}

class UnifiedCartState extends ChangeNotifier {
  static final UnifiedCartState instance = UnifiedCartState._internal();
  UnifiedCartState._internal();

  final List<UnifiedVendor> _vendors = [
    UnifiedVendor(
      name: 'Swadishtt',
      icon: Icons.restaurant,
      brandColor: Colors.red,
      deliveryLine: 'Restaurant delivery · Est. 25–35 min',
      items: [],
    ),
    UnifiedVendor(
      name: 'Grokly',
      icon: Icons.shopping_cart,
      brandColor: const Color(0xFF2E9E44), // green
      deliveryLine: 'Grocery & Essentials · Est. 15 min',
      items: [],
    ),

  ];

  List<UnifiedVendor> get vendors => _vendors;

  void addItem({
    required String vendorName,
    required String id,
    required String name,
    required String subtitle,
    required int unitPrice,
    IconData? icon,
    String? imageUrl,
  }) {
    final vendor = _vendors.firstWhere((v) => v.name == vendorName);
    final existingIndex = vendor.items.indexWhere((i) => i.id == id);
    if (existingIndex >= 0) {
      vendor.items[existingIndex].qty++;
    } else {
      vendor.items.add(UnifiedCartItem(
        id: id,
        name: name,
        subtitle: subtitle,
        unitPrice: unitPrice,
        icon: icon,
        imageUrl: imageUrl,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(String vendorName, String id, int change) {
    final vendor = _vendors.firstWhere((v) => v.name == vendorName);
    final existingIndex = vendor.items.indexWhere((i) => i.id == id);
    if (existingIndex >= 0) {
      vendor.items[existingIndex].qty += change;
      if (vendor.items[existingIndex].qty <= 0) {
        vendor.items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void clearVendor(String vendorName) {
    final vendor = _vendors.firstWhere((v) => v.name == vendorName);
    vendor.items.clear();
    notifyListeners();
  }
}
