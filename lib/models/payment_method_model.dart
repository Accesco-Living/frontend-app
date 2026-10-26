class PaymentMethodModel {
  final String id;
  final String type; // 'card', 'upi', 'wallet', 'netbanking'
  final String title;
  final String subtitle;
  final String brandText;
  final bool isDefault;

  PaymentMethodModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.brandText,
    this.isDefault = false,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PaymentMethodModel(
      id: documentId,
      type: data['type'] ?? 'card',
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      brandText: data['brandText'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'brandText': brandText,
      'isDefault': isDefault,
    };
  }
}
