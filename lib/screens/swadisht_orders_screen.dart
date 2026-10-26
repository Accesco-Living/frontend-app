import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import 'swadisht_feedback_issues_screens.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';
import 'swadisht_feedback_issues_screens.dart';
// Swadishtt Primary Branding Colors
const Color _kSwadishtRed = Color(0xFFE53935);
const Color _kSwadishtDarkRed = Color(0xFFC62828);
const Color _kSwadishtLightBg = Color(0xFFFAFAFA);

/// ─────────────────────────────────────────────────────────────
/// 1. MY ORDERS SCREEN (MAIN TABS & ORDERS LIST)
/// ─────────────────────────────────────────────────────────────
class SwadishtOrdersScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final bool showSearchBar;
  const SwadishtOrdersScreen({
    super.key,
    this.onBackToHome,
    this.showSearchBar = true,
  });

  @override
  State<SwadishtOrdersScreen> createState() => _SwadishtOrdersScreenState();
}

class _SwadishtOrdersScreenState extends State<SwadishtOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSwadishtLightBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── MY ORDERS TITLE & FILTER TABS ──
            _buildMyOrdersHeader(),

            // ── ORDERS LIST VIEW ──
            Expanded(
              child: FutureBuilder<dynamic>(
                future: ApiService.getOrders().catchError((e) {
                  debugPrint("API Orders fetch failed: \$e");
                  return [];
                }),
                builder: (context, snapshot) {
                  List<Map<String, dynamic>> orders = _getFallbackDemoOrders();

                  if (snapshot.hasData && snapshot.data is List && (snapshot.data as List).isNotEmpty) {
                    try {
                      orders = (snapshot.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
                    } catch (_) {}
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _kSwadishtRed),
                    );
                  }

                  if (_searchQuery.isNotEmpty) {
                    orders = orders.where((o) {
                      final name = (o['restaurantName'] ?? '').toString().toLowerCase();
                      final id = (o['orderNumber'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery.toLowerCase()) ||
                          id.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(orders, 'All'),
                      _buildOrdersList(orders, 'Ongoing'),
                      _buildOrdersList(orders, 'Completed'),
                    ],
                  );
                },
              ),
            ),

            // ── INFO BANNER AT BOTTOM ──
            _buildBottomInfoBanner(),
            const SizedBox(height: 80), // Padding for floating bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildRedTopperHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kSwadishtDarkRed, _kSwadishtRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Swadishtt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '20 Mins',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'To Home - Sembakkam, Chennai',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _buildCircleIconButton(Icons.notifications_outlined),
              const SizedBox(width: 8),
              _buildCircleIconButton(Icons.person_outline),
            ],
          ),
          if (widget.showSearchBar) ...[
            const SizedBox(height: 14),
            // Search Input Bar
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search for food, restaurants...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13.5),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const Icon(Icons.mic, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune, color: Colors.black87, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildMyOrdersHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: _kSwadishtRed,
          indicatorWeight: 3,
          labelColor: _kSwadishtRed,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, String tabType) {
    List<Map<String, dynamic>> filtered = orders;
    if (tabType == 'Ongoing') {
      filtered = orders.where((o) {
        final st = (o['status'] ?? '').toString().toLowerCase();
        return st == 'preparing' || st == 'ongoing' || st == 'on the way' || st == 'out for delivery';
      }).toList();
    } else if (tabType == 'Completed') {
      filtered = orders.where((o) {
        final st = (o['status'] ?? '').toString().toLowerCase();
        return st == 'delivered' || st == 'completed';
      }).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No $tabType orders found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final todayOrders = filtered.where((o) => (o['groupSection'] ?? 'Today') == 'Today').toList();
    final yesterdayOrders = filtered.where((o) => (o['groupSection'] ?? '') == 'Yesterday').toList();
    final olderOrders = filtered.where((o) => (o['groupSection'] ?? '') == 'Older').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (todayOrders.isNotEmpty) ...[
          _buildSectionHeader('Active / Today'),
          ...todayOrders.map((o) => _buildOrderCard(o, isHighlighted: true)),
        ],
        if (yesterdayOrders.isNotEmpty) ...[
          if (todayOrders.isNotEmpty) const SizedBox(height: 16),
          _buildSectionHeader('Yesterday'),
          ...yesterdayOrders.map((o) => _buildOrderCard(o, isHighlighted: o['id'] == '12345')),
        ],
        if (olderOrders.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Older'),
          ...olderOrders.map((o) => _buildOrderCard(o)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {bool isHighlighted = false}) {
    final String restaurantName = order['restaurantName'] ?? 'Restaurant';
    final String orderNumber = order['orderNumber'] ?? 'Order #${order['id']}';
    final String dateText = order['dateText'] ?? '';
    final String price = '₹${order['price'] ?? 0}';
    final String status = order['status'] ?? 'Delivered';
    final String imagePath = order['restaurantImage'] ?? 'assets/Swadishtt/burger.png';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SwadishtOrderDetailScreen(
                orderData: order,
                onBackToHome: widget.onBackToHome,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted ? _kSwadishtRed : Colors.grey.shade200,
              width: isHighlighted ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: Colors.orange.shade50,
                    child: const Icon(Icons.fastfood, color: _kSwadishtRed),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurantName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orderNumber,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              status,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Color(0xFF2E7D32),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC80).withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: _kSwadishtRed, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You can view your past orders and track or reorder easily.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFallbackDemoOrders() {
    return [
      {
        'id': '12345',
        'orderNumber': 'Order #12345',
        'restaurantName': 'Swad House Kitchen',
        'restaurantImage': 'assets/Swadishtt/spaghetti bolognese.png',
        'price': 348,
        'dateText': '12 Jul, 9:24 AM',
        'groupSection': 'Yesterday',
        'status': 'Delivered',
        'containerReturned': false,
        'items': [
          {'name': 'Paneer Butter Masala', 'quantity': 1, 'price': 199, 'image': 'assets/Swadishtt/burger.png'},
          {'name': 'Dal Makhani with Rice', 'quantity': 1, 'price': 149, 'image': 'assets/Swadishtt/spaghetti bolognese.png'},
        ],
        'deliveryFee': 25,
        'totalPaid': 373,
      },
      {
        'id': '12321',
        'orderNumber': 'Order #12321',
        'restaurantName': 'Homely Bites',
        'restaurantImage': 'assets/Swadishtt/lemon herb roasted chicken.png',
        'price': 279,
        'dateText': '11 Jul, 7:40 PM',
        'groupSection': 'Yesterday',
        'status': 'Delivered',
        'containerReturned': false,
        'items': [
          {'name': 'Special Thali Meal', 'quantity': 1, 'price': 279, 'image': 'assets/Swadishtt/thali engine.png'},
        ],
        'deliveryFee': 20,
        'totalPaid': 299,
      },
      {
        'id': '12110',
        'orderNumber': 'Order #12110',
        'restaurantName': 'Biryani Hub',
        'restaurantImage': 'assets/Swadishtt/chicken.png',
        'price': 399,
        'dateText': '10 Jul, 1:15 PM',
        'groupSection': 'Yesterday',
        'status': 'Delivered',
        'containerReturned': false,
        'items': [
          {'name': 'Hyderabadi Chicken Biryani', 'quantity': 1, 'price': 399, 'image': 'assets/Swadishtt/chicken.png'},
        ],
        'deliveryFee': 30,
        'totalPaid': 429,
      },
      {
        'id': '11876',
        'orderNumber': 'Order #11876',
        'restaurantName': 'Comfort Bowl',
        'restaurantImage': 'assets/Swadishtt/salad.png',
        'price': 249,
        'dateText': '09 Jul, 8:30 PM',
        'groupSection': 'Older',
        'status': 'Delivered',
        'containerReturned': false,
        'items': [
          {'name': 'Exotic Veggie Power Bowl', 'quantity': 1, 'price': 249, 'image': 'assets/Swadishtt/salad.png'},
        ],
        'deliveryFee': 25,
        'totalPaid': 274,
      },
    ];
  }
}

/// ─────────────────────────────────────────────────────────────
/// 2. ORDER DETAIL SCREEN (INTERACTIVE DETAILS & CONTAINER CARD)
/// ─────────────────────────────────────────────────────────────
class SwadishtOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onBackToHome;
  const SwadishtOrderDetailScreen({
    super.key,
    required this.orderData,
    this.onBackToHome,
  });

  @override
  State<SwadishtOrderDetailScreen> createState() => _SwadishtOrderDetailScreenState();
}

class _SwadishtOrderDetailScreenState extends State<SwadishtOrderDetailScreen> {
  late Map<String, dynamic> _order;
  bool _isReturned = false;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.orderData);
    _isReturned = _order['containerReturned'] ?? false;
    _checkPersistedReturnStatus();
  }

  Future<void> _checkPersistedReturnStatus() async {
    final returnedIds = await FirebaseService.getReturnedContainerIds();
    final orderId = _order['id']?.toString() ?? '';
    if (returnedIds.contains(orderId)) {
      if (mounted) {
        setState(() {
          _isReturned = true;
          _order['containerReturned'] = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String orderNumber = _order['orderNumber'] ?? 'Order #${_order['id']}';
    final String dateText = _order['dateText'] ?? '12 Jul, 9:24 AM';
    final String status = _order['status'] ?? 'Delivered';
    final List items = _order['items'] ?? [];
    final num price = _order['price'] ?? 348;
    final num deliveryFee = _order['deliveryFee'] ?? 25;
    final num totalPaid = _order['totalPaid'] ?? (price + deliveryFee);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          orderNumber,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── STATUS CARD ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your order has been delivered',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEDE0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: _kSwadishtRed,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── ITEMS LIST ──
          Text(
            'Items (${items.length})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final String name = item['name'] ?? 'Food Item';
            final int qty = item['quantity'] ?? 1;
            final num itemPrice = item['price'] ?? 199;
            final String img = item['image'] ?? 'assets/Swadishtt/burger.png';

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      img,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: Colors.orange.shade50,
                        child: const Icon(Icons.fastfood, color: _kSwadishtRed),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        if (item['selectedAddOns'] != null && (item['selectedAddOns'] as List).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Add-ons: ${(item['selectedAddOns'] as List).join(", ")}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kSwadishtRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (item['specialInstructions'] != null && (item['specialInstructions'] as String).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Note: ${item['specialInstructions']}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          'x $qty',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹$itemPrice',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // ── REUSABLE CONTAINER CARD (INTERACTIVE RETURN) ──
          _buildReusableContainerCard(context),

          const SizedBox(height: 24),

          // ── BILL DETAILS ──
          const Text(
            'Bill Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item Total', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              Text('₹$price', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              Text('₹$deliveryFee', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Paid',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              Text(
                '₹$totalPaid',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── VIEW INVOICE ACTION BUTTON ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kSwadishtRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showInvoiceBottomSheet(context),
              icon: const Icon(Icons.receipt_long, color: _kSwadishtRed, size: 20),
              label: const Text(
                'View Tax Invoice',
                style: TextStyle(
                  color: _kSwadishtRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── HELP & FEEDBACK TILES ──
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.eco_outlined, color: _kSwadishtRed),
            title: const Text('Packaging Feedback', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: const Text('Help us reduce waste & improve packaging', style: TextStyle(fontSize: 12.5)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SwadishtPackagingFeedbackScreen(
                    orderData: _order,
                    onBackToHome: widget.onBackToHome,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.warning_amber_rounded, color: _kSwadishtRed),
            title: const Text('Report an Issue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: const Text('Missing item, wrong item, or food quality', style: TextStyle(fontSize: 12.5)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SwadishtReportIssueScreen(
                    orderData: _order,
                    onBackToHome: widget.onBackToHome,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // ── BACK TO HOME BUTTON ──
          Center(
            child: TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                widget.onBackToHome?.call();
              },
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  color: _kSwadishtRed,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceBottomSheet(BuildContext context) {
    final String invoiceNumber = _order['invoiceNumber'] ?? 'INV-2026-${_order['id']}';
    final String restaurantName = _order['restaurantName'] ?? 'Swad House Kitchen';
    final String dateText = _order['dateText'] ?? '23 Jul 2026';
    final String paymentMethod = _order['paymentMethod'] ?? 'UPI';
    final List items = _order['items'] ?? [];
    final num subtotal = _order['price'] ?? 348;
    final num deliveryFee = _order['deliveryFee'] ?? 25;
    final num taxAmount = _order['taxAmount'] ?? (subtotal * 0.05).round();
    final num totalPaid = _order['totalPaid'] ?? (subtotal + deliveryFee + taxAmount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: _kSwadishtRed, size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TAX INVOICE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        invoiceNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kSwadishtRed,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInvoiceRow('Hotel / Kitchen', restaurantName),
              _buildInvoiceRow('Order Date', dateText),
              _buildInvoiceRow('Payment Method', paymentMethod),
              const Divider(height: 24),
              const Text(
                'Items Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              ...items.map((item) {
                final selectedAddOns = item['selectedAddOns'] as List?;
                final specialInstructions = item['specialInstructions'] as String?;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item['name']} x${item['quantity']}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '₹${item['price']}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      if (selectedAddOns != null && selectedAddOns.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            'Add-ons: ${selectedAddOns.join(", ")}',
                            style: const TextStyle(fontSize: 11, color: _kSwadishtRed, fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (specialInstructions != null && specialInstructions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 1),
                          child: Text(
                            'Note: $specialInstructions',
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              _buildInvoiceRow('Subtotal', '₹$subtotal'),
              _buildInvoiceRow('Delivery Fee', '₹$deliveryFee'),
              _buildInvoiceRow('Taxes & Charges (GST)', '₹$taxAmount'),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL PAID',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  Text(
                    '₹$totalPaid',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kSwadishtRed),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kSwadishtRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice downloaded to device!')),
                    );
                  },
                  child: const Text(
                    'Download Receipt',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildReusableContainerCard(BuildContext context) {
    if (_isReturned) {
      // ── SCHEDULED STATE CARD ──
      return Container(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reusable Container',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Return scheduled',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'We will collect the container with your next Swadishtt delivery.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Scheduled',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward, color: Color(0xFF2E7D32), size: 16),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── INITIAL UNRETURNED STATE CARD (PEACH BACKGROUND) ──
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0B2).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_cart_outlined, color: _kSwadishtRed, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Reusable Container',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'This order came in an Accesco reusable container.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Return it with your next Swadishtt order.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _kSwadishtRed,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kSwadishtRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                backgroundColor: Colors.white,
              ),
              onPressed: () async {
                HapticFeedback.selectionClick();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SwadishtReturnContainerScreen(
                      orderId: widget.orderData['id'].toString(),
                      onBackToHome: widget.onBackToHome,
                    ),
                  ),
                );

                if (result == true) {
                  setState(() => _isReturned = true);
                }
              },
              child: const Text(
                'Return Container',
                style: TextStyle(
                  color: _kSwadishtRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// 3. RETURN CONTAINER SCREEN (CONFIRMATION & REWARD)
/// ─────────────────────────────────────────────────────────────
class SwadishtReturnContainerScreen extends StatelessWidget {
  final String orderId;
  final VoidCallback? onBackToHome;
  const SwadishtReturnContainerScreen({
    super.key,
    required this.orderId,
    this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Return Container',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Spacer(),

            // ── ECO CONTAINER ILLUSTRATION ──
            Container(
              width: 140,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFC8E6C9).withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF81C784), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Icon(Icons.eco_outlined, size: 50, color: Color(0xFF2E7D32)),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Return Scheduled!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'We will collect the reusable container with your next Swadishtt delivery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── REWARD BANNER ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCEDC8)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_giftcard, color: Color(0xFF2E7D32), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'You will earn',
                          style: TextStyle(fontSize: 12.5, color: Colors.black54),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '₹10 Green Points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'on successful return.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── IMPORTANT CHECKLIST ──
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IMPORTANT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCheckItem('No separate pickup required'),
                  const SizedBox(height: 10),
                  _buildCheckItem('Please keep the container clean & dry'),
                ],
              ),
            ),

            const Spacer(),

            // ── ACTION BUTTONS ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kSwadishtRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await FirebaseService.updateContainerReturn(orderId);
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text(
                  'View Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                onBackToHome?.call();
              },
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  color: _kSwadishtRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
