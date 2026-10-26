/// Model representing an individual predicted item in the Sixth Sense basket.
class SixthSenseItem {
  final String productId;
  final int quantity;
  final String reason;

  SixthSenseItem({
    required this.productId,
    required this.quantity,
    required this.reason,
  });

  factory SixthSenseItem.fromMap(Map<String, dynamic> map) {
    return SixthSenseItem(
      productId: map['productId'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ??
          (map['qty'] as num?)?.toInt() ??
          1,
      reason: map['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'reason': reason,
    };
  }
}

/// Model representing the dynamic weekly predicted Sixth Sense basket.
class SixthSenseBasket {
  final double? accuracyScore;
  final String predictedDate;
  final double totalPrice;
  final List<SixthSenseItem> items;
  final List<String> crossVentureNotes;

  SixthSenseBasket({
    this.accuracyScore,
    required this.predictedDate,
    required this.totalPrice,
    required this.items,
    required this.crossVentureNotes,
  });

  factory SixthSenseBasket.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => SixthSenseItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    final rawNotes = map['crossVentureNotes'] as List<dynamic>? ?? [];
    final notesList = rawNotes.map((note) => note.toString()).toList();

    return SixthSenseBasket(
      accuracyScore: (map['accuracyScore'] as num?)?.toDouble(),
      predictedDate: map['predictedDate'] as String? ?? 'Sunday Morning',
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      items: itemsList,
      crossVentureNotes: notesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accuracyScore': accuracyScore,
      'predictedDate': predictedDate,
      'totalPrice': totalPrice,
      'items': items.map((i) => i.toMap()).toList(),
      'crossVentureNotes': crossVentureNotes,
    };
  }

  SixthSenseBasket copyWith({
    double? accuracyScore,
    String? predictedDate,
    double? totalPrice,
    List<SixthSenseItem>? items,
    List<String>? crossVentureNotes,
  }) {
    return SixthSenseBasket(
      accuracyScore: accuracyScore ?? this.accuracyScore,
      predictedDate: predictedDate ?? this.predictedDate,
      totalPrice: totalPrice ?? this.totalPrice,
      items: items ?? this.items,
      crossVentureNotes: crossVentureNotes ?? this.crossVentureNotes,
    );
  }
}
