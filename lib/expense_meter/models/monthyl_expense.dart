import '../models/store_spend.dart';
import 'package:flutter/material.dart';

class MonthlyExpenseData {
  final String monthYear;
  final double totalBudget;
  final List<StoreSpend> storeSpends;
  final double growthPercentage;

  const MonthlyExpenseData({
    required this.monthYear,
    required this.totalBudget,
    required this.storeSpends,
    required this.growthPercentage,
  });

  double get totalSpent {
    double sum = 0.0;
    for (int i = 0; i < storeSpends.length; i++) {
      sum += storeSpends[i].amount;
    }
    return sum;
  }

  double get remainingBudget =>
      (totalBudget - totalSpent) < 0 ? 0.0 : (totalBudget - totalSpent);

  double get spentRatio =>
      totalBudget <= 0 ? 0.0 : (totalSpent / totalBudget).clamp(0.0, 1.0);

  int get spentPercentage =>
      totalBudget <= 0 ? 0 : ((totalSpent / totalBudget) * 100).round();

  StoreSpend get biggestCategory {
    if (storeSpends.isEmpty) {
      return const StoreSpend(
        storeName: 'None',
        categoryName: 'General',
        amount: 0.0,
        color: Color(0xFF7B0041),
        icon: Icons.shopping_bag_outlined,
      );
    }
    StoreSpend maxSpend = storeSpends.first;
    for (var s in storeSpends) {
      if (s.amount > maxSpend.amount) {
        maxSpend = s;
      }
    }
    return maxSpend;
  }
}
