import 'package:flutter/material.dart';

class StoreSpend {
  final String storeName;
  final String categoryName;
  final double amount;
  final Color color;
  final IconData icon;
  final String imagePath;

  const StoreSpend({
    required this.storeName,
    required this.categoryName,
    required this.amount,
    required this.color,
    required this.icon,
    this.imagePath = '',
  });
}
