import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to analyze historical purchasing behavior and calculate SKU purchase velocity.
class PurchaseVelocityService {
  final FirebaseFirestore _firestore;

  PurchaseVelocityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Computes average purchase cycle interval in days.
  /// If a SKU has fewer than 2 distinct purchases, returns null (insufficient history).
  static int? calculateVelocityDays(List<DateTime> purchaseDates) {
    if (purchaseDates.length < 2) {
      return null;
    }

    final sorted = List<DateTime>.from(purchaseDates)..sort();
    int totalIntervalDays = 0;
    int intervalCount = 0;

    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff > 0) {
        totalIntervalDays += diff;
        intervalCount++;
      }
    }

    if (intervalCount == 0) return null;
    return (totalIntervalDays / intervalCount).round();
  }

  /// Estimates the next replenishment / restock date based on average velocity.
  static DateTime? estimateNextRestockDate(List<DateTime> purchaseDates) {
    final velocity = calculateVelocityDays(purchaseDates);
    if (velocity == null) return null;

    final sorted = List<DateTime>.from(purchaseDates)..sort();
    return sorted.last.add(Duration(days: velocity));
  }

  /// Computes days left and stock percentage from velocity and last purchase date.
  static Map<String, dynamic> calculateStockDepletion({
    required int velocityDays,
    required DateTime lastPurchaseDate,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final daysSince = now.difference(lastPurchaseDate).inDays;
    final daysLeft = (velocityDays - daysSince).clamp(0, velocityDays);
    final stockPct = velocityDays > 0
        ? double.parse((daysLeft / velocityDays).toStringAsFixed(2)).clamp(0.0, 1.0)
        : 0.0;

    return {
      'daysLeft': daysLeft,
      'stockPct': stockPct,
    };
  }

  /// Fetches historical orders from Firestore `users/{uid}/orders`.
  /// Returns a map of productId -> List<DateTime> purchase timestamps.
  Future<Map<String, List<DateTime>>> fetchPurchaseHistory(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('orders')
          .orderBy('createdAt', descending: false)
          .get();

      final Map<String, List<DateTime>> history = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        DateTime? orderDate;
        if (data['createdAt'] is Timestamp) {
          orderDate = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          orderDate = DateTime.tryParse(data['createdAt'] as String);
        } else if (data['date'] is String) {
          orderDate = DateTime.tryParse(data['date'] as String);
        }

        if (orderDate == null) continue;

        final items = data['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          if (item is Map) {
            final pid = (item['productId'] ?? item['id'])?.toString();
            if (pid != null && pid.isNotEmpty) {
              history.putIfAbsent(pid, () => []).add(orderDate);
            }
          }
        }
      }

      return history;
    } catch (_) {
      // Fallback for offline or empty orders
      return {};
    }
  }
}
