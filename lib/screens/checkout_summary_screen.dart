import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'return_containers_screen.dart';
import 'checkout_screen.dart';
import 'item_details_screen.dart';

class CheckoutSummaryScreen extends StatefulWidget {
  final List<ReturnContainer> selectedContainers;

  const CheckoutSummaryScreen({super.key, required this.selectedContainers});

  @override
  State<CheckoutSummaryScreen> createState() => _CheckoutSummaryScreenState();
}

class _CheckoutSummaryScreenState extends State<CheckoutSummaryScreen> {
  static const Color _kPrimaryRed = Color(0xFFC00A27);
  static const Color _kBgColor = Color(0xFFFAFAFA);
  static const Color _kLightPinkBg = Color(0xFFFFF5F6);

  bool _handBackToRider = true;

  double get _totalDiscount {
    double total = 0;
    for (var c in widget.selectedContainers) {
      if (c.isSelected) total += (c.pricePerPiece * c.quantity);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    // Filter only selected containers with quantity > 0
    final validContainers = widget.selectedContainers.where((c) => c.isSelected && c.quantity > 0).toList();

    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context, _totalDiscount), // Pass back discount on manual back
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // YOUR ORDER Section
                  Text(
                    'YOUR ORDER',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // Restaurant Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: _kLightPinkBg),
                                child: Image.asset('assets/Swadishtt/swadishtt_logo.png', width: 24, height: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Swadishtt - Madhapur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                    SizedBox(height: 2),
                                    Text('Arriving in 20 mins', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
                        // Food Items
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ...cart.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.product.name} * ${item.quantity}',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                                        ),
                                      ),
                                      Text(
                                        '₹${(item.product.price * item.quantity).toInt()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 4),
                              Divider(height: 1, color: Colors.grey.shade200),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                  Text(
                                    '₹${cart.subtotal.toInt()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // RETURN CONTAINERS Section
                  if (validContainers.isNotEmpty) ...[
                    Text(
                      'RETURN CONTAINERS WITH THIS ORDER',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Toggle Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDF7F0), // Slight tint as in mockup
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.recycling, color: _kPrimaryRed, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Hand back to the rider', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                                ),
                                Switch(
                                  value: _handBackToRider,
                                  onChanged: (val) {
                                    setState(() {
                                      _handBackToRider = val;
                                    });
                                  },
                                  activeColor: Colors.white,
                                  activeTrackColor: _kPrimaryRed,
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          
                          // Container Items
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: validContainers.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color: _kPrimaryRed,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item.name} * ${item.quantity}',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.type.replaceAll('•', '·'),
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '+₹${(item.pricePerPiece * item.quantity).toInt()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E8449)),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Return points banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kLightPinkBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard, color: _kPrimaryRed, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Return and earn Green Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text(
                                  'Earning ₹${_totalDiscount.toInt()} on return with this order',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to item details for the first container, or just return discount
                  if (validContainers.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    );
                  } else {
                     Navigator.pop(context, 0.0);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed To Checkout',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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
