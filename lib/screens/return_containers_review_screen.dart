import 'package:flutter/material.dart';
import 'return_containers_screen.dart';
import 'checkout_summary_screen.dart';

class ReturnContainersReviewScreen extends StatefulWidget {
  final List<ReturnContainer> selectedContainers;

  const ReturnContainersReviewScreen({super.key, required this.selectedContainers});

  @override
  State<ReturnContainersReviewScreen> createState() => _ReturnContainersReviewScreenState();
}

class _ReturnContainersReviewScreenState extends State<ReturnContainersReviewScreen> {
  static const Color _kPrimaryRed = Color(0xFFC00A27);
  static const Color _kBgColor = Color(0xFFFAFAFA);
  static const Color _kLightPinkBg = Color(0xFFFFF5F6);

  double get _totalDiscount {
    double total = 0;
    for (var c in widget.selectedContainers) {
      if (c.isSelected) total += (c.pricePerPiece * c.quantity);
    }
    return total;
  }

  int get _totalItems {
    int total = 0;
    for (var c in widget.selectedContainers) {
      if (c.isSelected && c.quantity > 0) total++;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Items added to return',
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
                  // Good Choice Banner
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 80),
                        padding: const EdgeInsets.fromLTRB(16, 20, 100, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6FAF1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Good Choice',
                              style: TextStyle(
                                color: _kPrimaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                                children: [
                                  const TextSpan(text: 'You will earn '),
                                  TextSpan(
                                    text: '₹${_totalDiscount.toInt()} Discount',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const TextSpan(text: ' for this order'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: -10,
                        child: Image.asset(
                          'assets/Swadishtt/good_choice.png', 
                          width: 110, 
                          height: 110, 
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, size: 40)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // You are returning
                  const Text('You are returning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Please review your items before confirming', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  
                  _buildItemsList(),
                  
                  const SizedBox(height: 24),
                  
                  _buildReturnBreakup(),
                  
                  const SizedBox(height: 24),
                  
                  // Sanitization note
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kLightPinkBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.health_and_safety_outlined, color: _kPrimaryRed, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All returned containers go through sanitization & quality check before reuse',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 8),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutSummaryScreen(selectedContainers: widget.selectedContainers),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Add to return', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildItemsList() {
    final items = widget.selectedContainers.where((c) => c.isSelected && c.quantity > 0).toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25)),
                  child: Image.asset('assets/Swadishtt/container.png', height: 60, width: 60, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            height: 26,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                Container(width: 1, color: Colors.grey.shade300),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                Container(width: 1, color: Colors.grey.shade300),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.type, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _kLightPinkBg, borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.recycling, color: _kPrimaryRed, size: 14),
                                const SizedBox(width: 4),
                                Text('₹${item.pricePerPiece.toInt()}/Piece', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('+₹${(item.pricePerPiece * item.quantity).toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E8449))),
                              Text('(${item.quantity}*₹${item.pricePerPiece.toInt()})', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReturnBreakup() {
    final items = widget.selectedContainers.where((c) => c.isSelected && c.quantity > 0).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kLightPinkBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _kPrimaryRed)),
                child: const Icon(Icons.card_giftcard, color: _kPrimaryRed, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('$_totalItems Items Selected', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Return Value', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                  Text('+₹${_totalDiscount.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E8449))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Return Value Breakup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimaryRed)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.name} (${item.quantity}*₹${item.pricePerPiece.toInt()})', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87)),
                    Text('₹${(item.pricePerPiece * item.quantity).toInt()}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87)),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              Text('+₹${_totalDiscount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E8449))),
            ],
          ),
        ],
      ),
    );
  }
}
