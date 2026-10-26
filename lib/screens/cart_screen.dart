import 'package:accesco_living_app/screens/swadisht_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';
import 'checkout_delivery_address_screen.dart';
import 'return_containers_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _kPrimaryRed = Color(0xFFC00A27);
  static const Color _kLightBg = Color(0xFFFFF7F5);
  static const Color _kBgWhite = Colors.white;

  double _returnDiscount = 0.0;

  final currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    // Calculate new total considering fees
    final double itemTotal = cart.subtotal;
    final double platformFee = 10.0;
    final double deliveryFee = 20.0;
    final double finalToPay = itemTotal + platformFee + deliveryFee - _returnDiscount;

    return Scaffold(
      backgroundColor: _kBgWhite,
      body: cart.items.isEmpty
          ? _buildEmptyCart()
          : Stack(
              children: [
                // 1. Hero Image Background
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 380, // slightly taller to show behind rounded corners
                  child: Image.asset(
                    'assets/Swadishtt/back.jpg', // use existing banner
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.black87),
                  ),
                ),
                
                // Back button overlapping the image
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SwadistScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                    ),
                  ),
                ),

                // 2. Scrollable Foreground
                Positioned.fill(
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 250), // Expose the image
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(35),
                              topRight: Radius.circular(35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 28),
                              // "3 Items" Title
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text(
                                  '${cart.itemCount} Items',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: _kPrimaryRed,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Items List
                              _buildItemsList(cart),

                              // Return Old Containers Banner
                              _buildReturnContainersBanner(),

                              // Bill Details
                              _buildSimplifiedBill(itemTotal, deliveryFee, platformFee, _returnDiscount, finalToPay),

                              const SizedBox(height: 24),

                              // Proceed to Checkout Button
                              _buildProceedButton(context, finalToPay),

                              SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
 }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SwadistScreen()),
                    ),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimaryRed),
            child: const Text('Browse Menu', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildItemsList(CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: cart.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 65,
                    height: 65,
                    color: Colors.grey.shade100,
                    child: item.product.imageUrl != null && item.product.imageUrl!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: item.product.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _kPrimaryRed,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(item.product.emoji, style: const TextStyle(fontSize: 30)),
                            ),
                          )
                        : Center(child: Text(item.product.emoji, style: const TextStyle(fontSize: 30))),
                  ),
                ),
                const SizedBox(width: 16),

                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Regular',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price and Quantity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(item.product.price * item.quantity),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => cart.decrementQuantity(item.product.id),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            color: Colors.grey.shade300,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            color: Colors.grey.shade300,
                          ),
                          InkWell(
                            onTap: () => cart.incrementQuantity(item.product.id),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReturnContainersBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kLightBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Container Icon/Image placeholder
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Image.asset(
                'assets/Swadishtt/return.png',
                width: 30,
                height: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Return Old Containers with this Order',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help us keep meals safe & Our Planet Cleaner !',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Earn Some money on return',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E8449),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final discount = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReturnContainersScreen()),
                            );
                            if (discount != null) {
                              setState(() {
                                _returnDiscount = (discount as num).toDouble();
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kPrimaryRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Add Items to return',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedBill(double itemTotal, double deliveryFee, double platformFee, double returnDiscount, double finalToPay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBillRow('Item Total', currencyFormat.format(itemTotal)),
          const SizedBox(height: 12),
          _buildBillRow('Delivery Fee', currencyFormat.format(deliveryFee)),
          const SizedBox(height: 12),
                    _buildBillRow('Platform Fee', currencyFormat.format(platformFee)),
          if (returnDiscount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Container Discount', style: TextStyle(color: Color(0xFF1E8449), fontSize: 14, fontWeight: FontWeight.w500)),
                Text('-' + currencyFormat.format(returnDiscount), style: const TextStyle(color: Color(0xFF1E8449), fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'To Pay',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _kPrimaryRed,
                ),
              ),
              Text(
                currencyFormat.format(finalToPay),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _kPrimaryRed,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBillRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildProceedButton(BuildContext context, double finalToPay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to checkout address selection first
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutDeliveryAddressScreen(isFromCart: true)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Proceed To Checkout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
