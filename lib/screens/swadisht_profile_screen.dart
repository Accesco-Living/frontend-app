import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';
import '../services/razorpay_service.dart';
import 'login_screen.dart';
import 'profile_address_screen.dart';
import 'payment_method_screen.dart';
import 'swadishtt_notification_settings_screen.dart';
import 'security_login_screen.dart';
import 'swadisht_orders_screen.dart';
import 'swadisht_favorite_meals_screen.dart';

class SwadishtProfileScreen extends StatelessWidget {
  const SwadishtProfileScreen({Key? key}) : super(key: key);

  final Color primaryRed =
      const Color(0xFF9B111E); // Approximate dark red from image
  final Color lightRedBorder = const Color(0x409B111E);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    
    final String phoneNumber = user?.phone ?? '';
    final String email = user?.email ?? '';
    
    String rawName = user?.name.trim() ?? '';
    if (rawName.toLowerCase() == 'accesco member') {
      rawName = '';
    }

    final String phoneToShow = phoneNumber.isNotEmpty ? phoneNumber : '+91 00000 00000';
    final String nameToShow = rawName.isNotEmpty ? rawName : phoneToShow;
    final String emailToShow = email.isNotEmpty ? email : 'user@example.com';
    final String avatarChar = rawName.isNotEmpty ? rawName[0].toUpperCase() : (phoneNumber.isNotEmpty ? '#' : 'U');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/Swadishtt/swadishtt_logo.png',
              height: 44, // Slightly larger logo
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.restaurant, color: Colors.red),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Swadishtt',
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 22, // Increased font
                  ),
                ),
                const Text(
                  'Homely meals, delivered',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14, // Increased font
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_none,
                  color: primaryRed, size: 26), // Increased icon size
              onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const SwadishttNotificationSettingsScreen())); },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              icon: Icon(Icons.settings_outlined,
                  color: primaryRed, size: 26), // Increased icon size
              onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityLoginScreen())); },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: user?.uid != null
                  ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots()
                  : null,
              builder: (context, snapshot) {
                String dName = nameToShow;
                String dPhone = phoneToShow;
                String dEmail = emailToShow;
                String dAvatar = avatarChar;
                int walletBalance = 0;
                int loyaltyPoints = 0;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    if ((data['name']?.toString().trim() ?? '').isNotEmpty) {
                      dName = data['name'].toString().trim();
                    }
                    if ((data['phone']?.toString().trim() ?? '').isNotEmpty) {
                      dPhone = data['phone'].toString().trim();
                    }
                    if ((data['email']?.toString().trim() ?? '').isNotEmpty) {
                      dEmail = data['email'].toString().trim();
                    }
                    if (data['credits'] != null) {
                      walletBalance = data['credits'] is int
                          ? data['credits']
                          : int.tryParse(data['credits'].toString()) ?? 0;
                    }
                    if (data['loyalty_points'] != null) {
                      loyaltyPoints = data['loyalty_points'] is int
                          ? data['loyalty_points']
                          : int.tryParse(data['loyalty_points'].toString()) ?? 0;
                    } else if (data['reward_points'] != null) {
                      loyaltyPoints = data['reward_points'] is int
                          ? data['reward_points']
                          : int.tryParse(data['reward_points'].toString()) ?? 0;
                    } else if (data['cqs_score'] != null) {
                      loyaltyPoints = data['cqs_score'] is int
                          ? data['cqs_score']
                          : (data['cqs_score'] is double ? (data['cqs_score'] as double).toInt() : 0);
                    }
                    if (dName.toLowerCase() == 'accesco member') {
                      dName = dPhone;
                    }
                    dAvatar = dName.isNotEmpty && dName != dPhone ? dName[0].toUpperCase() : (dPhone.isNotEmpty ? '#' : 'U');
                  }
                }
                return Column(
                  children: [
                    _buildProfileCard(dName, dPhone, dEmail, dAvatar),
                    const SizedBox(height: 16),
                    _buildWalletCard(context, walletBalance, user?.uid),
                    const SizedBox(height: 16),
                    _buildMemberCard(loyaltyPoints),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _buildMyOrdersSection(context),
            const SizedBox(height: 24),
            _buildQuickActionsSection(context),
            const SizedBox(height: 32),
            _buildLogoutButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String phone, String email, String avatarChar) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(
                    avatarChar,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, color: primaryRed, size: 18),
              const SizedBox(width: 6),
              Text(
                phone,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, color: primaryRed, size: 18),
              const SizedBox(width: 6),
              Text(
                email,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, int balance, String? uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet,
                color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Wallet',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                'Current Balance',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showTopUpDialog(context, uid),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '+ Add Money',
                    style: TextStyle(
                        color: primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showTransactionHistoryModal(context, uid),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Transaction History',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, String? uid) {
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to top up your wallet.')),
      );
      return;
    }

    final amountController = TextEditingController(text: '200');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Top Up Swadishtt Wallet',
                style: TextStyle(fontWeight: FontWeight.w900, color: primaryRed, fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text('Enter amount to add via Razorpay Payment Gateway:', style: TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryRed),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [100, 200, 500, 1000].map((amt) {
                  return ActionChip(
                    label: Text('+$amt'),
                    backgroundColor: Colors.red.shade50,
                    labelStyle: TextStyle(color: primaryRed, fontWeight: FontWeight.bold),
                    onPressed: () {
                      amountController.text = amt.toString();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amount <= 0) return;

                    Navigator.pop(modalContext);

                    RazorpayService.openCheckout(
                      amount: amount,
                      name: 'Swadishtt Wallet Top-Up',
                      description: 'Adding ₹$amount to Swadishtt Wallet',
                      userEmail: 'user@example.com',
                      userPhone: '+919999999999',
                      onSuccess: (paymentId, orderId, signature) async {
                        try {
                          await FirebaseFirestore.instance.collection('users').doc(uid).set({
                            'credits': FieldValue.increment(amount.toInt()),
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          await FirebaseService.recordWalletTransaction(
                            uid: uid,
                            amount: amount,
                            type: 'credit',
                            description: 'Wallet Top-Up via Razorpay ($paymentId)',
                            paymentId: paymentId,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('₹${amount.toStringAsFixed(0)} added to your Swadishtt Wallet!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error crediting wallet: $e');
                        }
                      },
                      onFailure: (code, message) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Payment failed: $message'), backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Proceed to Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showTransactionHistoryModal(BuildContext context, String? uid) {
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Transaction History', style: TextStyle(fontWeight: FontWeight.w900, color: primaryRed, fontSize: 20)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('wallet_transactions')
                          .where('userId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('No transaction history found.', style: TextStyle(color: Colors.black54)),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.separated(
                          controller: scrollController,
                          itemCount: docs.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tx = docs[index].data() as Map<String, dynamic>;
                            final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                            final isCredit = tx['type'] == 'credit';
                            final desc = tx['description'] ?? tx['title'] ?? (isCredit ? 'Wallet Top-Up' : 'Order Payment');

                            return ListTile(
                              leading: Icon(
                                isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                color: isCredit ? Colors.green : primaryRed,
                                size: 28,
                              ),
                              title: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(
                                tx['paymentId'] != null ? 'Ref: ${tx['paymentId']}' : 'Swadishtt Wallet',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              trailing: Text(
                                '${isCredit ? "+" : "-"}₹${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isCredit ? Colors.green : primaryRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMemberCard(int loyaltyPoints) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium,
                color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Swadishtt Member',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'You are saving more with every order !',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                loyaltyPoints.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26),
              ),
              Text(
                'Loyalty Points',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyOrdersSection(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.getOrdersStream(),
      builder: (context, snapshot) {
        int ongoing = 0;
        int onTheWay = 0;
        int delivered = 0;
        int cancelled = 0;

        if (snapshot.hasData) {
          for (var order in snapshot.data!) {
            final status = (order['status'] as String?)?.toLowerCase() ?? '';
            if (status == 'ongoing' || status == 'preparing') {
              ongoing++;
            } else if (status == 'on the way' || status == 'out for delivery') {
              onTheWay++;
            } else if (status == 'delivered' || status == 'completed') {
              delivered++;
            } else if (status == 'cancelled') {
              cancelled++;
            }
          }
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Orders',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SwadishtOrdersScreen()),
                    );
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(
                        color: primaryRed, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOrderItem(Icons.shopping_bag, 'Ongoing', ongoing.toString(), Colors.brown),
                  _buildOrderItem(
                      Icons.two_wheeler, 'On the Way', onTheWay.toString(), Colors.brown.shade800),
                  _buildOrderItem(
                      Icons.check_circle_outline, 'Delivered', delivered.toString(), Colors.green),
                  _buildOrderItem(
                      Icons.cancel_outlined, 'Cancelled', cancelled.toString(), primaryRed),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildOrderItem(
      IconData icon, String label, String count, Color iconColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
              color: primaryRed, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Column(
            children: [
              _buildActionTile(
                Icons.location_on, 'Saved Addresses', 'Manage your saved delivery addresses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileAddressScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 64, color: Colors.black12),
              _buildActionTile(
                Icons.credit_card, 'Payment Methods', 'UPI, Cards, Wallets & more',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 64, color: Colors.black12),
              _buildActionTile(Icons.favorite, 'Favourite Meals', 'Your loved meals at one place',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SwadishtFavoriteMealsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryRed, size: 24),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: Colors.black54, size: 28),
      onTap: onTap ?? () {},
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: primaryRed, size: 24),
            const SizedBox(width: 10),
            const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? You will need to log in again to access Swadishtt and your account.',
          style: TextStyle(height: 1.4, fontSize: 14, color: Color(0xFF4B5563)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => Center(
                  child: Card(
                    color: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryRed),
                          ),
                          const SizedBox(width: 16),
                          const Text('Logging out...', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final navigator = Navigator.of(context, rootNavigator: true);
              final messenger = ScaffoldMessenger.of(context);

              try {
                Provider.of<CartProvider>(context, listen: false).clearCart();
              } catch (_) {}

              try {
                await userProvider.logout();
              } catch (e) {
                debugPrint('Swadishtt logout error: $e');
              }

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Color(0xFF1E293B),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: Icon(Icons.logout, color: primaryRed, size: 24),
        label: Text(
          'Log Out',
          style: TextStyle(
              color: primaryRed, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red.shade200, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
