import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/razorpay_service.dart';
import 'checkout_screen.dart';
import '../widgets/plan_catering_bottom_sheet.dart';



// ─────────────────────────────────────────────

//  Entry Point

// ─────────────────────────────────────────────

void main() => runApp(const InstantCateringApp());



class InstantCateringApp extends StatelessWidget {

  const InstantCateringApp({super.key});



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'Instant Catering',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(

        fontFamily: 'Poppins',

        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),

        useMaterial3: true,

      ),

      home: const InstantCateringPage(),

    );

  }

}



// ─────────────────────────────────────────────

//  Colour Palette

// ─────────────────────────────────────────────

class AppColors {

  static const Color primary = Color(0xFFCC1212);

  static const Color primaryDark = Color(0xFFAA0000);

  static const Color cream = Color(0xFFFDF3EE);

  static const Color textDark = Color(0xFF1A0A00);

  static const Color textGrey = Color(0xFF6B6B6B);

  static const Color gold = Color(0xFFD4A017);

  static const Color white = Colors.white;

  static const Color statsBar = Color(0xFF2A2A2A);

  static const Color greenCheck = Color(0xFF2E7D32);

}



// ─────────────────────────────────────────────

//  Asset paths (change these if your folder differs)

// ─────────────────────────────────────────────

class AppAssets {

  static const String heroBg = 'assets/images/hero_bg.jpg';

  static const String smallGathering = 'assets/images/pkg_small_gathering.jpg';

  static const String birthday = 'assets/images/pkg_birthday.jpg';

  static const String officeLunch = 'assets/images/pkg_office_lunch.jpg';

  static const String miniWedding = 'assets/images/pkg_mini_wedding.jpg';

}



// ─────────────────────────────────────────────

//  Main Page

// ─────────────────────────────────────────────

class InstantCateringPage extends StatefulWidget {

  const InstantCateringPage({super.key});



  @override

  State<InstantCateringPage> createState() => _InstantCateringPageState();

}



class _InstantCateringPageState extends State<InstantCateringPage> {

  final GlobalKey _packagesKey = GlobalKey();



  void _scrollToPackages() {

    if (_packagesKey.currentContext != null) {

      Scrollable.ensureVisible(

        _packagesKey.currentContext!,

        duration: const Duration(milliseconds: 600),

        curve: Curves.easeInOut,

      );

    }

  }



  void _openPlanCateringForm() {

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (context) => Padding(

        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),

        child: const PlanCateringBottomSheet(),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.cream,

      body: Column(

        children: [

          _TopNavBar(onOrderNow: _scrollToPackages),

          Expanded(

            child: SingleChildScrollView(

              child: Column(

                children: [

                  _HeroSection(onOrderNow: _scrollToPackages, onPlanCatering: _openPlanCateringForm),

                  _StatsBar(),

                  _PackagesSection(key: _packagesKey),

                  _HowItWorksSection(),

                  _TestimonialsSection(),

                  _CtaSection(onOrderNow: _scrollToPackages),

                  _Footer(),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

}



// ─────────────────────────────────────────────

//  Top Navigation Bar

// ─────────────────────────────────────────────

class _TopNavBar extends StatelessWidget {

  final VoidCallback? onOrderNow;

  const _TopNavBar({this.onOrderNow});



  @override

  Widget build(BuildContext context) {

    return Container(

      color: AppColors.white,

      padding: const EdgeInsets.symmetric(horizontal: 19.2, vertical: 12),

      child: SafeArea(

        bottom: false,

        child: Row(

          children: [

            RichText(

              text: const TextSpan(

                children: [

                  TextSpan(

                    text: 'Swad',

                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17.2, color: AppColors.textDark, letterSpacing: -0.3),

                  ),

                  TextSpan(

                    text: 'ishtt',

                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17.2, color: AppColors.primary, letterSpacing: -0.3),

                  ),

                ],

              ),

            ),

            const SizedBox(width: 11.5),

            Container(width: 1, height: 18.4, color: const Color(0xFFE0E0E0)),

            const SizedBox(width: 11.5),

            const Text('Instant Catering', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.9, color: AppColors.textDark)),

            const Spacer(),

            GestureDetector(

              onTap: onOrderNow,

              child: Container(

                padding: const EdgeInsets.symmetric(horizontal: 16.8, vertical: 8.4),

                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),

                child: const Text('Order Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.8)),

              ),

            ),

          ],

        ),

      ),

    );

  }

}



// ─────────────────────────────────────────────

//  Hero Section  — uses hero_bg.jpg as background

// ─────────────────────────────────────────────

class _HeroSection extends StatelessWidget {

  final VoidCallback? onOrderNow;

  final VoidCallback? onPlanCatering;

  const _HeroSection({this.onOrderNow, this.onPlanCatering});



  @override

  Widget build(BuildContext context) {

    return SizedBox(

      // Constrain height so image doesn't stretch infinitely

      child: Stack(

        children: [

          // ── Background image ──

          Positioned.fill(

            child: Image.asset(

              AppAssets.heroBg,

              fit: BoxFit.cover,

              // Fallback gradient while image loads (or if it fails)

              errorBuilder: (_, __, ___) => Container(

                decoration: const BoxDecoration(

                  gradient: LinearGradient(

                    colors: [Color(0xFFFDF0E8), Color(0xFFF8D9C8)],

                    begin: Alignment.topLeft,

                    end: Alignment.bottomRight,

                  ),

                ),

              ),

            ),

          ),



          // ── Cream-to-transparent overlay for text legibility ──

          Positioned.fill(

            child: Container(

              decoration: const BoxDecoration(

                gradient: LinearGradient(

                  begin: Alignment.topCenter,

                  end: Alignment.bottomCenter,

                  colors: [

                    Color(0xE8FDF0E8), // nearly opaque cream at top

                    Color(0xC0FDF0E8), // semi-opaque in middle

                    Color(0xF5FDF0E8), // nearly opaque cream at bottom

                  ],

                  stops: [0.0, 0.45, 1.0],

                ),

              ),

            ),

          ),



          // ── Decorative spice dots ──





          // ── Foreground content ──

          Padding(

            padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // Label chip

                

                const SizedBox(height: 20.1),



                // Headline

                RichText(

                  text: const TextSpan(

                    style: TextStyle(fontSize: 29.9, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5),

                    children: [

                      TextSpan(text: 'Celebration-ready food,\n', style: TextStyle(color: AppColors.primary)),

                      TextSpan(text: 'delivered', style: TextStyle(color: AppColors.primary, fontStyle: FontStyle.italic)),

                      TextSpan(text: ' to your door.', style: TextStyle(color: Color(0xFF1A0A00))),

                    ],

                  ),

                ),

                const SizedBox(height: 14.4),



                // Sub-headline

                Text(

                  'Pre-curated packs for 10-50 guests. No planning needed\n— pick a pack, customise it, and we\'ll handle the rest.',

                  style: TextStyle(color: AppColors.textGrey, fontSize: 13.2, height: 1.5),

                ),

                const SizedBox(height: 20.1),



                // Feature pills

                Wrap(

                  spacing: 10,

                  runSpacing: 6,

                  children: const [

                    _FeaturePill(icon: Icons.delivery_dining, label: '0-5h delivery'),

                    _FeaturePill(icon: Icons.event_note_outlined, label: 'No-menu planning'),

                    _FeaturePill(icon: Icons.event_note_outlined, label: 'Free cancellation'),

                    _FeaturePill(icon: Icons.cancel_outlined, label: 'Same-day available', bgColor: Colors.red),

                  ],

                ),

                const SizedBox(height: 8.6),

                

                const SizedBox(height: 23),



                // CTA buttons

                Row(

                  children: [

                    Expanded(child: _PrimaryButton(label: 'Plan My Catering →', onTap: onPlanCatering)),

                    const SizedBox(width: 14.4),

                    Expanded(child: _OutlineButton(label: 'View Packages', onTap: onOrderNow)),

                  ],

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}



class _SpiceDot extends StatelessWidget {

  final double size;

  final Color color;

  const _SpiceDot({required this.size, required this.color});



  @override

  Widget build(BuildContext context) => Container(

        width: size,

        height: size,

        decoration: BoxDecoration(color: color, shape: BoxShape.circle),

      );

}



class _FeaturePill extends StatelessWidget {

  final IconData icon;

  final String label;

  final Color bgColor;  // background colour — defaults to white

  const _FeaturePill({required this.icon, required this.label, this.bgColor = Colors.white});



  @override

  Widget build(BuildContext context) {

    // When a coloured background is used, switch icon & text to white

    final bool isColoured = bgColor != Colors.white;

    final Color contentColor = isColoured ? Colors.white : AppColors.primary;

    final Color textColor    = isColoured ? Colors.white : AppColors.textDark;



    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 9.6, vertical: 4.8),

      decoration: BoxDecoration(

        color: bgColor,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],

      ),

      child: Row(

        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(icon, size: 13.8, color: contentColor),

          const SizedBox(width: 5),

          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: textColor)),

        ],

      ),

    );

  }

}



class _PrimaryButton extends StatelessWidget {

  final String label;

  final VoidCallback? onTap;

  const _PrimaryButton({required this.label, this.onTap});



  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

      padding: const EdgeInsets.symmetric(vertical: 15.6),

      decoration: BoxDecoration(

        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.centerLeft, end: Alignment.centerRight),

        borderRadius: BorderRadius.circular(25),

        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],

      ),

      child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.8))),

    ),

    );

  }

}



class _OutlineButton extends StatelessWidget {

  final String label;

  final VoidCallback? onTap;

  const _OutlineButton({required this.label, this.onTap});



  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

      padding: const EdgeInsets.symmetric(vertical: 14.4),

      decoration: BoxDecoration(

        color: Colors.white.withOpacity(0.85),

        borderRadius: BorderRadius.circular(25),

        border: Border.all(color: AppColors.primary.withOpacity(0.4)),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],

      ),

      child: Center(child: Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13.8))),

    ),

    );

  }

}



// ─────────────────────────────────────────────

//  Stats Bar

// ─────────────────────────────────────────────

class _StatsBar extends StatelessWidget {

  @override

  Widget build(BuildContext context) {

    return Container(

      color: AppColors.statsBar,

      padding: const EdgeInsets.symmetric(horizontal: 14.4, vertical: 16.8),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: const [

          _StatItem(value: '500+', sub: 'Packs Ordered'),

          _StatDivider(),

          _StatItem(value: '4.9 ★', sub: 'Avg rating', highlight: true),

          _StatDivider(),

          _StatItem(value: 'Same-Day', sub: 'Booking Available'),

          _StatDivider(),

          _StatItem(value: '10K+', sub: 'Guests Served'),

        ],

      ),

    );

  }

}



class _StatItem extends StatelessWidget {

  final String value;

  final String sub;

  final bool highlight;

  const _StatItem({required this.value, required this.sub, this.highlight = false});



  @override

  Widget build(BuildContext context) {

    return Column(

      children: [

        Text(value, style: TextStyle(color: highlight ? AppColors.gold : AppColors.white, fontWeight: FontWeight.w800, fontSize: 14.9)),

        const SizedBox(height: 2.5),

        Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 9.8), textAlign: TextAlign.center),

      ],

    );

  }

}



class _StatDivider extends StatelessWidget {

  const _StatDivider();

  @override

  Widget build(BuildContext context) => Container(width: 1, height: 32.2, color: Colors.white12);

}



// ─────────────────────────────────────────────

//  Packages Section

// ─────────────────────────────────────────────

class _PackageInfo {

  final String name;

  final String serves;

  final String description;

  final String price;

  final String originalPrice;

  final List<String> items;

  final String? badge;

  final Color? badgeColor;

  final String imageAsset;



  const _PackageInfo({

    required this.name,

    required this.serves,

    required this.description,

    required this.price,

    required this.originalPrice,

    required this.items,

    required this.imageAsset,

    this.badge,

    this.badgeColor,

  });

}



  void _openPackageBookingForm(BuildContext context, _PackageInfo info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _PackageBookingSheet(info: info),
    );
  }

class _PackagesSection extends StatelessWidget {

  const _PackagesSection({super.key});

  static const List<_PackageInfo> packages = [

    _PackageInfo(

      name: 'Small Gathering',

      serves: 'Serves 10-15 people',

      description: 'A comforting everyday spread for intimate get-togethers.',

      price: '₹2,999',

      originalPrice: '₹3,499',

      items: ['2 Starters', '3 Main Courses', '2 Breads', '1 Rice', '1 Dessert'],

      imageAsset: AppAssets.smallGathering,

    ),

    _PackageInfo(

      name: 'Birthday Celebration',

      serves: 'Serves 20-30 people',

      description: 'A stunning pack — festive, generous, and photo-ready.',

      price: '₹4,999',

      originalPrice: '₹5,999',

      items: ['4 Starters', '4 Main Courses', '3 Breads', '1 Rice', '2 Desserts'],

      imageAsset: AppAssets.birthday,

      badge: 'Most Popular',

      badgeColor: Color(0xFFCC1212),

    ),

    _PackageInfo(

      name: 'Office Lunch Pack',

      serves: 'Serves 15-25 people',

      description: 'Individually packed, easy to serve, ideal for teams.',

      price: '₹3,499',

      originalPrice: '₹4,199',

      items: ['2 Starters', '3 Main Courses', '2 Breads', '1 Rice', 'Salad'],

      imageAsset: AppAssets.officeLunch,

    ),

    _PackageInfo(

      name: 'Mini Wedding Pack',

      serves: 'Serves 40-75 people',

      description: 'A premium multi-course spread for milestone days.',

      price: '₹9,999',

      originalPrice: '₹12,499',

      items: ['6 Starters', '5 Main Courses', '3 Breads', '1 Rice', '3 Desserts'],

      imageAsset: AppAssets.miniWedding,

      badge: 'Premium',

      badgeColor: Color(0xFFD4A017),

    ),

  ];



  @override

  

  @override
  Widget build(BuildContext context) {

    return Container(

      decoration: const BoxDecoration(

        gradient: LinearGradient(

          begin: Alignment.topCenter,

          end: Alignment.bottomCenter,

          colors: [Color(0xFFFDF3EE), Color(0xFFF5E0D3)],

        ),

      ),

      padding: const EdgeInsets.symmetric(vertical: 33.6),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Section header

          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 21.6),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Text('Our Packs', style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)),

                const SizedBox(height: 5),

                const Text('Choose your package', style: TextStyle(color: AppColors.textDark, fontSize: 25.3, fontWeight: FontWeight.w800, height: 1.2)),

                const SizedBox(height: 8.6),

                Text('All packages include delivery, packaging, and a dedicated support contact.', style: TextStyle(color: AppColors.textGrey, fontSize: 13.8, height: 1.5)),

              ],

            ),

          ),

          const SizedBox(height: 25.9),



          // Horizontal scroll cards

          SizedBox(

            height: 460.0,

            child: ListView.separated(

              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(horizontal: 21.6),

              itemCount: packages.length,

              separatorBuilder: (_, __) => const SizedBox(width: 20.1),

              itemBuilder: (context, i) => _PackageCard(info: packages[i], onBookNow: () => _openPackageBookingForm(context, packages[i])),

            ),

          ),

        ],

      ),

    );

  }

}



// ─────────────────────────────────────────────

//  Package Card

// ─────────────────────────────────────────────

class _PackageCard extends StatelessWidget {

  final _PackageInfo info;

  final VoidCallback onBookNow;

  const _PackageCard({required this.info, required this.onBookNow});



  bool get _isPopular => info.badge == 'Most Popular';



  @override

  Widget build(BuildContext context) {

    return Container(

      width: 230.0,

      decoration: BoxDecoration(

        color: _isPopular ? AppColors.primaryDark : Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 7))],

        border: _isPopular ? null : Border.all(color: Colors.black.withOpacity(0.07)),

      ),

      clipBehavior: Clip.hardEdge,

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // ── Photo ──

          Stack(

            children: [

              SizedBox(

                height: 138,

                width: double.infinity,

                child: Image.asset(

                  info.imageAsset,

                  fit: BoxFit.cover,

                  errorBuilder: (_, __, ___) => Container(

                    color: _isPopular ? const Color(0xFF8B0000) : const Color(0xFFE8C49A),

                    child: Center(child: Icon(Icons.restaurant, size: 46, color: Colors.white.withOpacity(0.7))),

                  ),

                ),

              ),

              // Gradient overlay at the bottom of image for smooth text transition

              Positioned(

                bottom: 0,

                left: 0,

                right: 0,

                height: 46,

                child: Container(

                  decoration: BoxDecoration(

                    gradient: LinearGradient(

                      begin: Alignment.topCenter,

                      end: Alignment.bottomCenter,

                      colors: [Colors.transparent, (_isPopular ? AppColors.primaryDark : Colors.white).withOpacity(0.7)],

                    ),

                  ),

                ),

              ),

              // Badge

              if (info.badge != null)

                Positioned(

                  top: 10,

                  left: 10,

                  child: Container(

                    padding: const EdgeInsets.symmetric(horizontal: 9.6, vertical: 4.8),

                    decoration: BoxDecoration(color: info.badgeColor, borderRadius: BorderRadius.circular(8)),

                    child: Text(info.badge!, style: const TextStyle(color: Colors.white, fontSize: 10.3, fontWeight: FontWeight.w700)),

                  ),

                ),

            ],

          ),



          // ── Content ──

          Expanded(

            child: Padding(

              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(info.name, style: TextStyle(color: _isPopular ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 15.5)),

                  const SizedBox(height: 2.5),

                  Text(info.serves, style: TextStyle(color: _isPopular ? Colors.white60 : AppColors.textGrey, fontSize: 11.5)),

                  const SizedBox(height: 5),

                  Text(info.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: _isPopular ? Colors.white70 : AppColors.textGrey, fontSize: 11.5, height: 1.4)),

                  const SizedBox(height: 11.5),

                  // Price

                  Row(

                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: [

                      Text(info.price, style: TextStyle(color: _isPopular ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w900, fontSize: 19.5)),

                      const SizedBox(width: 8.6),

                      Text(info.originalPrice, style: TextStyle(color: _isPopular ? Colors.white38 : Colors.black26, fontSize: 11.5, decoration: TextDecoration.lineThrough)),

                    ],

                  ),

                  const SizedBox(height: 8.6),

                  // Items list

                  ...info.items.map((item) => Padding(

                    padding: const EdgeInsets.only(bottom: 2.4),

                    child: Row(

                      children: [

                        Icon(Icons.check_circle, size: 12.6, color: _isPopular ? Colors.greenAccent : AppColors.greenCheck),

                        const SizedBox(width: 7.1),

                        Text(item, style: TextStyle(color: _isPopular ? Colors.white70 : AppColors.textGrey, fontSize: 11.5)),

                      ],

                    ),

                  )),

                  const Spacer(),

                  // Book Now

                  GestureDetector(

                    onTap: onBookNow,

                    child: Container(

                      width: double.infinity,

                      padding: const EdgeInsets.symmetric(vertical: 12),

                      decoration: BoxDecoration(

                        color: _isPopular ? Colors.white : AppColors.primaryDark,

                        borderRadius: BorderRadius.circular(20),

                      ),

                      child: Center(

                        child: Text(

                          'Book Now',

                          style: TextStyle(color: _isPopular ? AppColors.primary : Colors.white, fontWeight: FontWeight.w700, fontSize: 13.8),

                        ),

                      ),

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

}



// ─────────────────────────────────────────────

//  How It Works Section

// ─────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {

  static const List<_StepData> steps = [

    _StepData(step: '1', title: 'Choose package', description: 'Pick the right pack for your guest count and occasion.'),

    _StepData(step: '2', title: 'Customise', description: 'Set dietary preferences, cuisine style, and add-ons.'),

    _StepData(step: '3', title: 'Schedule', description: 'Pick delivery date and time — same-day available.'),

    _StepData(step: '4', title: 'We deliver', description: 'Fresh food arrives 4-5 hrs before your event starts.'),

  ];



  @override

  Widget build(BuildContext context) {

    return Container(

      decoration: const BoxDecoration(

        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFCC1212), Color(0xFF8B0000)]),

      ),

      padding: const EdgeInsets.fromLTRB(18, 30, 18, 36),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.8),

            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),

            child: const Text('Simple Process', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),

          ),

          const SizedBox(height: 14.4),

          const Text('How it works', style: TextStyle(color: Colors.white, fontSize: 25.3, fontWeight: FontWeight.w800)),

          const SizedBox(height: 5),

          const Text('From order to your table, in four simple steps.', style: TextStyle(color: Colors.white70, fontSize: 13.8)),

          const SizedBox(height: 40.2),

          // Step circles row

          Row(

            crossAxisAlignment: CrossAxisAlignment.center,

            children: [

              for (int i = 0; i < steps.length; i++) ...[

                _StepCircle(number: steps[i].step),

                if (i < steps.length - 1)

                  Expanded(

                    child: Container(

                      height: 2,

                      margin: const EdgeInsets.symmetric(horizontal: 4.8),

                      decoration: const BoxDecoration(

                        gradient: LinearGradient(colors: [Color(0x80FFFFFF), Color(0x30FFFFFF)]),

                      ),

                    ),

                  ),

              ],

            ],

          ),

          const SizedBox(height: 20.1),

          // Step labels row

          Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: steps.map((s) => Expanded(

              child: Padding(

                padding: const EdgeInsets.symmetric(horizontal: 2.4),

                child: Column(

                  children: [

                    Text(s.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.1)),

                    const SizedBox(height: 3.8),

                    Text(s.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 10.3, height: 1.4)),

                  ],

                ),

              ),

            )).toList(),

          ),

        ],

      ),

    );

  }

}



class _StepData {

  final String step, title, description;

  const _StepData({required this.step, required this.title, required this.description});

}



class _StepCircle extends StatelessWidget {

  final String number;

  const _StepCircle({required this.number});



  @override

  Widget build(BuildContext context) {

    return Container(

      width: 41.4,

      height: 41.4,

      decoration: BoxDecoration(

        color: Colors.white,

        shape: BoxShape.circle,

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],

      ),

      child: Center(child: Text(number, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16.1))),

    );

  }

}



// ─────────────────────────────────────────────

//  Testimonials Section

// ─────────────────────────────────────────────

class _TestimonialsSection extends StatelessWidget {

  static const List<_ReviewData> reviews = [

    _ReviewData(

      name: 'Priya M.', role: 'Birthday Celebrant', initials: 'PM', avatarColor: Color(0xFFE91E63),

      review: '"Ordered the Birthday Pack for 22 people — food arrived on time, everything was fresh. Guests loved it."',

    ),

    _ReviewData(

      name: 'Rohan K.', role: 'Corporate Lunch', initials: 'RK', avatarColor: Color(0xFF1565C0),

      review: '"The Office Lunch Pack was perfect for our team of 18. Clean packaging, great quantity."',

    ),

  ];



  @override

  Widget build(BuildContext context) {

    return Container(

      color: const Color(0xFFFDF3EE),

      padding: const EdgeInsets.fromLTRB(18, 30, 18, 30),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.8),

            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),

            child: const Text('Customer Stories', style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),

          ),

          const SizedBox(height: 11.5),

          const Text('What our customers say', style: TextStyle(color: AppColors.textDark, fontSize: 24.1, fontWeight: FontWeight.w800)),

          const SizedBox(height: 5),

          Text('500+ events and counting — here\'s how a few of them went.', style: const TextStyle(color: AppColors.textGrey, fontSize: 13.2, height: 1.4)),

          const SizedBox(height: 28.7),

          ...reviews.map((r) => Padding(padding: const EdgeInsets.only(bottom: 16.8), child: _ReviewCard(data: r))),

        ],

      ),

    );

  }

}



class _ReviewData {

  final String name, role, initials, review;

  final Color avatarColor;

  const _ReviewData({required this.name, required this.role, required this.initials, required this.review, required this.avatarColor});

}



class _ReviewCard extends StatelessWidget {

  final _ReviewData data;

  const _ReviewCard({required this.data});



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(19.2),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(children: List.generate(5, (_) => const Icon(Icons.star, color: AppColors.gold, size: 16.1))),

          const SizedBox(height: 11.5),

          Text(data.review, style: const TextStyle(color: AppColors.textDark, fontSize: 13.8, height: 1.5, fontStyle: FontStyle.italic)),

          const SizedBox(height: 17.2),

          Row(

            children: [

              CircleAvatar(radius: 18, backgroundColor: data.avatarColor, child: Text(data.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.6))),

              const SizedBox(width: 14.4),

              Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(data.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13.8)),

                  Text(data.role, style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5)),

                ],

              ),

            ],

          ),

        ],

      ),

    );

  }

}



// ─────────────────────────────────────────────

//  CTA Section

// ─────────────────────────────────────────────

class _CtaSection extends StatelessWidget {

  final VoidCallback? onOrderNow;

  const _CtaSection({this.onOrderNow});



  @override

  Widget build(BuildContext context) {

    return Container(

      decoration: const BoxDecoration(

 gradient: LinearGradient(

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [            // mauve pink

            Color(0xFFFF6766), // soft peach

            Color(0xFFF8F4E9), // cream white

          ],

        ),      ),

      padding: const EdgeInsets.symmetric(horizontal: 28.8, vertical: 48),

      child: Column(

        children: [

          const Text('Ready to plan your next event?', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDark, fontSize: 25.3, fontWeight: FontWeight.w800, height: 1.2)),

          const SizedBox(height: 14.4),

          const Text('Pick a package and get your catering confirmed in under 2 minutes.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 14.4, height: 1.5)),

          const SizedBox(height: 31.6),

          GestureDetector(

            onTap: onOrderNow,

            child: Container(

              padding: const EdgeInsets.symmetric(horizontal: 38.4, vertical: 16.8),

              decoration: BoxDecoration(

                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.centerLeft, end: Alignment.centerRight),

                borderRadius: BorderRadius.circular(28),

                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.40), blurRadius: 16, offset: const Offset(0, 6))],

              ),

              child: const Row(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16.1)),

                  SizedBox(width: 8.6),

                  Icon(Icons.arrow_forward, color: Colors.white, size: 18.4),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

}



// ─────────────────────────────────────────────

//  Footer

// ─────────────────────────────────────────────

class _Footer extends StatelessWidget {

  @override

  Widget build(BuildContext context) {

    return Container(

      color: AppColors.statsBar,

      padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),

      child: Column(

        children: [

          RichText(

            text: const TextSpan(

              children: [

                TextSpan(text: 'Swad', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20.7, color: Colors.white)),

                TextSpan(text: 'ishtt', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20.7, color: AppColors.primary)),

              ],

            ),

          ),

          const SizedBox(height: 5),

          const Text('Instant Catering · A part of Accesso Living', style: TextStyle(color: Colors.white54, fontSize: 11.5)),

          const SizedBox(height: 23),

          Wrap(

            alignment: WrapAlignment.center,

            spacing: 20,

            children: const [

              Text('Packages', style: TextStyle(color: Colors.white60, fontSize: 13.2, fontWeight: FontWeight.w500)),

              Text('How it works', style: TextStyle(color: Colors.white60, fontSize: 13.2, fontWeight: FontWeight.w500)),

              Text('Stories', style: TextStyle(color: Colors.white60, fontSize: 13.2, fontWeight: FontWeight.w500)),

              Text('Contact', style: TextStyle(color: Colors.white60, fontSize: 13.2, fontWeight: FontWeight.w500)),

            ],

          ),

          const SizedBox(height: 23),

          const Divider(color: Colors.white12),

          const SizedBox(height: 14.4),

          const Text('© 2026 Swadishtt · Instant Catering · A part of Accesso Living', style: TextStyle(color: Colors.white30, fontSize: 10.3), textAlign: TextAlign.center),

        ],

      ),

    );

  }

}//                                                                                           

//  Package Booking Bottom Sheet

//                                                                                           

class _PackageBookingSheet extends StatefulWidget {

  final _PackageInfo info;

  const _PackageBookingSheet({required this.info});



  @override

  State<_PackageBookingSheet> createState() => _PackageBookingSheetState();

}



class _PackageBookingSheetState extends State<_PackageBookingSheet> {
  String _selectedDiet = 'Mixed (Veg & Non-Veg)';
  final List<String> _diets = ['Pure Veg', 'Mixed (Veg & Non-Veg)', 'Jain'];
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);

  final TextEditingController _addressController = TextEditingController(text: '12th Cross, HSR Layout, Bengaluru');
  final TextEditingController _phoneController = TextEditingController(text: '9876543210');
  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double _parsePrice(String priceStr) {
    final clean = priceStr.replaceAll('₹', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 2999.0;
  }

  Future<void> _handleRazorpayPayment() async {
    if (_isProcessing) return;

    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter delivery address and phone number.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final amount = _parsePrice(widget.info.price);
    final description = '${widget.info.name} (${widget.info.serves})';

    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'customer@accescoliving.com';
    final userName = user?.displayName ?? 'Valued Customer';

    try {
      final paymentResult = await RazorpayService.openPayment(
        amount: amount,
        description: description,
        name: userName,
        email: userEmail,
        contact: phone,
      );

      if (paymentResult.success) {
        final uid = user?.uid ?? 'guest_user';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final orderId = paymentResult.orderId ?? 'CAT_$timestamp';
        final paymentId = paymentResult.paymentId ?? 'pay_$timestamp';

        final dateFormatted = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
        final timeFormatted = _selectedTime.format(context);

        final Map<String, dynamic> cateringOrder = {
          'id': orderId,
          'orderNumber': 'CAT-$timestamp',
          'userId': uid,
          'service': 'Swadishtt Instant Catering',
          'restaurantName': 'Swadishtt Instant Catering',
          'restaurantImage': widget.info.imageAsset,
          'packageName': widget.info.name,
          'serves': widget.info.serves,
          'cuisine': _selectedDiet,
          'deliveryDate': dateFormatted,
          'deliveryTime': timeFormatted,
          'address': address,
          'contactPhone': phone,
          'total': amount,
          'totalPaid': amount,
          'subtotal': amount,
          'price': amount,
          'status': 'Confirmed',
          'paymentMethod': 'Razorpay',
          'transactionId': paymentId,
          'razorpayOrderId': orderId,
          'createdAt': FieldValue.serverTimestamp(),
          'items': [
            {
              'name': '${widget.info.name} Package',
              'quantity': 1,
              'price': amount,
              'cuisine': _selectedDiet,
              'serves': widget.info.serves,
              'deliveryDate': dateFormatted,
              'deliveryTime': timeFormatted,
            }
          ],
        };

        // Save order to top-level orders and users/{uid}/swadishtt_orders
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

        // Create normalized order in memory via FirebaseService
        await FirebaseService.createOrder(
          restaurantName: 'Swadishtt Instant Catering',
          restaurantImage: widget.info.imageAsset,
          totalAmount: amount,
          items: (cateringOrder['items'] as List).cast<Map<String, dynamic>>(),
          paymentMethod: 'Razorpay',
          razorpayOrderId: orderId,
          transactionId: paymentId,
        );

        if (!mounted) return;

        Navigator.pop(context); // Close sheet

        // Show Success Dialog
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
                  'Your booking for ${widget.info.name} has been placed successfully.',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text('• Scheduled: $dateFormatted at $timeFormatted'),
                Text('• Cuisine: $_selectedDiet'),
                Text('• Amount Paid: ₹${amount.toInt()}'),
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
              content: Text(paymentResult.message ?? 'Payment failed or cancelled.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing catering payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing order: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.info.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.info.serves}   ${widget.info.price}',
                        style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 24, color: Color(0xFFEEEEEE), thickness: 1),
            
            // Customise Package
            const Text('Customise Cuisine', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _diets.map((diet) {
                final isSelected = _selectedDiet == diet;
                return ChoiceChip(
                  label: Text(diet),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textGrey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDiet = diet);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Schedule Delivery
            const Text('Schedule Delivery', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.textGrey),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppColors.textGrey),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Address & Phone
            const Text('Delivery Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Number',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Razorpay Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleRazorpayPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pay via Razorpay (${widget.info.price})',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

