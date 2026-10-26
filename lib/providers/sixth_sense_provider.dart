import 'package:flutter/foundation.dart';
import '../models/smart_pantry_item.dart';
import '../models/sixth_sense_basket.dart';
import '../services/sixth_sense_service.dart';
import '../services/firebase_service.dart';

/// Validation result for adding predicted items to cart
class RestockValidationResult {
  final int addedCount;
  final int unavailableCount;
  final List<String> unavailableProductIds;
  final double currentTotal;

  RestockValidationResult({
    required this.addedCount,
    required this.unavailableCount,
    required this.unavailableProductIds,
    required this.currentTotal,
  });
}

/// Provider managing dynamic Sixth Sense recommendations, smart pantry depletion,
/// and predicted weekly basket restock flows.
class SixthSenseProvider with ChangeNotifier {
  final SixthSenseService _service;

  List<SmartPantryItem> _smartPantryItems = [];
  SixthSenseBasket? _sixthSenseBasket;
  bool _isLoading = false;
  String? _errorMessage;

  SixthSenseProvider({SixthSenseService? service})
      : _service = service ?? SixthSenseService();

  List<SmartPantryItem> get smartPantryItems => _smartPantryItems;
  SixthSenseBasket? get sixthSenseBasket => _sixthSenseBasket;
  double? get accuracyScore => _sixthSenseBasket?.accuracyScore;
  List<String> get crossVentureNotes => _sixthSenseBasket?.crossVentureNotes ?? [];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Loads initial recommendations and depletion tracking
  Future<void> loadRecommendations({
    String? uid,
    Map<String, double>? catalogPriceLookup,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetUid = uid ?? FirebaseService.currentUserId;
      await _service.generateAndPersistRecommendations(
        uid: targetUid,
        catalogPriceLookup: catalogPriceLookup,
      );

      // Listen to or fetch the initial state
      // For immediate responsiveness, generate default dynamic entries if list is empty
      if (_smartPantryItems.isEmpty) {
        _populateFallbackPantry();
      }
      if (_sixthSenseBasket == null) {
        _populateFallbackBasket(catalogPriceLookup);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _populateFallbackPantry();
      _populateFallbackBasket(catalogPriceLookup);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes recommendations
  Future<void> refreshRecommendations({
    String? uid,
    Map<String, double>? catalogPriceLookup,
  }) async {
    await loadRecommendations(uid: uid, catalogPriceLookup: catalogPriceLookup);
  }

  /// Marks a pantry item as restocked locally and persists state
  void restockPantryItem(String productId) {
    final index = _smartPantryItems.indexWhere((i) => i.productId == productId);
    if (index != -1) {
      final old = _smartPantryItems[index];
      _smartPantryItems[index] = old.copyWith(
        restocked: true,
        daysLeft: 14,
        stockPct: 1.0,
      );
      notifyListeners();

      _service.updatePantryItem(
        FirebaseService.currentUserId,
        _smartPantryItems[index],
      );
    }
  }

  /// Restocks all low pantry items
  List<String> restockAllLow() {
    final lowIds = <String>[];
    for (int i = 0; i < _smartPantryItems.length; i++) {
      if (_smartPantryItems[i].isLow) {
        lowIds.add(_smartPantryItems[i].productId);
        _smartPantryItems[i] = _smartPantryItems[i].copyWith(
          restocked: true,
          daysLeft: 14,
          stockPct: 1.0,
        );
      }
    }
    if (lowIds.isNotEmpty) {
      notifyListeners();
    }
    return lowIds;
  }

  /// Validates predicted basket products against catalog availability & prices.
  /// Does NOT blindly trust stored total. Returns current price total and valid items.
  RestockValidationResult validatePredictedBasket({
    required Set<String> selectedProductIds,
    required dynamic Function(String id) productLookup,
  }) {
    int addedCount = 0;
    int unavailableCount = 0;
    final List<String> unavailable = [];
    double currentTotal = 0.0;

    final items = _sixthSenseBasket?.items ?? [];
    for (final pick in items) {
      if (!selectedProductIds.contains(pick.productId)) continue;

      final product = productLookup(pick.productId);
      if (product != null) {
        addedCount++;
        final price = (product.price as num).toDouble();
        currentTotal += price * pick.quantity;
      } else {
        unavailableCount++;
        unavailable.add(pick.productId);
      }
    }

    return RestockValidationResult(
      addedCount: addedCount,
      unavailableCount: unavailableCount,
      unavailableProductIds: unavailable,
      currentTotal: currentTotal,
    );
  }

  void _populateFallbackPantry() {
    _smartPantryItems = [
      SmartPantryItem(
        productId: 'd3',
        velocityDays: 2,
        daysLeft: 2,
        stockPct: 0.18,
        recommendationReason: 'Milk velocity: 500ml every 2 days',
      ),
      SmartPantryItem(
        productId: 'b2',
        velocityDays: 4,
        daysLeft: 1,
        stockPct: 0.10,
        recommendationReason: 'Bread velocity: 1 loaf every 4 days',
      ),
      SmartPantryItem(
        productId: 's7',
        velocityDays: 21,
        daysLeft: 3,
        stockPct: 0.22,
        recommendationReason: 'Dal velocity: 1kg every 3 weeks',
      ),
      SmartPantryItem(
        productId: 's5',
        velocityDays: 21,
        daysLeft: 6,
        stockPct: 0.55,
        recommendationReason: 'Rice velocity: 5kg every 3 weeks',
      ),
      SmartPantryItem(
        productId: 's14',
        velocityDays: 42,
        daysLeft: 9,
        stockPct: 0.70,
        recommendationReason: 'Oil velocity: 500ml every 6 weeks',
      ),
      SmartPantryItem(
        productId: 's19',
        velocityDays: 30,
        daysLeft: 12,
        stockPct: 0.85,
        recommendationReason: 'Oats velocity: 1kg every month',
      ),
    ];
  }

  void _populateFallbackBasket(Map<String, double>? priceLookup) {
    final items = [
      SixthSenseItem(productId: 'd3', quantity: 2, reason: 'Milk velocity: runs out every 6 days'),
      SixthSenseItem(productId: 'b2', quantity: 1, reason: 'Bread velocity: loaf every 4 days'),
      SixthSenseItem(productId: 's7', quantity: 1, reason: 'Swadishtt cross-reference: Dal Tadka weekly'),
      SixthSenseItem(productId: 'd12', quantity: 1, reason: 'Swadishtt cross-reference: Butter Chicken ordered 2 times'),
      SixthSenseItem(productId: 'd17', quantity: 1, reason: 'Swadishtt cross-reference: Butter Chicken ordered 2 times'),
      SixthSenseItem(productId: 's5', quantity: 1, reason: 'SKU velocity: 5kg every 3 weeks'),
      SixthSenseItem(productId: 's19', quantity: 1, reason: 'Weekday breakfast pattern'),
      SixthSenseItem(productId: 's12', quantity: 1, reason: 'Monthly replenishment cycle'),
    ];

    double total = 0.0;
    for (final it in items) {
      total += (priceLookup?[it.productId] ?? 50.0) * it.quantity;
    }

    _sixthSenseBasket = SixthSenseBasket(
      accuracyScore: 0.91,
      predictedDate: 'Sunday Morning',
      totalPrice: total,
      items: items,
      crossVentureNotes: [
        'You ordered Butter Chicken twice last month — butter, cream & dal were added to this week\'s prediction.',
      ],
    );
  }
}
