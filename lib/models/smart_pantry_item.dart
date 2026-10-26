/// Model representing a tracked product in the user's Smart Pantry.
class SmartPantryItem {
  final String productId;
  final int velocityDays;
  final int daysLeft;
  final double stockPct;
  final String recommendationReason;
  final bool restocked;

  SmartPantryItem({
    required this.productId,
    required this.velocityDays,
    required this.daysLeft,
    required this.stockPct,
    required this.recommendationReason,
    this.restocked = false,
  });

  /// True if item is running low (<= 3 days or stock <= 25%)
  bool get isLow => !restocked && (daysLeft <= 3 || stockPct <= 0.25);

  /// Safe deserialization from Firestore / Map
  factory SmartPantryItem.fromMap(Map<String, dynamic> map) {
    return SmartPantryItem(
      productId: map['productId'] as String? ?? '',
      velocityDays: (map['velocityDays'] as num?)?.toInt() ?? 0,
      daysLeft: (map['daysLeft'] as num?)?.toInt() ?? 0,
      stockPct: (map['stockPct'] as num?)?.toDouble() ?? 0.0,
      recommendationReason: map['recommendationReason'] as String? ?? '',
      restocked: map['restocked'] as bool? ?? false,
    );
  }

  /// Serialization to Firestore / Map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'velocityDays': velocityDays,
      'daysLeft': daysLeft,
      'stockPct': stockPct,
      'recommendationReason': recommendationReason,
      'restocked': restocked,
    };
  }

  SmartPantryItem copyWith({
    String? productId,
    int? velocityDays,
    int? daysLeft,
    double? stockPct,
    String? recommendationReason,
    bool? restocked,
  }) {
    return SmartPantryItem(
      productId: productId ?? this.productId,
      velocityDays: velocityDays ?? this.velocityDays,
      daysLeft: daysLeft ?? this.daysLeft,
      stockPct: stockPct ?? this.stockPct,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      restocked: restocked ?? this.restocked,
    );
  }
}
