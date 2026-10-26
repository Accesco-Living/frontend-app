import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';
import 'order_tracking_screen.dart';
import '../services/api_service.dart';
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPayment = 'upi';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'upi',
      'title': 'UPI',
      'subtitle': 'GPay, PhonePe, Paytm',
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'card',
      'title': 'Credit/Debit Card',
      'subtitle': 'Visa, Mastercard, RuPay',
      'icon': Icons.credit_card,
    },
    {
      'id': 'netbanking',
      'title': 'Net Banking',
      'subtitle': 'All major banks',
      'icon': Icons.account_balance,
    },
    {
      'id': 'cod',
      'title': 'Cash on Delivery',
      'subtitle': 'Pay at doorstep',
      'icon': Icons.money,
    },
  ];

  bool _isProcessing = false;

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final cart = Provider.of<CartProvider>(context, listen: false);
    final trackingItems = cart.items
        .map(
          (item) => OrderTrackingItem(
            name: item.product.name,
            quantity: item.quantity,
            price: item.product.price,
            selectedAddOns: item.product.selectedAddOns,
            specialInstructions: item.product.specialInstructions,
          ),
        )
        .toList();
    final orderTotal = cart.total;
    final restaurantName = trackingItems.isNotEmpty
        ? trackingItems.first.name.contains('Thali')
            ? 'Thali Engine'
            : 'Swad House Kitchen'
        : 'Swad House Kitchen';

    final firestoreItems = cart.items.map((item) {
      return {
        'name': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
        'image': item.product.imageUrl ?? 'assets/Swadishtt/burger.png',
        if (item.product.selectedAddOns != null)
          'selectedAddOns': item.product.selectedAddOns,
        if (item.product.specialInstructions != null)
          'specialInstructions': item.product.specialInstructions,
      };
    }).toList();

    final paymentMethodTitle = _paymentMethods
        .firstWhere((m) => m['id'] == _selectedPayment)['title'] as String;

    // ── FIRE API CHECKOUT TO VPS BACKEND ──
    try {
      await ApiService.checkoutCart(orderTotal.toInt());
    } catch (e) {
      debugPrint("API Checkout failed, using fallback: \$e");
    }

    // Simulate network processing delay for smooth UI feedback
    await Future.delayed(const Duration(milliseconds: 1500));

    // Write to Firebase Firestore with generated Invoice (Local Fallback & UI Sync)
    await FirebaseService.createOrder(
      restaurantName: restaurantName,
      restaurantImage: 'assets/Swadishtt/spaghetti bolognese.png',
      totalAmount: orderTotal,
      items: firestoreItems,
      paymentMethod: paymentMethodTitle,
    );

    cart.clearCart();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            items: trackingItems,
            total: orderTotal,
            restaurantName: restaurantName,
            paymentMethod: paymentMethodTitle,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Swadishtt Red Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC62828), Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.payment,
                                  size: 14, color: Colors.white.withValues(alpha: 0.9)),
                              const SizedBox(width: 4),
                              const Text(
                                'Choose Payment Option',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount to Pay
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE53935).withOpacity(0.08),
                            const Color(0xFFFFF3E0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFCC80)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount to Pay',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${cart.total.toInt()}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Methods
                    ..._paymentMethods.map((method) {
                      final isSelected = _selectedPayment == method['id'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedPayment = method['id']),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFEDE0)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFE53935)
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE53935)
                                            .withOpacity(0.12)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    method['icon'],
                                    color: isSelected
                                        ? const Color(0xFFE53935)
                                        : Colors.grey.shade600,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        method['title'],
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? const Color(0xFFE53935)
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        method['subtitle'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFE53935),
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            // Pay Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedPayment == 'cod'
                            ? 'PAY AT DELIVERY'
                            : 'PAY NOW',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${cart.total.toInt()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      if (_isProcessing)
        Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Processing Payment...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Please wait while we confirm your order',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  ),
);
  }
}
