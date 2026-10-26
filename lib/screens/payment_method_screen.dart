import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../models/payment_method_model.dart';
import '../providers/payment_provider.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentProvider(),
      child: const _PaymentMethodScreenContent(),
    );
  }
}

class _PaymentMethodScreenContent extends StatefulWidget {
  const _PaymentMethodScreenContent();

  @override
  State<_PaymentMethodScreenContent> createState() => _PaymentMethodScreenContentState();
}

class _PaymentMethodScreenContentState extends State<_PaymentMethodScreenContent> {
  static const Color brandPrimary = Color(0xFF90103B);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGray = Color(0xFF64748B);
  static const Color lightPinkBg = Color(0xFFFDF5F8);
  static const Color pinkBorder = Color(0xFFF3E1E8);
  static const Color grayBorder = Color(0xFFF1F5F9);
  
  String? _selectedMethodId;

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final savedMethods = paymentProvider.paymentMethods;
    
    // Auto-select default if none selected
    if (_selectedMethodId == null && savedMethods.isNotEmpty) {
      try {
        _selectedMethodId = savedMethods.firstWhere((m) => m.isDefault).id;
      } catch (e) {
        _selectedMethodId = savedMethods.first.id;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payments',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black, size: 24),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[100],
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (paymentProvider.isLoading)
                  const Center(child: CircularProgressIndicator(color: brandPrimary))
                else if (savedMethods.isNotEmpty) ...[
                  // --- Saved Payment Methods ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Payment Methods',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Manage',
                          style: TextStyle(
                            color: brandPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ...savedMethods.map((method) {
                    IconData? icon;
                    if (method.brandText.toLowerCase() == 'mc') icon = Icons.circle;
                    if (method.brandText.toLowerCase() == 'rupay') icon = Icons.credit_card;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSavedMethod(
                        id: method.id,
                        title: method.title,
                        subtitle: method.subtitle,
                        brandText: method.brandText,
                        brandIcon: icon,
                        isDefault: method.isDefault,
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
                
                // --- Add Payment Method ---
                const Text(
                  'Add Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildActionCard(
                  title: 'Credit or Debit Card',
                  subtitle: 'Add and save your card securely',
                  icon: Icons.credit_card,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  title: 'UPI',
                  subtitle: 'Pay with any UPI app',
                  iconText: 'UPI',
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  title: 'Wallet',
                  subtitle: 'Link your wallet for faster payments',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  title: 'Net Banking',
                  subtitle: 'Pay directly from your bank',
                  icon: Icons.account_balance,
                ),
                
                const SizedBox(height: 32),
                
                // --- More Options ---
                const Text(
                  'More Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildActionCard(
                  title: 'Have a promo code?',
                  subtitle: 'Apply and save on your next order',
                  icon: Icons.card_giftcard,
                ),
                
                const SizedBox(height: 100), // padding for bottom button
              ],
            ),
          ),
          
          // --- Bottom Button ---
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: brandPrimary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add payment method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

  Widget _buildSavedMethod({
    required String id,
    required String title,
    required String subtitle,
    required String brandText,
    IconData? brandIcon,
    bool isDefault = false,
  }) {
    bool isSelected = _selectedMethodId == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethodId = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? lightPinkBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? pinkBorder : grayBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? brandPrimary : Colors.grey[400]!,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Brand Logo Placeholder
            Container(
              width: 46,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              alignment: Alignment.center,
              child: brandIcon != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(brandIcon, color: Colors.red, size: 14),
                        const SizedBox(width: 2),
                        Icon(brandIcon, color: Colors.orange, size: 14),
                      ],
                    )
                  : Text(
                      brandText,
                      style: TextStyle(
                        fontSize: brandText.length > 4 ? 9 : 12,
                        fontWeight: FontWeight.w900,
                        color: brandText == 'VISA' ? Colors.blue[800] : 
                               brandText == 'paytm' ? Colors.lightBlue : textDark,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: pinkBorder),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: brandPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // More options
            const Icon(Icons.more_vert, color: textGray, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    IconData? icon,
    String? iconText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: grayBorder, width: 1.5),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lightPinkBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: brandPrimary, size: 20)
                : Text(
                    iconText ?? '',
                    style: const TextStyle(
                      color: brandPrimary,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Chevron
          const Icon(Icons.chevron_right, color: textGray, size: 20),
        ],
      ),
    );
  }
}
