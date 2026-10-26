import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/razorpay_service.dart';
import '../screens/instant_catering_screen.dart'; // For AppColors

class PlanCateringBottomSheet extends StatefulWidget {
  const PlanCateringBottomSheet({super.key});

  @override
  State<PlanCateringBottomSheet> createState() => _PlanCateringBottomSheetState();
}

class _PlanCateringBottomSheetState extends State<PlanCateringBottomSheet> {
  String _selectedOccasion = 'Birthday';
  double _numberOfPeople = 50;
  String _selectedFoodType = 'North Indian';
  
  final List<String> _occasions = ['Birthday', 'Corporate', 'Wedding', 'House Party', 'Other'];
  final List<String> _foodTypes = ['North Indian', 'South Indian', 'Continental', 'Chinese', 'Mixed'];
  final Map<String, bool> _moreOptions = {
    'Live Counter': false,
    'Premium Desserts': false,
    'Decor Setup': false,
    'Drinks & Beverages': false,
  };

  final TextEditingController _otherOccasionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(text: '12th Cross, HSR Layout, Bengaluru');
  final TextEditingController _phoneController = TextEditingController(text: '9876543210');
  
  bool _isProcessing = false;

  @override
  void dispose() {
    _otherOccasionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get _calculatedTotal {
    int selectedAddOns = _moreOptions.values.where((val) => val).length;
    return (_numberOfPeople * 220.0) + (selectedAddOns * 1000.0);
  }

  double get _depositAmount => _calculatedTotal * 0.25;

  Future<void> _submitQuoteRequest() async {
    if (_isProcessing) return;

    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter delivery address and contact phone.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'guest_user';
      final occasion = _selectedOccasion == 'Other'
          ? _otherOccasionController.text.trim()
          : _selectedOccasion;

      final selectedOptions = _moreOptions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final requestData = {
        'userId': uid,
        'occasion': occasion,
        'guestCount': _numberOfPeople.toInt(),
        'foodType': _selectedFoodType,
        'moreOptions': selectedOptions,
        'estimatedTotal': _calculatedTotal,
        'deliveryAddress': address,
        'contactPhone': phone,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        await FirebaseFirestore.instance.collection('catering_requests').add(requestData);
      } catch (fsErr) {
        debugPrint('Firestore catering_requests note: $fsErr');
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catering quote request submitted successfully! Our team will call you.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      debugPrint('Error submitting catering quote: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRazorpayDeposit() async {
    if (_isProcessing) return;

    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter delivery address and contact phone.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Valued Customer';
    final userEmail = user?.email ?? 'customer@accescoliving.com';

    final occasion = _selectedOccasion == 'Other'
        ? _otherOccasionController.text.trim()
        : _selectedOccasion;

    final deposit = _depositAmount;
    final description = 'Custom Catering Deposit for $_numberOfPeople.toInt() guests ($occasion)';

    try {
      final paymentResult = await RazorpayService.openPayment(
        amount: deposit,
        description: description,
        name: userName,
        email: userEmail,
        contact: phone,
      );

      if (paymentResult.success) {
        final uid = user?.uid ?? 'guest_user';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final orderId = paymentResult.orderId ?? 'CAT_CUST_$timestamp';
        final paymentId = paymentResult.paymentId ?? 'pay_$timestamp';

        final Map<String, dynamic> cateringOrder = {
          'id': orderId,
          'orderNumber': 'CAT-CUST-$timestamp',
          'userId': uid,
          'service': 'Swadishtt Instant Catering',
          'restaurantName': 'Swadishtt Custom Catering',
          'restaurantImage': 'assets/images/pkg_birthday.jpg',
          'packageName': 'Custom Catering ($occasion)',
          'serves': 'Serves ${_numberOfPeople.toInt()} guests',
          'cuisine': _selectedFoodType,
          'address': address,
          'contactPhone': phone,
          'total': _calculatedTotal,
          'depositPaid': deposit,
          'totalPaid': deposit,
          'status': 'Confirmed',
          'paymentMethod': 'Razorpay Deposit',
          'transactionId': paymentId,
          'razorpayOrderId': orderId,
          'createdAt': FieldValue.serverTimestamp(),
          'items': [
            {
              'name': 'Custom Catering for ${_numberOfPeople.toInt()} guests',
              'quantity': 1,
              'price': _calculatedTotal,
              'depositPaid': deposit,
              'cuisine': _selectedFoodType,
              'occasion': occasion,
            }
          ],
        };

        try {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc('${uid}_$orderId')
              .set(cateringOrder, SetOptions(merge: true));

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('swadishtt_orders')
              .doc(orderId)
              .set(cateringOrder, SetOptions(merge: true));
        } catch (fsErr) {
          debugPrint('Firestore direct save note (permission-denied fallback): $fsErr');
        }

        await FirebaseService.createOrder(
          restaurantName: 'Swadishtt Custom Catering',
          restaurantImage: 'assets/images/pkg_birthday.jpg',
          totalAmount: deposit,
          items: (cateringOrder['items'] as List).cast<Map<String, dynamic>>(),
          paymentMethod: 'Razorpay Deposit',
          razorpayOrderId: orderId,
          transactionId: paymentId,
        );

        if (!mounted) return;
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Booking Confirmed!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your custom catering booking for ${_numberOfPeople.toInt()} guests has been confirmed.',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text('• Occasion: $occasion'),
                Text('• Cuisine: $_selectedFoodType'),
                Text('• Estimated Total: ₹${_calculatedTotal.toInt()}'),
                Text('• Deposit Paid via Razorpay: ₹${deposit.toInt()}'),
                Text('• Payment ID: $paymentId'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentResult.message ?? 'Deposit payment failed.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error paying catering deposit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Plan Your Catering',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            // Occasion
            const Text('Select Occasion', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _occasions.map((occasion) {
                final isSelected = _selectedOccasion == occasion;
                return ChoiceChip(
                  label: Text(occasion),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textGrey, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedOccasion = occasion);
                  },
                );
              }).toList(),
            ),
            if (_selectedOccasion == 'Other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otherOccasionController,
                decoration: InputDecoration(
                  hintText: 'Please specify the occasion',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Number of people
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Number of People', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text('${_numberOfPeople.toInt()} guests', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            Slider(
              value: _numberOfPeople,
              min: 10,
              max: 500,
              divisions: 49,
              activeColor: AppColors.primary,
              inactiveColor: Colors.grey.shade300,
              onChanged: (value) {
                setState(() => _numberOfPeople = value);
              },
            ),
            const SizedBox(height: 20),

            // Type of food
            const Text('Type of Food', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _foodTypes.map((food) {
                final isSelected = _selectedFoodType == food;
                return ChoiceChip(
                  label: Text(food),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textGrey, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFoodType = food);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // More Options
            const Text('More Options', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Column(
              children: _moreOptions.keys.map((option) {
                return CheckboxListTile(
                  title: Text(option, style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
                  value: _moreOptions[option],
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _moreOptions[option] = val);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Delivery Details
            const Text('Delivery & Contact Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Phone Number',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Total:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('₹${_calculatedTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Deposit to Lock (25%):', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      Text('₹${_depositAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleRazorpayDeposit,
                icon: const Icon(Icons.payment, size: 18),
                label: Text('Pay Deposit via Razorpay (₹${_depositAmount.toInt()})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _submitQuoteRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Submit Request for Quote', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
