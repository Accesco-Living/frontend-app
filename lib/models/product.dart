class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String emoji;
  final String? imageUrl;
  final bool isVeg;
  final List<String>? selectedAddOns;
  final String? specialInstructions;
  final double? basePrice;
  final List<String>? tags;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.emoji,
    this.imageUrl,
    this.isVeg = false,
    this.selectedAddOns,
    this.specialInstructions,
    this.basePrice,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'emoji': emoji,
      'imageUrl': imageUrl,
      'isVeg': isVeg,
      if (selectedAddOns != null) 'selectedAddOns': selectedAddOns,
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
      if (basePrice != null) 'basePrice': basePrice,
      if (tags != null) 'tags': tags,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      emoji: json['emoji'] ?? '🍱',
      imageUrl: json['imageUrl'],
      isVeg: json['isVeg'] ?? false,
      selectedAddOns: json['selectedAddOns'] != null
          ? List<String>.from(json['selectedAddOns'])
          : null,
      specialInstructions: json['specialInstructions'],
      basePrice: json['basePrice'] != null ? (json['basePrice']).toDouble() : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }
}
