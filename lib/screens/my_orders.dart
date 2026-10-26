import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchRealOrders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final List<Map<String, dynamic>> combined = [];

    try {
      // 1. Fetch from top-level 'orders' collection (used in some places)
      final topOrders = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (var doc in topOrders.docs) {
        combined.add(_normalizeOrder(doc.data(), doc.id, 'TopLevel'));
      }

      // 2. Fetch from users/{uid}/orders (Grokly / general orders)
      final groklyOrders = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('orders')
          .get();
          
      for (var doc in groklyOrders.docs) {
        combined.add(_normalizeOrder(doc.data(), doc.id, 'Grokly'));
      }

      // 3. Fetch from users/{uid}/swadishtt_orders
      final swadishttOrders = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('swadishtt_orders')
          .get();
          
      for (var doc in swadishttOrders.docs) {
        combined.add(_normalizeOrder(doc.data(), doc.id, 'Swadishtt'));
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    }

    // Sort by date descending (newest first)
    combined.sort((a, b) {
      final dateA = _parseDate(a);
      final dateB = _parseDate(b);
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA); 
    });

    return combined;
  }

  Map<String, dynamic> _normalizeOrder(Map<String, dynamic> data, String docId, String source) {
    // Deduce service type
    String service = data['service'] ?? '';
    if (service.isEmpty) {
      if (source == 'Grokly') service = 'Grokly';
      else if (source == 'Swadishtt') service = 'Swadishtt';
      else if (data.containsKey('restaurantName')) service = 'Swadishtt';
      else service = 'Grokly';
    }
    
    // Normalize status, total, date
    String status = data['status'] ?? 'Delivered';
    String total = (data['total'] ?? data['totalPaid'] ?? data['price'] ?? 0).toString();
    
    String dateStr = data['dateText'] ?? data['date'] ?? '';
    if (dateStr.isEmpty && data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
         final dt = (data['createdAt'] as Timestamp).toDate();
         dateStr = _formatDateTime(dt);
      }
    }
    if (dateStr.isEmpty) dateStr = 'Unknown Date';

    return {
      'id': data['id'] ?? data['orderNumber'] ?? docId,
      'service': service,
      'status': status,
      'date': dateStr,
      'total': total,
      'items': data['items'] ?? [],
      '_rawDate': data['createdAt'] ?? data['date'],
    };
  }
  
  String _formatDateTime(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    String month = dt.month >= 1 && dt.month <= 12 ? months[dt.month-1] : '';
    String hour = dt.hour > 12 ? (dt.hour - 12).toString() : (dt.hour == 0 ? '12' : dt.hour.toString());
    String amPm = dt.hour >= 12 ? 'PM' : 'AM';
    String min = dt.minute.toString().padLeft(2, '0');
    return "${dt.day} $month, $hour:$min $amPm";
  }

  DateTime? _parseDate(Map<String, dynamic> data) {
    final raw = data['_rawDate'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF7FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRealOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF9D1C50)),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'When you place an order on Swadishtt\nor Grokly, it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.4, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final bool isGrokly = order['service'] == 'Grokly';
    
    final Color serviceColor = isGrokly ? const Color(0xFF7CB342) : const Color(0xFFE53935);
    final Color serviceBg = isGrokly ? const Color(0xFFF2FCF3) : const Color(0xFFFFF5F5);
    const Color primaryMaroon = Color(0xFF9D1C50);

    Color statusColor;
    if (order['status'] == 'Delivered') {
      statusColor = const Color(0xFF137333);
    } else if (order['status'] == 'Cancelled') {
      statusColor = Colors.red.shade700;
    } else {
      statusColor = Colors.orange.shade800;
    }

    final dynamic rawItems = order['items'];
    final List<dynamic> itemsList = rawItems is String 
        ? [{'name': rawItems, 'qty': 1, 'price': 0}] 
        : (rawItems as List<dynamic>? ?? []);

    int totalItems = 0;
    for (var item in itemsList) {
      // Fallback gracefully if quantity is missing
      int qty = 1;
      if (item is Map && item.containsKey('quantity')) qty = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1;
      else if (item is Map && item.containsKey('qty')) qty = item['qty'] is int ? item['qty'] : int.tryParse(item['qty'].toString()) ?? 1;
      totalItems += qty;
    }

    return GestureDetector(
      onTap: () => _showOrderDetails(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: serviceBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGrokly ? Icons.shopping_basket : Icons.restaurant,
                          size: 16,
                          color: serviceColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order['service'],
                          style: TextStyle(
                            color: serviceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['id'].toString().replaceAll("Order #", "")}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${order['date']} • $totalItems items',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '₹${order['total']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: primaryMaroon,
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tap to view receipt',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: primaryMaroon,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: primaryMaroon,
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

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    const Color primaryMaroon = Color(0xFF9D1C50);
    final dynamic rawItems = order['items'];
    final List<dynamic> items = rawItems is String 
        ? [{'name': rawItems, 'qty': 1, 'price': int.tryParse(order['total'].toString()) ?? 0}] 
        : (rawItems as List<dynamic>? ?? []);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Order #${order['id'].toString().replaceAll("Order #", "")}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${order['service']} • ${order['date']}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Items in your order',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    
                    // Item list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        
                        // Handle potential differences in database item schema
                        String itemName = '';
                        int itemQty = 1;
                        num itemPrice = 0;
                        
                        if (item is Map) {
                          itemName = item['name'] ?? item['dishName'] ?? item['title'] ?? 'Unknown Item';
                          itemQty = item['quantity'] ?? item['qty'] ?? 1;
                          itemPrice = item['price'] ?? 0;
                        } else if (item is String) {
                          itemName = item;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${itemQty}x',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: primaryMaroon, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  itemName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 15),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹${itemPrice * itemQty}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 15),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                    ),
                    
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 18),
                        ),
                        Text(
                          '₹${order['total']}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: primaryMaroon, fontSize: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: primaryMaroon,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Close Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
