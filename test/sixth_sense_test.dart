import 'package:flutter_test/flutter_test.dart';
import 'package:accesco_living_app/models/smart_pantry_item.dart';
import 'package:accesco_living_app/models/sixth_sense_basket.dart';
import 'package:accesco_living_app/services/purchase_velocity_service.dart';
import 'package:accesco_living_app/services/cross_venture_engine.dart';
import 'package:accesco_living_app/services/sixth_sense_service.dart';

void main() {
  group('Sixth Sense AI & Cross-Venture Consumption Engine Tests', () {
    test('1. Purchase velocity calculation: [1, 5, 9, 13 Sept] -> 4 days', () {
      final purchaseDates = [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 9),
        DateTime(2026, 9, 13),
      ];

      final velocityDays = PurchaseVelocityService.calculateVelocityDays(purchaseDates);
      expect(velocityDays, equals(4));
    });

    test('2. Next restock date prediction: last purchase 13 Sept + 4 days -> 17 Sept', () {
      final purchaseDates = [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 9),
        DateTime(2026, 9, 13),
      ];

      final nextDate = PurchaseVelocityService.estimateNextRestockDate(purchaseDates);
      expect(nextDate, isNotNull);
      expect(nextDate!.year, equals(2026));
      expect(nextDate.month, equals(9));
      expect(nextDate.day, equals(17));
    });

    test('3. Fallback on insufficient purchase history: single purchase -> null prediction', () {
      final singlePurchase = [
        DateTime(2026, 9, 10),
      ];

      final velocity = PurchaseVelocityService.calculateVelocityDays(singlePurchase);
      expect(velocity, isNull, reason: 'Must return null with fewer than 2 purchases');

      final restockDate = PurchaseVelocityService.estimateNextRestockDate(singlePurchase);
      expect(restockDate, isNull, reason: 'Must return null restock date without sufficient history');

      final emptyVelocity = PurchaseVelocityService.calculateVelocityDays([]);
      expect(emptyVelocity, isNull, reason: 'Must return null with 0 purchases');
    });

    test('4. Cross-venture recommendation: Butter Chicken ordered 2+ times -> grocery ingredients generated', () {
      final engine = CrossVentureEngine(minimumOrderThreshold: 2);
      final dishCounts = {
        'Butter Chicken': 2,
      };

      final candidates = engine.evaluateDishFrequencies(dishCounts);
      expect(candidates, isNotEmpty);

      // Verify mapped ingredients for Butter Chicken: d12 (Butter), d17 (Fresh Cream), s7 (Spices/Dal)
      final productIds = candidates.map((c) => c.productId).toList();
      expect(productIds, contains('d12'));
      expect(productIds, contains('d17'));
      expect(productIds, contains('s7'));

      final first = candidates.first;
      expect(first.dishName, equals('Butter Chicken'));
      expect(first.orderCount, equals(2));
      expect(first.reason, contains('Swadishtt cross-reference: Butter Chicken ordered 2 times'));
    });

    test('5. Cross-venture threshold: Butter Chicken ordered 1 time -> no aggressive recommendations', () {
      final engine = CrossVentureEngine(minimumOrderThreshold: 2);
      final singleOrderCount = {
        'Butter Chicken': 1,
      };

      final candidates = engine.evaluateDishFrequencies(singleOrderCount);
      expect(candidates, isEmpty,
          reason: 'Strict threshold >= 2 orders required before triggering grocery recommendations');
    });

    test('6. Smart Pantry depletion calculation: velocity=4, elapsed=3 -> daysLeft=1, stockPct=0.25, isLow=true', () {
      final lastPurchase = DateTime(2026, 9, 10);
      final currentDate = DateTime(2026, 9, 13); // 3 days elapsed

      final depletion = PurchaseVelocityService.calculateStockDepletion(
        velocityDays: 4,
        lastPurchaseDate: lastPurchase,
        referenceDate: currentDate,
      );

      final daysLeft = depletion['daysLeft'] as int;
      final stockPct = depletion['stockPct'] as double;

      expect(daysLeft, equals(1));
      expect(stockPct, closeTo(0.25, 0.01));

      final pantryItem = SmartPantryItem(
        productId: 'd3',
        velocityDays: 4,
        daysLeft: daysLeft,
        stockPct: stockPct,
        recommendationReason: 'Velocity: runs out every 4 days',
      );

      expect(pantryItem.isLow, isTrue,
          reason: 'Item with <= 3 days left or <= 25% stock should trigger low stock alert');
    });

    test('7. SixthSenseService dynamic accuracy score & basket model', () {
      final predicted = ['d3', 'b2', 's7', 'd12'];
      final actual = ['d3', 'b2', 's7']; // 3 out of 4 correct

      final accuracy = SixthSenseService.calculateAccuracyScore(
        predictedProductIds: predicted,
        actualPurchasedProductIds: actual,
      );

      expect(accuracy, equals(0.75));

      final emptyAccuracy = SixthSenseService.calculateAccuracyScore(
        predictedProductIds: [],
        actualPurchasedProductIds: actual,
      );
      expect(emptyAccuracy, isNull, reason: 'Empty predicted items should return null');

      // Test SixthSenseBasket model serialization round-trip
      final basket = SixthSenseBasket(
        accuracyScore: accuracy,
        predictedDate: 'Sunday Morning',
        totalPrice: 285.0,
        items: [
          SixthSenseItem(productId: 'd3', quantity: 2, reason: 'Every 4 days'),
          SixthSenseItem(productId: 'd12', quantity: 1, reason: 'Cross-ref Butter Chicken'),
        ],
        crossVentureNotes: ['Cross-referenced with Swadishtt: Butter Chicken ordered 2 times'],
      );

      final map = basket.toMap();
      final reconstructed = SixthSenseBasket.fromMap(map);

      expect(reconstructed.accuracyScore, equals(0.75));
      expect(reconstructed.totalPrice, equals(285.0));
      expect(reconstructed.items.length, equals(2));
      expect(reconstructed.items.first.productId, equals('d3'));
      expect(reconstructed.items.first.quantity, equals(2));
      expect(reconstructed.crossVentureNotes.length, equals(1));
    });
  });
}
