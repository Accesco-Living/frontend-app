import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RedeemCodeScreen extends StatefulWidget {
  const RedeemCodeScreen({super.key});

  static const Color primaryMaroon = Color(0xFF6B003B);
  static const Color lightBgColor = Color(0xFFF9F9FB);

  @override
  State<RedeemCodeScreen> createState() => _RedeemCodeScreenState();
}

class _RedeemCodeScreenState extends State<RedeemCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  bool _isRedeeming = false;

  final List<Map<String, String>> _allOffers = [
    {
      'code': 'WELCOME100',
      'title': 'Flat ₹100 off',
      'subtitle': 'On your first order',
      'tnc': 'Applicable only on first order. Minimum order value ₹200. Valid once per user.',
    },
    {
      'code': 'SAVE50',
      'title': 'Flat ₹50 off',
      'subtitle': 'On orders above ₹399',
      'tnc': 'Minimum order value ₹399. Maximum discount ₹50. Valid on select categories.',
    },
    {
      'code': 'FREESHIP',
      'title': 'Free delivery',
      'subtitle': 'On orders above ₹299',
      'tnc': 'Free delivery on orders above ₹299. Not applicable on express delivery.',
    },
    {
      'code': 'PARTY200',
      'title': 'Flat ₹200 off',
      'subtitle': 'On orders above ₹999',
      'tnc': 'Applicable on party orders. Minimum order value ₹999. Valid till month end.',
    },
  ];

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      final pastedText = clipboardData.text!.trim();
      setState(() {
        _codeController.text = pastedText;
      });
      if (mounted) {
        _showSnackBar('Pasted from clipboard!', Colors.green);
      }
    }
  }

  Future<void> _redeemCode() async {
    if (_isRedeeming) return;

    final rawCode = _codeController.text.trim();
    final cleanCode = rawCode.replaceAll(' ', '').toUpperCase();
    final pin = _pinController.text.trim();

    if (cleanCode.isEmpty) {
      _showSnackBar('Please enter a 12-digit gift card code or offer coupon.', Colors.redAccent);
      return;
    }

    final isGiftCard = cleanCode.length == 12 && RegExp(r'^\d+$').hasMatch(cleanCode);
    final isOfferCoupon = _allOffers.any((offer) => offer['code']!.toUpperCase() == cleanCode);

    if (isGiftCard && pin.length != 6) {
      _showSnackBar('Gift card redemption requires a valid 6-digit PIN.', Colors.redAccent);
      return;
    }

    if (!isGiftCard && !isOfferCoupon) {
      _showSnackBar('Invalid code. Please enter a valid 12-digit code or select an available offer.', Colors.redAccent);
      return;
    }

    setState(() {
      _isRedeeming = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _showSnackBar('User not logged in. Please sign in to redeem codes.', Colors.redAccent);
        return;
      }

      // Check if user has already redeemed this code
      final existingDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('redeemed_codes')
          .where('code', isEqualTo: cleanCode)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        _showSnackBar('You have already redeemed the code "$cleanCode"!', const Color(0xFFD97706));
        return;
      }

      final rewardPointsEarned = isGiftCard ? 500 : 100;

      // Record redemption in user subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('redeemed_codes')
          .add({
        'code': cleanCode,
        'pin': pin,
        'type': isGiftCard ? 'gift_card' : 'coupon',
        'pointsEarned': rewardPointsEarned,
        'redeemedAt': FieldValue.serverTimestamp(),
        'status': 'applied',
      });

      // Atomically update user's rewardPoints & walletBalance
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'rewardPoints': FieldValue.increment(rewardPointsEarned),
        'walletBalance': FieldValue.increment(isGiftCard ? 1000 : 100),
        'lastRedeemedCode': cleanCode,
        'lastRedeemedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showSnackBar(
        'Code "$cleanCode" redeemed successfully! +$rewardPointsEarned reward points added.',
        Colors.green,
      );

      _codeController.clear();
      _pinController.clear();
    } catch (e) {
      debugPrint('Error redeeming code: $e');
      if (mounted) {
        _showSnackBar('Failed to redeem code. Please try again.', Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRedeeming = false;
        });
      }
    }
  }

  void _applyOffer(String code) {
    _codeController.text = code;
    _showSnackBar('Offer $code applied!', Colors.green);
  }

  void _showOfferDetails(String code, String title, String subtitle, String tnc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(code, style: const TextStyle(color: RedeemCodeScreen.primaryMaroon, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(tnc, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF4A4A4A))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyOffer(code);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RedeemCodeScreen.primaryMaroon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Apply Offer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAllOffers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'All Available Offers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allOffers.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemBuilder: (context, index) {
                    final offer = _allOffers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOfferItem(
                        offer['code']!,
                        offer['title']!,
                        offer['subtitle']!,
                        offer['tnc']!,
                        isFromSheet: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }



 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedeemCodeScreen.lightBgColor,
      body: Stack(
        children: [
          // Background Header Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 310,
            child: Image.asset(
              'assets/images/redeem.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Main Scrollable Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: RedeemCodeScreen.primaryMaroon),
                  onPressed: () => Navigator.pop(context),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header Text area
                        const SizedBox(height: 0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDDEB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'REDEEM REWARDS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: RedeemCodeScreen.primaryMaroon,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Gift Cards',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: RedeemCodeScreen.primaryMaroon,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Unlock discounts, cashback &\nexclusive rewards.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Card and content (overlaps the bottom of the background image)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              _buildInputCard(),
                              const SizedBox(height: 28),
                              _buildOffersHeader(),
                              const SizedBox(height: 16),
                              ..._allOffers.take(3).map((offer) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildOfferItem(
                                  offer['code']!,
                                  offer['title']!,
                                  offer['subtitle']!,
                                  offer['tnc']!,
                                ),
                              )),
                              const SizedBox(height: 12),
                              _buildHowItWorks(),
                              const SizedBox(height: 24),
                              _buildImportantNotes(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
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

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter code',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(16),
              _CodeSpaceFormatter(),
            ],
            decoration: InputDecoration(
              hintText: 'Enter 12 digit code',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: TextButton(
                onPressed: _pasteFromClipboard,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Paste',
                  style: TextStyle(
                    color: RedeemCodeScreen.primaryMaroon,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: RedeemCodeScreen.primaryMaroon),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Enter PIN (if required)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              hintText: 'Enter 6 digit PIN',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: RedeemCodeScreen.primaryMaroon),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isRedeeming ? null : _redeemCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: RedeemCodeScreen.primaryMaroon,
                disabledBackgroundColor: RedeemCodeScreen.primaryMaroon.withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isRedeeming
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Redeem Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Available Offers',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
        ),
        InkWell(
          onTap: _showAllOffers,
          child: const Row(
            children: [
              Text(
                'View all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: RedeemCodeScreen.primaryMaroon,
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: RedeemCodeScreen.primaryMaroon),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfferItem(String code, String title, String subtitle, String tnc, {bool isFromSheet = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isFromSheet) {
              Navigator.pop(context);
            }
            _applyOffer(code);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Dashed border for the code
                CustomPaint(
                  painter: DashedBorderPainter(color: RedeemCodeScreen.primaryMaroon.withOpacity(0.5)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFFFF7FA),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: RedeemCodeScreen.primaryMaroon,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showOfferDetails(code, title, subtitle, tnc),
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepItem('1', 'Enter\nyour code'),
              const Text(
                '>',
                style: TextStyle(
                  color: RedeemCodeScreen.primaryMaroon,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _buildStepItem('2', 'Verify\ndetails'),
              const Text(
                '>',
                style: TextStyle(
                  color: RedeemCodeScreen.primaryMaroon,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _buildStepItem('3', 'Redeem\ninstantly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: RedeemCodeScreen.primaryMaroon, width: 1.5),
            color: Colors.white,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.w800, 
              fontSize: 12,
              color: RedeemCodeScreen.primaryMaroon,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildImportantNotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Important Notes',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          _buildBullet(
            'You can redeem gift cards worth up to ₹2,500 each month.',
          ),
          _buildBullet('Gift card balance can be used across our app.'),
          _buildBullet(
            'The gift card amount will have the same expiry date as mentioned on the card.',
          ),
          _buildBullet(
            'Redeemed balance cannot be transferred to another account.',
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 10.0),
            child: Icon(Icons.circle, size: 5, color: RedeemCodeScreen.primaryMaroon),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));

    // Simple dashing using PathMetrics
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        canvas.drawPath(
          measurePath.extractPath(distance, distance + 4.0), // dash length 4
          paint,
        );
        distance += 8.0; // dash + gap length
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _CodeSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    // Only format if purely digits
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return newValue;
    }
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
