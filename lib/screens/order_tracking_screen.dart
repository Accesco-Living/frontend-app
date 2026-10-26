import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'swadisht_screen.dart';

class OrderTrackingItem {
  final String name;
  final int quantity;
  final double price;
  final List<String>? selectedAddOns;
  final String? specialInstructions;

  const OrderTrackingItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.selectedAddOns,
    this.specialInstructions,
  });
}

class OrderTrackingScreen extends StatelessWidget {
  final List<OrderTrackingItem> items;
  final double total;
  final String restaurantName;
  final String orderId;
  final String paymentMethod;

  const OrderTrackingScreen({
    super.key,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.restaurantName = 'Swadishtt Kitchen',
    this.orderId = 'SWD123456789',
  });

  static const Color _kMaroon = Color(0xFFC32148);
  static const Color _kBgColor = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context),
                _buildOrderIdHeader(context),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Map Section
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)),
                            child: _buildMapBackground(),
                          ),
                        ),
                        // Map floating action buttons
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMapFloatingButton(Icons.my_location),
                              const SizedBox(height: 12),
                              _buildMapFloatingButton(Icons.headset_mic),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Details Section
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.only(top: 24, bottom: 24),
                    child: Column(
                      children: [
                        _buildHeaderStatus(),
                        const SizedBox(height: 24),
                        _buildHorizontalStepper(),
                        const SizedBox(height: 24),
                        _buildRiderCard(),
                        const SizedBox(height: 24),
                        _buildActionGrid(),
                        const SizedBox(height: 24),
                        _buildTelemetryRow(),
                        const SizedBox(height: 24),
                        _buildOrderUpdates(),
                        const Divider(
                            height: 32, color: Color(0xFFEEEEEE), thickness: 6),
                        _buildReferBanner(),
                        const SizedBox(height: 16),
                        _buildHelpTile(),
                        const SizedBox(height: 24),
                        _buildFooterButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SwadistScreen()),
              (route) => false,
            ),
          ),
          const Text('Live Tracking',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16)),
            child: const Text('Live',
                style: TextStyle(
                    color: _kMaroon,
                    fontWeight: FontWeight.w900,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderIdHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white,
      child: Row(
        children: [
          Text('Order ID: $orderId',
              style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: orderId));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order ID copied!')));
            },
            child: Icon(Icons.copy, size: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return Container(
      color: const Color(0xFFF9F9F9),
      child: Stack(
        children: [
          Positioned(
              top: 50,
              left: -50,
              right: -50,
              child: Container(height: 12, color: Colors.white)),
          Positioned(
              top: 150,
              left: -50,
              right: -50,
              child: Container(height: 12, color: Colors.white)),
          Positioned(
              top: -50,
              bottom: -50,
              left: 100,
              child: Container(width: 12, color: Colors.white)),
          Positioned(
              top: -50,
              bottom: -50,
              left: 250,
              child: Container(width: 12, color: Colors.white)),
          Positioned(
            top: 10,
            left: 20,
            child: Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: const Center(
                  child: Text('MVP Colony\nPark',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                )),
          ),
          const Positioned(
              top: 70,
              left: 100,
              child: Text('Sagar Nagar',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700))),
          Positioned(
            top: 70,
            left: 40,
            child: Transform.rotate(
              angle: 0.6,
              child: Container(
                width: 180,
                height: 3,
                color: _kMaroon,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _kMaroon,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4)
                  ]),
              child:
                  const Icon(Icons.restaurant, color: Colors.white, size: 16),
            ),
          ),
          Positioned(
            top: 130,
            left: 200,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ]),
                  child: const Column(
                    children: [
                      Text('5 mins',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 12)),
                      Text('away from you',
                          style: TextStyle(color: Colors.grey, fontSize: 8)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ]),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        NetworkImage('https://i.pravatar.cc/150?img=11'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFloatingButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Icon(icon, color: Colors.black87, size: 24),
    );
  }

  Widget _buildHeaderStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your order is on the way! 🚀',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Estimated delivery in ',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const Text('30-40 mins',
                  style: TextStyle(
                      color: _kMaroon,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStepper() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepIcon(
              label: 'Confirmed',
              time: '12:05 PM',
              icon: Icons.check,
              state: _StepState.completed),
          _StepLine(state: _StepState.completed),
          _StepIcon(
              label: 'Preparing',
              time: '12:10 PM',
              icon: Icons.check,
              state: _StepState.completed),
          _StepLine(state: _StepState.active),
          _StepIcon(
              label: 'On the way',
              time: '12:25 PM',
              icon: Icons.two_wheeler,
              state: _StepState.active),
          _StepLine(state: _StepState.pending),
          _StepIcon(
              label: 'Delivered',
              time: '--',
              icon: null,
              state: _StepState.pending),
        ],
      ),
    );
  }

  Widget _buildRiderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Ravi Kumar',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          Icon(Icons.star,
                              color: Colors.orange.shade700, size: 12),
                          const SizedBox(width: 4),
                          const Text('4.8',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Your Delivery Partner',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          _buildCircleIconButton(Icons.phone,
              color: _kMaroon, bgColor: Colors.red.shade50),
          const SizedBox(width: 12),
          _buildCircleIconButton(Icons.chat_bubble,
              color: _kMaroon, bgColor: Colors.red.shade50),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, {Color? color, Color? bgColor}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          shape: BoxShape.circle,
          border:
              bgColor == null ? Border.all(color: Colors.grey.shade300) : null),
      child: Icon(icon, color: color ?? Colors.grey.shade700, size: 20),
    );
  }

  Widget _buildActionGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionItem(Icons.location_on_outlined, 'Share Live Location'),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          _buildActionItem(Icons.phone_outlined, 'Call Rider'),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          _buildActionItem(Icons.chat_bubble_outline, 'Chat'),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          _buildActionOTP('1256', 'Delivery OTP'),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: _kMaroon, size: 24),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2),
        ),
      ],
    );
  }

  Widget _buildActionOTP(String otp, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8)),
          child: Text(otp,
              style: const TextStyle(
                  color: _kMaroon, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTelemetryRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTelemetryItem(Icons.route_outlined, 'Distance Left', '2.4 km'),
          _buildTelemetryItem(
              Icons.pedal_bike_outlined, 'Rider Speed', '28 km/h'),
          _buildTelemetryItem(Icons.cloudy_snowing, 'Weather', '27°C'),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _kMaroon, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderUpdates() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Updates',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 24),
          _buildTimelineItem(Icons.two_wheeler, 'On the way',
              'Rider is on the way to deliver your order', '12:25 PM',
              isCurrent: true),
          _buildTimelineItem(Icons.shopping_bag_outlined, 'Order Picked',
              'Your order has been picked up', '12:20 PM'),
          _buildTimelineItem(Icons.inventory_2_outlined, 'Preparing',
              'Restaurant is preparing your order', '12:10 PM'),
          _buildTimelineItem(Icons.receipt_long_outlined, 'Order Confirmed',
              'We\'ve received your order', '12:05 PM',
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      IconData icon, String title, String subtitle, String time,
      {bool isCurrent = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: isCurrent ? _kMaroon : Colors.grey.shade300,
                    shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color: isCurrent ? _kMaroon : Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 15)),
                      Text(time,
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard, color: _kMaroon, size: 48),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(text: 'Invite friends & get '),
                      TextSpan(
                          text: '₹100\n',
                          style: TextStyle(
                              color: _kMaroon, fontWeight: FontWeight.w900)),
                      TextSpan(text: 'Swadishtt Cash'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('Share the love!',
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _kMaroon),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Refer & Earn',
                      style: TextStyle(
                          color: _kMaroon,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration:
                const BoxDecoration(color: _kMaroon, shape: BoxShape.circle),
            child: const Icon(Icons.headset_mic, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need Help?',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text('We are here for you',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.black87, size: 20),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterAction(
                Icons.receipt_long, 'Order Details', 'View bill & items'),
          ),
          Container(width: 1, height: 48, color: Colors.grey.shade300),
          Expanded(
            child: _buildFooterAction(
                Icons.refresh, 'Repeat Order', 'Order again'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _kMaroon, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

enum _StepState { completed, active, pending }

class _StepIcon extends StatelessWidget {
  final String label;
  final String time;
  final IconData? icon;
  final _StepState state;

  const _StepIcon(
      {required this.label,
      required this.time,
      required this.icon,
      required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (state == _StepState.completed) {
      color = Colors.green;
    } else if (state == _StepState.active) {
      color = OrderTrackingScreen._kMaroon;
    } else {
      color = Colors.grey.shade300;
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: state == _StepState.active
                ? Border.all(color: color.withOpacity(0.3), width: 4)
                : null,
          ),
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 14)
              : const SizedBox(),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: state == _StepState.pending
                    ? Colors.grey.shade500
                    : Colors.black87,
                fontWeight: state == _StepState.active
                    ? FontWeight.w900
                    : FontWeight.w700,
                fontSize: 11)),
        const SizedBox(height: 2),
        Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final _StepState state;
  const _StepLine({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color = state == _StepState.completed
        ? Colors.green
        : (state == _StepState.active
            ? OrderTrackingScreen._kMaroon
            : Colors.grey.shade300);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: 2,
        color: color,
      ),
    );
  }
}
