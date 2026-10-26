import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'redeem_code_screen.dart';
import 'security_login_screen.dart';
import 'accesco_library_screen.dart';
import 'referral_screen.dart';
import '../expense_meter/screens/xpense_home.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';
import 'login_screen.dart';
import 'grokly_screen.dart' hide PaymentScreen, MyOrdersScreen;
import 'my_orders.dart';
import 'swadisht_splash_screen.dart';
import 'unified_Cart.dart';
import 'profile_address_screen.dart';
import 'payment_method_screen.dart';
import 'notification_settings_screen.dart';
import 'help_and_support_screen.dart';
import 'partner_with_us_screen.dart';
import 'account_details_screen.dart';
import 'language_region_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, int>> _fetchOrderCounts(String? uid) async {
    if (uid == null || uid.isEmpty) {
      return {'grokly': 0, 'swadishtt': 0, 'total': 0};
    }

    int groklyCount = 0;
    int swadishttCount = 0;

    try {
      // 1. Grokly user orders subcollection
      final groklySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('orders')
          .get();
      groklyCount += groklySnap.docs.length;

      // 2. Swadishtt user orders subcollection
      final swadishttSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('swadishtt_orders')
          .get();
      swadishttCount += swadishttSnap.docs.length;

      // 3. Top-level orders collection
      final topSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .get();

      for (var doc in topSnap.docs) {
        final data = doc.data();
        final service = (data['service'] ?? data['restaurantName'] ?? '').toString().toLowerCase();
        if (service.contains('grokly')) {
          if (!groklySnap.docs.any((d) => d.id == doc.id)) {
            groklyCount++;
          }
        } else if (service.contains('swadishtt') || service.contains('catering')) {
          if (!swadishttSnap.docs.any((d) => d.id == doc.id)) {
            swadishttCount++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching order counts: $e');
    }

    return {
      'grokly': groklyCount,
      'swadishtt': swadishttCount,
      'total': groklyCount + swadishttCount,
    };
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of Accesco Living? You will need to log in again to access your account.',
          style: TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF860038)),
                          ),
                          SizedBox(width: 16),
                          Text('Logging out...', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final navigator = Navigator.of(context, rootNavigator: true);
              final messenger = ScaffoldMessenger.of(context);

              try {
                try {
                  Provider.of<CartProvider>(context, listen: false).clearCart();
                } catch (_) {}

                await userProvider.logout();
              } catch (e) {
                debugPrint('Logout error: $e');
              }

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              backgroundColor: const Color(0xFFDC2626),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    // Get display info safely — works for both phone & email auth
    final String phoneNumber = user?.phone ?? '';
    final String email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. NEW CUSTOM TOP APP BAR ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8F1), // Soft pink background
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),

                    // Accesco Logo
                    Image.asset(
                      'assets/images/accesco_logo.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.blur_circular, color: Color(0xFF6B0721), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Color(0xFF6B0721),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),

                    // Cart Icon
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xFF6B0721),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UnifiedCartScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── 2. NEW HEADER & MEMBERSHIP CARD ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Your Account',
                            style: TextStyle(
                              color: Color(0xFFD81B60), // Pink accent
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your Accesco membership — one card across Grokly, Swadishtt and InstaStyle.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Membership Card
                          FutureBuilder<List<dynamic>>(
                            future: Future.wait([
                              FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                              _fetchOrderCounts(user?.uid),
                            ]),
                            builder: (context, snapshot) {
                              String nameToShow = (user?.name?.isNotEmpty == true) ? user!.name : 'Santosh Reddy';
                              String phoneToShow = phoneNumber.isNotEmpty ? phoneNumber : '+91 99999 99999';
                              String emailToShow = email.isNotEmpty ? email : 'Sample@gmail.com';
                              String cityToShow = 'Bengaluru, KAR';
                              String memberNumber = 'AC-2026-004821';
                              String totalOrders = '0';
                              String rewardPoints = '0';
                              String walletBalance = '₹0';
                              String accountStatus = 'Active';

                              if (snapshot.hasData) {
                                final userDoc = snapshot.data![0] as DocumentSnapshot;
                                final countsMap = snapshot.data![1] as Map<String, int>;
                                
                                int calcTotal = countsMap['total'] ?? 0;
                                totalOrders = '$calcTotal';

                                if (userDoc.exists && userDoc.data() != null) {
                                  final data = userDoc.data() as Map<String, dynamic>;
                                  if ((data['name']?.toString().trim() ?? '').isNotEmpty) {
                                    nameToShow = data['name'].toString().trim();
                                  }
                                  if ((data['phone']?.toString().trim() ?? '').isNotEmpty) {
                                    phoneToShow = data['phone'].toString().trim();
                                  }
                                  if ((data['email']?.toString().trim() ?? '').isNotEmpty) {
                                    emailToShow = data['email'].toString().trim();
                                  }
                                  if ((data['city']?.toString().trim() ?? '').isNotEmpty) {
                                    cityToShow = data['city'].toString().trim();
                                  }
                                  if ((data['memberNumber']?.toString().trim() ?? '').isNotEmpty) {
                                    memberNumber = data['memberNumber'].toString().trim();
                                  }
                                  if (data['totalOrders'] != null && data['totalOrders'].toString() != '0') {
                                    totalOrders = data['totalOrders'].toString();
                                  }
                                  if (data['rewardPoints'] != null) {
                                    rewardPoints = data['rewardPoints'].toString();
                                  }
                                  if (data['walletBalance'] != null) {
                                    walletBalance = '₹${data['walletBalance']}';
                                  }
                                  if ((data['accountStatus']?.toString().trim() ?? '').isNotEmpty) {
                                    accountStatus = data['accountStatus'].toString().trim();
                                  }
                                }
                              }

                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFC2125E), // Pink-Magenta
                                      Color(0xFF4A0416), // Dark Maroon
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6B0721).withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                // Wrap the inside of the card in a ClipRRect to fix the bleeding white circles!
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Card Top Half
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Accesco Member • Est. 2026',
                                                  style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  nameToShow,
                                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  cityToShow,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                            // Avatar with Verified Badge
                                            Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Container(
                                                  width: 54,
                                                  height: 54,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      nameToShow.isNotEmpty ? nameToShow.substring(0, 1).toUpperCase() : 'S',
                                                      style: const TextStyle(color: Color(0xFF6B0721), fontSize: 24, fontWeight: FontWeight.w900),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: -4,
                                                  right: -4,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF4CAF50),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: const Color(0xFF6B0721), width: 2),
                                                    ),
                                                    child: const Icon(Icons.check, color: Colors.white, size: 10),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ── TICKET CUTOUT DIVIDER ──
                                      SizedBox(
                                        height: 24,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            // The thin line in the middle
                                            Align(
                                              alignment: Alignment.center,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.white.withOpacity(0.15),
                                                ),
                                              ),
                                            ),
                                            // Left Cutout (White circle)
                                            Positioned(
                                              left: -12,
                                              top: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 24,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            // Right Cutout (White circle)
                                            Positioned(
                                              right: -12,
                                              top: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 24,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Card Bottom Half
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Text(
                                                'MEMBER NO. $memberNumber',
                                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(phoneToShow, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                                Text(emailToShow, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(totalOrders, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                                    const SizedBox(height: 4),
                                                    const Text('Total orders', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(rewardPoints, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                                    const SizedBox(height: 4),
                                                    const Text('Reward points', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(walletBalance, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                                    const SizedBox(height: 4),
                                                    const Text('Wallet balance', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 8),
                                                        const SizedBox(width: 6),
                                                        Text(accountStatus, style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 18, fontWeight: FontWeight.w900)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    const Text('Account status', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // ── 3. YOUR ACCESCO WORLD ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Circular Commerce',
                            style: TextStyle(
                              color: Color(0xFFD81B60), // Pink accent
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your Accesco world',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Every order you place keeps working across your household profile, three services.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Horizontal Scroll for Services
                    FutureBuilder<Map<String, int>>(
                      future: _fetchOrderCounts(user?.uid),
                      builder: (context, countsSnapshot) {
                        final groklyOrders = countsSnapshot.data?['grokly'] ?? 0;
                        final swadishttOrders = countsSnapshot.data?['swadishtt'] ?? 0;

                        return SizedBox(
                          height: 220,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _buildServiceCard(
                                color: const Color(0xFFF2FCF3), // Grokly Light Green
                                iconColor: const Color(0xFF7CB342),
                                icon: Icons.shopping_basket,
                                tag: 'Groceries',
                                title: 'Grokly',
                                description: 'Fresh groceries and farm-direct essentials, delivered fast.',
                                orders: '$groklyOrders',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => GroklyScreen()));
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildServiceCard(
                                color: const Color(0xFFFFF5F5), // Swadishtt Light Red
                                iconColor: const Color(0xFFE53935),
                                icon: Icons.restaurant,
                                tag: 'Food Delivery',
                                title: 'Swadishtt',
                                description: 'Ghar jaisa khana from neighborhood kitchens.',
                                orders: '$swadishttOrders',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SwadishtSplashScreen()));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
// ── 4. MANAGE YOUR ACCOUNT LIST ──
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Account',
style: TextStyle(
color: Color(0xFFD81B60), // Pink accent
fontSize: 10,
fontWeight: FontWeight.w900,
letterSpacing: 1.5,
),
),
const SizedBox(height: 4),
const Text(
'Manage your account',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.w900,
color: Colors.black87,
letterSpacing: -0.5,
),
),
const SizedBox(height: 16),

// The unified bordered box
Container(
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(24),
border: Border.all(color: Colors.black12, width: 0.8),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 8),
const Padding(
padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
child: Text('Account', style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w800, letterSpacing: 1)),
),
_MenuItem(icon: Icons.person_outline, title: l10n?.accountDetails ?? 'Account details', isSelected: true, onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsScreen())); }),
_MenuItem(
  icon: Icons.shopping_bag_outlined, 
  title: l10n?.myOrders ?? 'My Orders', 
  onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
  }
),
_MenuItem(
  icon: Icons.location_on_outlined, 
  title: l10n?.addresses ?? 'Addresses', 
  onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileAddressScreen()));
  }
),
_MenuItem(
  icon: Icons.payment, 
  title: l10n?.paymentMethods ?? 'Payment methods', 
  onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodScreen()));
  }
),
_MenuItem(icon: Icons.card_giftcard, title: l10n?.redeemCode ?? 'Redeem a code', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const RedeemCodeScreen())); }),


_MenuItem(
  icon: Icons.notifications_outlined, 
  title: l10n?.notifications ?? 'Notifications', 
  onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
  }
),
_MenuItem(icon: Icons.language, title: l10n?.languageAndRegion ?? 'Language & region', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageRegionScreen())); }),
_MenuItem(icon: Icons.shield_outlined, title: l10n?.security ?? 'Security', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityLoginScreen())); }),
_MenuItem(
  icon: Icons.help_outline, 
  title: l10n?.helpAndSupport ?? 'Help & support', 
  onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpAndSupportScreen()));
  }
),

Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: Divider(color: Colors.black.withOpacity(0.05), height: 32),
),

const Padding(
padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
child: Text('Explore', style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w800, letterSpacing: 1)),
),
_MenuItem(icon: Icons.card_giftcard, title: l10n?.inviteAndEarn ?? 'Invite & earn', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())); }),
_MenuItem(icon: Icons.video_library_outlined, title: l10n?.accescoLibrary ?? 'Accesco Library', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const AccescoLibraryScreen())); }),
_MenuItem(icon: Icons.account_balance_wallet_outlined, title: l10n?.xpenseMeter ?? 'Xpense Meter', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const XpenseHomeScreen())); }),
_MenuItem(icon: Icons.handshake_outlined, title: l10n?.partnerWithUs ?? 'Partner with us', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerWithUsScreen())); }),

Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: Divider(color: Colors.black.withOpacity(0.05), height: 32),
),

// Logout
_MenuItem(
  icon: Icons.logout,
  title: l10n?.signOut ?? 'Log Out',
  isLogout: true,
  onTap: () => _showLogoutDialog(context, userProvider),
),
const SizedBox(height: 16),
],
),
),
],
),
),
const SizedBox(height: 32),
// ── 5. FOOTER ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('© 2026 Accesco Living. All rights reserved.', style: TextStyle(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.w600)),
                          Text('Bengaluru, Karnataka • India', style: TextStyle(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the horizontal service cards
  Widget _buildServiceCard({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String tag,
    required String title,
    required String description,
    required String orders,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.black87, size: 20),
              ),
              Text(
                tag,
                style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            height: 1,
            color: Colors.black.withOpacity(0.05),
            margin: const EdgeInsets.symmetric(vertical: 12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orders, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                  const Text('Orders placed', style: TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              ),
              const Text(
                'Order History',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
class _MenuItem extends StatelessWidget {
final IconData icon;
final String title;
final VoidCallback onTap;
final bool isSelected;
final bool isLogout;

const _MenuItem({
required this.icon,
required this.title,
required this.onTap,
this.isSelected = false,
this.isLogout = false,
});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: isLogout
              ? const Color(0xFFFEF2F2)
              : (isSelected ? const Color(0xFFFDE8F1) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: isLogout ? Border.all(color: const Color(0xFFFECACA), width: 1) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isLogout
                    ? const Color(0xFFFEE2E2)
                    : (isSelected ? Colors.white : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isLogout ? const Color(0xFFDC2626) : Colors.black87,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isLogout || isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isLogout ? const Color(0xFFDC2626) : Colors.black87,
                ),
              ),
            ),
            if (isLogout)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFEF4444)),
          ],
        ),
      ),
    );
  }
}
