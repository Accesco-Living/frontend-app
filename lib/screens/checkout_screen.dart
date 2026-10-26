import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';
import '../services/razorpay_service.dart';
import 'order_tracking_screen.dart';
import 'address_screen.dart';
import 'checkout_delivery_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color _kMaroon = Color(0xFFC32148);
  static const Color _kBgColor = Color(0xFFFAFAFA);

  final ValueNotifier<String> _selectedPaymentMethod =
      ValueNotifier<String>('UPI ID');
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);
  final GlobalKey _paymentMethodsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_paymentMethodsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _paymentMethodsKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  @override
  void dispose() {
    _selectedPaymentMethod.dispose();
    _isProcessing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We only read from CartProvider once per build.
    final cart = Provider.of<CartProvider>(context);
    final double itemTotal = cart.subtotal;
    const double platformFee = 10.0;
    const double deliveryFee = 20.0;
    const double discount = 100.0;
    final double toPay = (itemTotal + platformFee + deliveryFee) - discount;

    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: const _CheckoutAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.only(bottom: 180), // Space for fixed footer
            child: Column(
              children: [
                const _CheckoutStepper(),
                const SizedBox(height: 16),
                const _AddressCard(),
                const SizedBox(height: 16),
                const _DeliveryTimeCard(),
                const SizedBox(height: 16),
                _OrderSummary(
                  cart: cart,
                  itemTotal: itemTotal,
                  platformFee: platformFee,
                  deliveryFee: deliveryFee,
                  discount: discount,
                  toPay: toPay,
                ),
                const SizedBox(height: 16),
                Container(
                  key: _paymentMethodsKey,
                  child: _PaymentMethodsList(
                      selectedMethodNotifier: _selectedPaymentMethod),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _StickyFooter(
              cart: cart,
              toPay: toPay,
              selectedMethodNotifier: _selectedPaymentMethod,
              isProcessingNotifier: _isProcessing,
              onProcessOrder: _processOrder,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processOrder(
      CartProvider cart, double finalToPay, String paymentMethod) async {
    _isProcessing.value = true;

    try {
      String? rzpOrderId;
      String? txnId;

      if (paymentMethod != 'Pay Later' && paymentMethod != 'Cash on Delivery') {
        final paymentResult = await RazorpayService.openPayment(
          amount: finalToPay,
          description: 'Order Checkout - Swadishtt Central',
        );

        if (!paymentResult.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(paymentResult.message ?? 'Payment failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        rzpOrderId = paymentResult.orderId;
        txnId = paymentResult.paymentId;
      }

      final trackingItems = cart.items
          .map((item) => OrderTrackingItem(
                name: item.product.name,
                quantity: item.quantity,
                price: item.product.price,
                selectedAddOns: item.product.selectedAddOns,
                specialInstructions: item.product.specialInstructions,
              ))
          .toList();

      final firestoreItems = cart.items
          .map((item) => {
                'name': item.product.name,
                'quantity': item.quantity,
                'price': item.product.price,
                'image': item.product.imageUrl ?? 'assets/Swadishtt/burger.png',
                if (item.product.selectedAddOns != null)
                  'selectedAddOns': item.product.selectedAddOns,
                if (item.product.specialInstructions != null)
                  'specialInstructions': item.product.specialInstructions,
              })
          .toList();

      await FirebaseService.createOrder(
        restaurantName: 'Swadishtt Central',
        restaurantImage: 'assets/Swadishtt/spaghetti bolognese.png',
        totalAmount: finalToPay,
        items: firestoreItems,
        paymentMethod: paymentMethod,
        razorpayOrderId: rzpOrderId,
        transactionId: txnId,
      );

      cart.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              items: trackingItems,
              total: finalToPay,
              restaurantName: 'Swadishtt Central',
              paymentMethod: paymentMethod,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        _isProcessing.value = false;
      }
    }
  }
}

// ----------------------------------------------------------------------
// EXTRACTED WIDGETS FOR PERFORMANCE OPTIMIZATION
// ----------------------------------------------------------------------

class _CheckoutAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CheckoutAppBar();
  static const Color _kMaroon = Color(0xFFC32148);
  static const Color _kBgColor = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _kBgColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Swadishtt',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CheckoutStepper extends StatelessWidget {
  const _CheckoutStepper();
  static const Color _kMaroon = Color(0xFFC32148);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _StepItem('Cart', 1, isCompleted: true),
          _StepLine(isCompleted: true),
          _StepItem('Address', 2, isCompleted: true),
          _StepLine(isCompleted: true),
          _StepItem('Payment', 3, isCompleted: true, isCurrent: true),
          _StepLine(isCompleted: false),
          _StepItem('Delivery', 4, isCompleted: false),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final int number;
  final bool isCompleted;
  final bool isCurrent;

  const _StepItem(this.label, this.number,
      {this.isCompleted = false, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    const Color _kMaroon = Color(0xFFC32148);
    final Color bgColor = isCompleted ? _kMaroon : Colors.white;
    final Color textColor = isCompleted ? Colors.white : Colors.grey.shade400;
    final Color borderColor = isCompleted ? _kMaroon : Colors.grey.shade300;
    final double size = isCurrent ? 40 : 32;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                        color: _kMaroon.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2)
                  ]
                : null,
          ),
          child: Center(
            child: Text('$number',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: isCurrent ? 16 : 14)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isCurrent
                ? _kMaroon
                : (isCompleted ? Colors.black87 : Colors.grey.shade500),
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isCompleted;
  const _StepLine({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    const Color _kMaroon = Color(0xFFC32148);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 2,
        color: isCompleted
            ? _kMaroon.withValues(alpha: 0.5)
            : Colors.grey.shade300,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard();
  static const Color _kMaroon = Color(0xFFC32148);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.home_outlined, color: _kMaroon, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Home',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutDeliveryAddressScreen(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text('CHANGE',
                            style: TextStyle(
                                color: _kMaroon,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    'D.No. 45-8-10, MVP Colony,\nSector 7, Visakhapatnam,\nAndhra Pradesh - 530017',
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.4)),
                const SizedBox(height: 12),
                Text('Ravi Kumar  •  +91 98765 43210',
                    style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTimeCard extends StatelessWidget {
  const _DeliveryTimeCard();
  static const Color _kMaroon = Color(0xFFC32148);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.access_time, color: _kMaroon, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Time',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('ASAP',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _kMaroon,
                            fontSize: 16)),
                    Text(' (30–40 mins)',
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('You\'ll get your order as soon as possible',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          const Text('CHANGE',
              style: TextStyle(
                  color: _kMaroon, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.orange.shade100]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium,
              color: Colors.orange.shade700, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4),
                children: [
                  const TextSpan(text: 'Yay! You are saving '),
                  TextSpan(
                      text: '₹20 on delivery\n',
                      style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w800)),
                  const TextSpan(text: 'with Swadishtt Plus'),
                ],
              ),
            ),
          ),
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.fastfood, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  final double itemTotal;
  final double platformFee;
  final double deliveryFee;
  final double discount;
  final double toPay;

  const _OrderSummary({
    required this.cart,
    required this.itemTotal,
    required this.platformFee,
    required this.deliveryFee,
    required this.discount,
    required this.toPay,
  });

  static const Color _kMaroon = Color(0xFFC32148);

  @override
  Widget build(BuildContext context) {
    final int totalItems =
        cart.items.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Summary',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('$totalItems Items',
                  style: const TextStyle(
                      color: _kMaroon,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          ...cart.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      item.product.imageUrl ?? 'assets/Swadishtt/burger.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                          width: 48, height: 48, color: Colors.grey.shade200),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('₹${item.product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                            const Spacer(),
                            Text('x${item.quantity}',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          _BillRow('Item Total', '₹${itemTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              Row(
                children: [
                  Text('₹40',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 8),
                  const Text('₹20',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BillRow('Platform Fee', '₹${platformFee.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _BillRow('Coupon Discount (SWADISHTT20)',
              '- ₹${discount.toStringAsFixed(0)}',
              isDiscount: true),
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('To Pay',
                  style: TextStyle(
                      color: _kMaroon,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
              Text('₹${toPay.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: _kMaroon,
                      fontWeight: FontWeight.w900,
                      fontSize: 24)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.red.shade100, style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    color: _kMaroon, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          color: _kMaroon, fontSize: 13, height: 1.4),
                      children: [
                        const TextSpan(text: 'You\'re saving '),
                        const TextSpan(
                            text: '₹120 on this order\n',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(
                            text: 'with SWADISHTT20',
                            style: TextStyle(
                                color: _kMaroon.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.card_giftcard, color: _kMaroon, size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isDiscount;

  const _BillRow(this.title, this.value, {this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                color: isDiscount ? Colors.green : Colors.grey.shade600,
                fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: isDiscount ? Colors.green : Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    );
  }
}

class _PaymentMethodsList extends StatelessWidget {
  final ValueNotifier<String> selectedMethodNotifier;

  const _PaymentMethodsList({required this.selectedMethodNotifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a payment method',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  color: Colors.green.shade600, size: 16),
              const SizedBox(width: 6),
              Text('100% Secure Payments',
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: selectedMethodNotifier,
            builder: (context, selectedMethod, child) {
              return Column(
                children: [
                  _PaymentOptionRow(
                      'UPI',
                      'Pay using any UPI app',
                      Icons.qr_code_scanner,
                      selectedMethod,
                      selectedMethodNotifier),
                  _PaymentOptionRow(
                      'Card',
                      'Visa, Mastercard, RuPay',
                      Icons.credit_card,
                      selectedMethod,
                      selectedMethodNotifier),
                  _PaymentOptionRow(
                      'Wallet',
                      'Pay using wallet balance',
                      Icons.account_balance_wallet_outlined,
                      selectedMethod,
                      selectedMethodNotifier),
                  _PaymentOptionRow(
                      'Net Banking',
                      'All major banks supported',
                      Icons.account_balance,
                      selectedMethod,
                      selectedMethodNotifier),
                  _PaymentOptionRow('Pay Later', 'Buy now, pay later',
                      Icons.schedule, selectedMethod, selectedMethodNotifier,
                      isNew: true),
                  _PaymentOptionRow('EMI', 'Easy monthly installments',
                      Icons.refresh, selectedMethod, selectedMethodNotifier),
                  const SizedBox(height: 16),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Saved Payment Options',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14))),
                  const SizedBox(height: 12),
                  _SavedPaymentRow('Visa', '**** 4242', 'Expires 07/28',
                      'Visa Card', selectedMethod, selectedMethodNotifier),
                  _SavedPaymentRow('UPI', 'UPI ID: ravikumar@okicici', '',
                      'UPI ID', selectedMethod, selectedMethodNotifier),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isNew;
  final String selectedMethod;
  final ValueNotifier<String> notifier;

  const _PaymentOptionRow(
      this.title, this.subtitle, this.icon, this.selectedMethod, this.notifier,
      {this.isNew = false});

  @override
  Widget build(BuildContext context) {
    const Color _kMaroon = Color(0xFFC32148);
    final bool isSelected = selectedMethod == title;

    return InkWell(
      onTap: () => notifier.value = title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 22, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      if (isNew) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('NEW',
                              style: TextStyle(
                                  color: _kMaroon,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? _kMaroon : Colors.grey.shade300, size: 24),
          ],
        ),
      ),
    );
  }
}

class _SavedPaymentRow extends StatelessWidget {
  final String iconText;
  final String title;
  final String subtitle;
  final String value;
  final String selectedMethod;
  final ValueNotifier<String> notifier;

  const _SavedPaymentRow(this.iconText, this.title, this.subtitle, this.value,
      this.selectedMethod, this.notifier);

  @override
  Widget build(BuildContext context) {
    const Color _kMaroon = Color(0xFFC32148);
    final bool isSelected = selectedMethod == value;

    return InkWell(
      onTap: () => notifier.value = value,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.shade50.withValues(alpha: 0.3)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: isSelected ? _kMaroon : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 28,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(6)),
              child: Center(
                  child: Text(iconText,
                      style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w900,
                          fontSize: 12))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? _kMaroon : Colors.grey.shade300, size: 24),
          ],
        ),
      ),
    );
  }
}

class _StickyFooter extends StatelessWidget {
  final CartProvider cart;
  final double toPay;
  final ValueNotifier<String> selectedMethodNotifier;
  final ValueNotifier<bool> isProcessingNotifier;
  final Function(CartProvider, double, String) onProcessOrder;

  const _StickyFooter({
    required this.cart,
    required this.toPay,
    required this.selectedMethodNotifier,
    required this.isProcessingNotifier,
    required this.onProcessOrder,
  });

  static const Color _kMaroon = Color(0xFFC32148);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _TrustBadge(Icons.security, 'PCI DSS\nCertified'),
                  _TrustBadge(Icons.lock_outline, '256-bit SSL\nSecured'),
                  _TrustBadge(Icons.shield_outlined, 'Razorpay\nSecured'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ValueListenableBuilder<bool>(
                  valueListenable: isProcessingNotifier,
                  builder: (context, isProcessing, child) {
                    return ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () => onProcessOrder(
                              cart, toPay, selectedMethodNotifier.value),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kMaroon,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text('Pay ₹${toPay.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18)),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  children: const [
                    TextSpan(text: 'By proceeding, you agree to our '),
                    TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                            color: _kMaroon, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustBadge(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal.shade700, size: 20),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
