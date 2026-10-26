import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';

const Color _kSwadishtRed = Color(0xFFFF5722);

/// ─────────────────────────────────────────────────────────────
/// 1. PACKAGING FEEDBACK SCREEN
/// ─────────────────────────────────────────────────────────────
class SwadishtPackagingFeedbackScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onBackToHome;

  const SwadishtPackagingFeedbackScreen({
    super.key,
    required this.orderData,
    this.onBackToHome,
  });

  @override
  State<SwadishtPackagingFeedbackScreen> createState() =>
      _SwadishtPackagingFeedbackScreenState();
}

class _SwadishtPackagingFeedbackScreenState
    extends State<SwadishtPackagingFeedbackScreen> {
  int _selectedIndex = 2; // Default to 'Good packaging'
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _options = [
    {
      'title': 'Too much packaging',
      'desc': 'There was more packaging than needed.',
      'icon': Icons.shopping_cart_outlined,
    },
    {
      'title': 'Difficult to recycle',
      'desc': 'The packaging was not easy to recycle.',
      'icon': Icons.delete_outline,
    },
    {
      'title': 'Good packaging',
      'desc': 'The packaging was appropriate and eco-friendly.',
      'icon': Icons.check_circle_outline,
    },
    {
      'title': 'Other feedback',
      'desc': 'Share your feedback with us.',
      'icon': Icons.chat_bubble_outline,
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final selected = _options[_selectedIndex]['title'] as String;
    final orderId = widget.orderData['id']?.toString() ?? '12345';

    await FirebaseService.submitPackagingFeedback(
      orderId: orderId,
      selectedFeedback: selected,
      comments: _commentController.text,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SwadishtFeedbackSubmittedScreen(
            onBackToHome: widget.onBackToHome,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Packaging Feedback',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Help us reduce waste',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How was the packaging of your order?',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // ── FEEDBACK OPTIONS ──
          ...List.generate(_options.length, (index) {
            final opt = _options[index];
            final isSelected = index == _selectedIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedIndex = index);
                  HapticFeedback.selectionClick();
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFF3E0).withOpacity(0.4)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? _kSwadishtRed
                          : const Color(0xFFE0E0E0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFE0B2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          opt['icon'] as IconData,
                          color: isSelected
                              ? _kSwadishtRed
                              : Colors.grey.shade700,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['title'] as String,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? _kSwadishtRed
                            : Colors.grey.shade400,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          const Text(
            'Additional comments (optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // ── COMMENT TEXT AREA ──
          TextField(
            controller: _commentController,
            maxLength: 200,
            maxLines: 4,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Share your suggestions...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
              filled: true,
              fillColor: Colors.white,
              counterStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kSwadishtRed, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── SUBMIT BUTTON ──
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
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
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
}

/// ─────────────────────────────────────────────────────────────
/// 2. FEEDBACK SUBMITTED SUCCESS SCREEN
/// ─────────────────────────────────────────────────────────────
class SwadishtFeedbackSubmittedScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;

  const SwadishtFeedbackSubmittedScreen({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Feedback Submitted',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),

          // ── GREEN CLIPBOARD ILLUSTRATION ──
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 64,
                    color: Color(0xFF4CAF50),
                  ),
                  Positioned(
                    top: 16,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF81C784),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Thank you!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Your feedback has been submitted\nsuccessfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── GREEN BANNER CALLOUT ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Small steps, big change.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Together, we can reduce unnecessary packaging and build a sustainable future.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF388E3C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'What happens next?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),

          // ── BULLET POINTS ──
          _buildBulletItem(
            'Your feedback helps our team improve packaging choices.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            'We review all feedback to reduce waste and improve sustainability.',
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            "You're helping Swadishtt build a greener food future.",
          ),

          const SizedBox(height: 32),

          // ── BACK TO HOME BUTTON ──
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
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                onBackToHome?.call();
              },
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── VIEW ORDERS TEXT BUTTON ──
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.shopping_bag_outlined, color: _kSwadishtRed, size: 18),
              label: const Text(
                'View My Orders',
                style: TextStyle(
                  color: _kSwadishtRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: _kSwadishtRed,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// 3. REPORT AN ISSUE SCREEN
/// ─────────────────────────────────────────────────────────────
class SwadishtReportIssueScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onBackToHome;

  const SwadishtReportIssueScreen({
    super.key,
    required this.orderData,
    this.onBackToHome,
  });

  @override
  State<SwadishtReportIssueScreen> createState() => _SwadishtReportIssueScreenState();
}

class _SwadishtReportIssueScreenState extends State<SwadishtReportIssueScreen> {
  int _selectedIndex = 0; // Default to 'Missing Item'

  final List<Map<String, dynamic>> _issueTypes = [
    {
      'title': 'Missing Item',
      'desc': "I didn't receive one or more items in my order.",
      'icon': Icons.shopping_cart_outlined,
    },
    {
      'title': 'Wrong Item Received',
      'desc': 'I received a different item from what I ordered.',
      'icon': Icons.takeout_dining_outlined,
    },
    {
      'title': 'Food Quality Issue',
      'desc': 'There is an issue with the quality or condition of food.',
      'icon': Icons.local_fire_department_outlined,
    },
  ];

  void _handleContinue() {
    HapticFeedback.mediumImpact();
    final selectedType = _issueTypes[_selectedIndex]['title'] as String;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwadishtMissingItemScreen(
          orderData: widget.orderData,
          issueType: selectedType,
          onBackToHome: widget.onBackToHome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report an Issue',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'What went wrong with your order?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please select the issue you are facing.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // ── ISSUE OPTIONS ──
          ...List.generate(_issueTypes.length, (index) {
            final opt = _issueTypes[index];
            final isSelected = index == _selectedIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedIndex = index);
                  HapticFeedback.selectionClick();
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFF3E0).withOpacity(0.4)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? _kSwadishtRed
                          : const Color(0xFFE0E0E0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFE0B2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          opt['icon'] as IconData,
                          color: _kSwadishtRed,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['title'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              opt['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_off,
                        color: isSelected
                            ? _kSwadishtRed
                            : Colors.grey.shade400,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 40),

          // ── CONTINUE BUTTON ──
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
              onPressed: _handleContinue,
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
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
}

/// ─────────────────────────────────────────────────────────────
/// 4. MISSING ITEM DETAIL SELECTION SCREEN
/// ─────────────────────────────────────────────────────────────
class SwadishtMissingItemScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String issueType;
  final VoidCallback? onBackToHome;

  const SwadishtMissingItemScreen({
    super.key,
    required this.orderData,
    required this.issueType,
    this.onBackToHome,
  });

  @override
  State<SwadishtMissingItemScreen> createState() => _SwadishtMissingItemScreenState();
}

class _SwadishtMissingItemScreenState extends State<SwadishtMissingItemScreen> {
  final Set<int> _selectedItemIndexes = {0}; // Default select first item
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    final rawItems = widget.orderData['items'] as List?;
    if (rawItems != null && rawItems.isNotEmpty) {
      _items = List<Map<String, dynamic>>.from(
        rawItems.map((e) => Map<String, dynamic>.from(e)),
      );
    } else {
      // Default demo items matching design reference
      _items = [
        {
          'name': 'Butter Naan',
          'quantity': 2,
          'price': 60,
          'image': 'assets/Swadishtt/burger.png',
        },
        {
          'name': 'Raita',
          'quantity': 1,
          'price': 40,
          'image': 'assets/Swadishtt/salad.png',
        },
        {
          'name': 'Coke (250ml)',
          'quantity': 1,
          'price': 40,
          'image': 'assets/Swadishtt/lemon herb roasted chicken.png',
        },
      ];
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  double get _calculatedRefund {
    double total = 0;
    for (final index in _selectedItemIndexes) {
      final item = _items[index];
      final price = (item['price'] as num?)?.toDouble() ?? 40.0;
      total += price;
    }
    return total > 0 ? total : 60.0;
  }

  Future<void> _handleConfirm() async {
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final selectedNames =
        _selectedItemIndexes.map((i) => _items[i]['name'] as String).toList();
    final orderId = widget.orderData['id']?.toString() ?? '12345';

    await FirebaseService.submitReportedIssue(
      orderId: orderId,
      issueType: widget.issueType,
      selectedItems: selectedNames,
      details: _detailsController.text,
      refundAmount: _calculatedRefund,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SwadishtIssueReportedScreen(
            refundAmount: _calculatedRefund,
            onBackToHome: widget.onBackToHome,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          widget.issueType,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Tell us more',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please provide details about the missing item.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'SELECT MISSING ITEM(S)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // ── ITEM CHECKBOX CARDS ──
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            final isSelected = _selectedItemIndexes.contains(index);
            final String name = item['name'] ?? 'Food Item';
            final int qty = (item['quantity'] as num?)?.toInt() ?? 1;
            final num price = item['price'] ?? 60;
            final String img = item['image'] ?? 'assets/Swadishtt/burger.png';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedItemIndexes.remove(index);
                    } else {
                      _selectedItemIndexes.add(index);
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFF3E0).withOpacity(0.3)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? _kSwadishtRed
                          : const Color(0xFFE0E0E0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: _kSwadishtRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedItemIndexes.add(index);
                            } else {
                              _selectedItemIndexes.remove(index);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          img,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood, color: Colors.grey),
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
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'x $qty',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹$price',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          const Text(
            'Add more details (optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // ── DETAILS TEXT AREA ──
          TextField(
            controller: _detailsController,
            maxLength: 200,
            maxLines: 4,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Let us know if there\'s anything else we should know...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              counterStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kSwadishtRed, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Add photos (optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // ── DOTTED PHOTO UPLOAD BOX ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: _kSwadishtRed,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload images',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── CONFIRM BUTTON ──
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
              onPressed: _isSubmitting ? null : _handleConfirm,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Confirm',
                      style: TextStyle(
                        color: Colors.white,
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
}

/// ─────────────────────────────────────────────────────────────
/// 5. ISSUE REPORTED RESOLUTION SCREEN
/// ─────────────────────────────────────────────────────────────
class SwadishtIssueReportedScreen extends StatelessWidget {
  final double refundAmount;
  final VoidCallback? onBackToHome;

  const SwadishtIssueReportedScreen({
    super.key,
    this.refundAmount = 60.0,
    this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Issue Reported',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),

          // ── GREEN WREATH CHECKMARK GRAPHIC ──
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 58,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              "We've received your issue!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'We are reviewing your issue and will resolve it for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── WHAT HAPPENS NEXT CARD ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What happens next?',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                _buildNextStepRow(
                  icon: Icons.shield_outlined,
                  text: 'We will verify your issue.',
                ),
                const SizedBox(height: 12),
                _buildNextStepRow(
                  icon: Icons.refresh_rounded,
                  text: 'Refund will be initiated within 24 hours.',
                ),
                const SizedBox(height: 12),
                _buildNextStepRow(
                  icon: Icons.notifications_none_outlined,
                  text: "You will receive a confirmation once it's done.",
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'RESOLUTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // ── RESOLUTION CARDS ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Refund for Missing Item',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '₹${refundAmount.toInt()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '+10 Green Points',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'for reporting the issue',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF388E3C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.bookmark_border_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // ── BACK TO HOME BUTTON ──
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
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                onBackToHome?.call();
              },
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  color: Colors.white,
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

  Widget _buildNextStepRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kSwadishtRed),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
