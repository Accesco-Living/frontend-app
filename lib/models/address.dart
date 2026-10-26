class AddressModel {
  final String id;
  final String type; // e.g., Home, Work, Parents
  final String fullAddress;
  bool isDefault;

  AddressModel({
    required this.id,
    required this.type,
    required this.fullAddress,
    this.isDefault = false,
  });

  factory AddressModel.fromMap(String id, Map<String, dynamic> data) {
    return AddressModel(
      id: id,
      type: data['type'] ?? 'Home',
      fullAddress: data['fullAddress'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fullAddress': fullAddress,
      'isDefault': isDefault,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}