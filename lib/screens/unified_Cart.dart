import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:accesco_living_app/providers/unified_cart_provider.dart';
import 'package:accesco_living_app/models/products_data.dart';
import 'package:accesco_living_app/models/product.dart';
import 'package:accesco_living_app/screens/grokly_screen.dart';
import 'package:accesco_living_app/services/api_service.dart';
import 'package:accesco_living_app/screens/swadisht_food_detail_screen.dart';
import 'package:accesco_living_app/screens/return_and_earn_screen.dart';
import '../services/firebase_service.dart';
import '../services/razorpay_service.dart';
import 'checkout_screen.dart';
import '../widgets/custom_bottom_nav.dart';

class UnifiedCartScreen extends StatefulWidget {
  const UnifiedCartScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedCartScreen> createState() => _UnifiedCartScreenState();
}

class _UnifiedCartScreenState extends State<UnifiedCartScreen> {
  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------
  static const Color _brand = Color(0xFF8B0054);
  static const Color _bg = Color(0xFFFCF5F7);
  static const Color _card = Colors.white;

  // ---------------------------------------------------------------------------
  // Fixed charges (would come from the cart API in production).
  // ---------------------------------------------------------------------------
  int get _handlingCharge => _itemCount == 0 ? 0 : 12;
  int get _platformFee => _itemCount == 0 ? 0 : 8;
  static const int _originalDeliveryCharge = 78;
  static const int _giftPackagingCharge = 29;
  static const int _freeDeliveryThreshold = 499;
  static const int _bundleSavings = 90;

  // ---------------------------------------------------------------------------
  // Mutable state — one cart per UnifiedVendor, plus which tab is open.
  // ---------------------------------------------------------------------------
  // The _vendors list is now managed globally.
  List<UnifiedVendor> get _vendors => UnifiedCartState.instance.vendors;

  int _activeVendorIndex = 0;

  bool _giftPackaging = true;

  static const List<int> _tipPresets = [15, 25, 40];
  int _tipAmount = 0;
  bool _tipCustom = false;

  static const List<int> _roundUpPresets = [5, 10, 20];
  int _roundUpAmount = 0;
  bool _roundUpCustom = false;

  int _selectedInstruction = 1; // "Leave at door"
  final TextEditingController _gstinController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Derived values (single source of truth for the bill) — all vendors combined.
  // ---------------------------------------------------------------------------
  int get _itemsTotal => _vendors.fold(0, (sum, v) => sum + v.subtotal);

  int get _itemCount => _vendors.fold(0, (sum, v) => sum + v.unitCount);

  int get _serviceCount =>
      _vendors.where((v) => v.items.isNotEmpty).length;

  bool get _freeDelivery => _itemsTotal >= _freeDeliveryThreshold;

  int get _giftCharge => (_itemCount == 0 || !_giftPackaging) ? 0 : _giftPackagingCharge;
  
  int get _deliveryCharge => _itemCount == 0 ? 0 : (_freeDelivery ? 0 : _originalDeliveryCharge);

  int get _grandTotal => _itemCount == 0 
      ? 0 
      : (_itemsTotal +
         _handlingCharge +
         _platformFee +
         _deliveryCharge +
         _tipAmount +
         _roundUpAmount +
         _giftCharge);

  double get _deliveryProgress =>
      (_itemsTotal / _freeDeliveryThreshold).clamp(0.0, 1.0);

  late final List<CrossSellProduct> _crossSell = _generateCrossSell();

  List<CrossSellProduct> _generateCrossSell() {
    final List<CrossSellProduct> items = [];
    final random = math.Random();

    // 4 random items from Grokly
    final List<GroklyProduct> groceries = List.from(GroklyCatalog.all)..shuffle(random);
    for (var p in groceries.take(4)) {
      items.add(CrossSellProduct(p.id, p.name, p.price.toInt(), p.imageUrl, 'Grokly', p));
    }

    // 4 random items from Swadishtt
    final List<Product> foods = List.from(ProductsData.activeFoodProducts)..shuffle(random);
    for (var p in foods.take(4)) {
      items.add(CrossSellProduct(p.id.toString(), p.name, p.price.toInt(), p.imageUrl ?? '', 'Swadishtt', p));
    }



    items.shuffle(random);
    return items;
  }

  static const List<_Instruction> _instructions = [
    _Instruction(Icons.mic, 'Hold to record'),
    _Instruction(Icons.door_front_door, 'Leave at door'),
    _Instruction(Icons.person, 'Leave with guard'),
    _Instruction(Icons.notifications_off, "Don't ring bell"),
  ];

  @override
  void dispose() {
    _gstinController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Currency: Indian digit grouping (e.g. 1620 -> ₹1,620, 1234567 -> ₹12,34,567)
  // ---------------------------------------------------------------------------
  String _inr(num value) {
    final bool neg = value < 0;
    final String s = value.abs().round().toString();
    if (s.length <= 3) return '${neg ? '-' : ''}₹$s';
    final String last3 = s.substring(s.length - 3);
    String rest = s.substring(0, s.length - 3);
    final List<String> parts = [];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${neg ? '-' : ''}₹${parts.join(',')},$last3';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UnifiedCartState.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: _buildAppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFreeDeliveryBanner(),
                  _buildAppTabs(),
                  _buildActiveVendorCart(),
                  _buildCrossSell(),
                  _buildGiveBackSection(),
                  _buildDeliveryInstructions(),
                  _buildGSTINSection(),
                  _buildGiveBackEarnBack(),
                  _buildBillDetails(),
                  _buildCancellationPolicy(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomCheckoutBar(),
              const CustomBottomNav(currentIndex: 1),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Colors.black87),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.send, size: 16, color: _brand),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Delivering to Home',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black87),
            ],
          ),
          Text(
            'Yelahanka, Bengaluru',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _brand,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _inr(_grandTotal),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        )
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Free delivery banner
  // ---------------------------------------------------------------------------
  Widget _buildFreeDeliveryBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _brand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Free delivery unlocked at ${_inr(_freeDeliveryThreshold)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _deliveryProgress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "You're at ${_inr(_itemsTotal)}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (_freeDelivery)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('🎉', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'Free delivery unlocked!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UnifiedVendor tabs — tap to switch which cart is shown. Each badge reflects that
  // UnifiedVendor's live item count.
  // ---------------------------------------------------------------------------
  Widget _buildAppTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < _vendors.length; i++) ...[
            _buildTabChip(i),
            if (i != _vendors.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildTabChip(int index) {
    final UnifiedVendor vendor = _vendors[index];
    final bool active = _activeVendorIndex == index;
    final Color brand = vendor.brandColor;
    return Material(
      color: active ? brand.withOpacity(0.08) : _card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _activeVendorIndex = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? brand.withOpacity(0.45) : Colors.grey[300]!,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(vendor.icon,
                  size: 16, color: active ? brand : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                vendor.name,
                style: TextStyle(
                  color: active ? brand : Colors.black87,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: brand,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  vendor.items.length.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active UnifiedVendor's cart (header + items), themed by that UnifiedVendor's colour.
  // ---------------------------------------------------------------------------
  Widget _buildActiveVendorCart() {
    final UnifiedVendor vendor = _vendors[_activeVendorIndex];
    final Color brand = vendor.brandColor;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  color: brand.withOpacity(0.12),
                  child: Icon(vendor.icon, color: brand),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      vendor.deliveryLine,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed:
                    vendor.items.isEmpty ? null : () => _removeAll(vendor),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Remove all',
                    style: TextStyle(
                        color: brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap:
                    vendor.items.isEmpty ? null : () => _removeAll(vendor),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete,
                      size: 18, color: Colors.black54),
                ),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          if (vendor.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No items in this cart',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            for (int i = 0; i < vendor.items.length; i++) ...[
              _buildItemRow(vendor.items[i], brand, vendor.name),
              if (i != vendor.items.length - 1) const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }

  Widget _buildItemRow(UnifiedCartItem item, Color brand, String vendorName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _thumbnail(item, size: 70, radius: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _inr(item.unitPrice),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: brand),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStepper(item, brand, vendorName),
            const SizedBox(height: 10),
            Text(
              _inr(item.lineTotal),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStepper(UnifiedCartItem item, Color brand, String vendorName) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: brand.withOpacity(0.30)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: brand.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.remove,
                size: 16,
                color: item.qty > 1 ? brand : brand.withOpacity(0.35)),
            onPressed: item.qty > 1
                ? () => UnifiedCartState.instance
                    .updateQuantity(vendorName, item.id, -1)
                : null,
          ),
          Text(item.qty.toString(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          IconButton(
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.add, size: 16, color: brand),
            onPressed: () => UnifiedCartState.instance
                .updateQuantity(vendorName, item.id, 1),
          ),
        ],
      ),
    );
  }

  void _removeAll(UnifiedVendor vendor) {
    UnifiedCartState.instance.clearVendor(vendor.name);
  }

  // ---------------------------------------------------------------------------
  // Cross-sell
  // ---------------------------------------------------------------------------
  Widget _buildCrossSell() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('You might also like',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Complete the cart',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 172,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _crossSell.length,
            itemBuilder: (_, i) => _buildCrossSellItem(_crossSell[i]),
          ),
        )
      ],
    );
  }

  Widget _buildCrossSellItem(CrossSellProduct product) {
    const double imageHeight = 95;
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () {
              if (product.originalItem == null) return;
              
              if (product.vendorName == 'Grokly') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroklyScreen()));
              } else if (product.vendorName == 'Swadishtt') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SwadishtFoodDetailScreen(product: product.originalItem)));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: imageHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrl.isEmpty
                        ? const Center(
                            child: Icon(Icons.image, color: Colors.black26))
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _inr(product.price),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _brand),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // "Add" button — last child in the Stack, so it paints on TOP and
          // stays fully visible while straddling the image/text divider.
          Positioned(
            top: imageHeight - 15,
            right: 8,
            child: Material(
              color: _brand,
              elevation: 2,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  UnifiedCartState.instance.addItem(
                    vendorName: product.vendorName,
                    id: product.id,
                    name: product.title,
                    subtitle: 'Cross-sell item',
                    unitPrice: product.price,
                    imageUrl: product.imageUrl,
                  );
                },
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Give back
  // ---------------------------------------------------------------------------
  Widget _buildGiveBackSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Give back with this order',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('optional',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildDonationRow(
                  title: 'Round up for Annapurna Meals',
                  desc:
                      'Your contribution funds a mid-day meal for a child through our NGO partner, when this amount reaches the kitchen.',
                  presets: _roundUpPresets,
                  amount: _roundUpAmount,
                  isCustom: _roundUpCustom,
                  badgeText: '1 MEAL',
                  onPreset: (v) => setState(() {
                    if (_roundUpAmount == v && !_roundUpCustom) {
                      _roundUpAmount = 0;
                    } else {
                      _roundUpAmount = v;
                      _roundUpCustom = false;
                    }
                  }),
                  onCustom: () => _pickCustomAmount(
                    title: 'Round-up amount',
                    current: _roundUpAmount,
                    apply: (v) => setState(() {
                      _roundUpAmount = v;
                      _roundUpCustom = true;
                    }),
                  ),
                ),
                const Divider(height: 1),
                _buildDonationRow(
                  title: 'Tip your delivery partners',
                  desc:
                      'Split across all three riders on this order. 100% of your tip goes directly to them.',
                  presets: _tipPresets,
                  amount: _tipAmount,
                  isCustom: _tipCustom,
                  onPreset: (v) => setState(() {
                    if (_tipAmount == v && !_tipCustom) {
                      _tipAmount = 0;
                    } else {
                      _tipAmount = v;
                      _tipCustom = false;
                    }
                  }),
                  onCustom: () => _pickCustomAmount(
                    title: 'Tip amount',
                    current: _tipAmount,
                    apply: (v) => setState(() {
                      _tipAmount = v;
                      _tipCustom = true;
                    }),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gift packaging',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            SizedBox(height: 4),
                            Text(
                                'Wrap items in kraft paper with a handwritten note. ₹29',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: _giftPackaging,
                        onChanged: (val) =>
                            setState(() => _giftPackaging = val),
                        activeColor: Colors.green,
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                InkWell(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text('Ordering for someone else?',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(width: 8),
                            Text('Add details ›',
                                style: TextStyle(
                                    color: _brand,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                            'Add their name and number so our delivery partner can reach them directly.',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDonationRow({
    required String title,
    required String desc,
    required List<int> presets,
    required int amount,
    required bool isCustom,
    required ValueChanged<int> onPreset,
    required VoidCallback onCustom,
    String? badgeText,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              if (badgeText != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _brand,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(badgeText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
            ],
          ),
          const SizedBox(height: 4),
          Text(desc,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final p in presets)
                _buildChoiceChip(
                  label: _inr(p),
                  selected: !isCustom && amount == p,
                  onTap: () => onPreset(p),
                ),
              _buildChoiceChip(
                label: isCustom ? '${_inr(amount)} ✎' : 'Custom',
                selected: isCustom,
                onTap: onCustom,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _brand : _card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(
                color: selected ? _brand : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomAmount({
    required String title,
    required int current,
    required ValueChanged<int> apply,
  }) async {
    final controller =
        TextEditingController(text: current > 0 ? current.toString() : '');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '₹ ',
            hintText: 'Enter amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (result != null && result >= 0) apply(result);
  }

  // ---------------------------------------------------------------------------
  // Delivery instructions
  // ---------------------------------------------------------------------------
  Widget _buildDeliveryInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery instructions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('for all $_serviceCount orders',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _instructions.length,
            itemBuilder: (_, i) => _buildInstructionCard(i),
          ),
        )
      ],
    );
  }

  Widget _buildInstructionCard(int index) {
    final instruction = _instructions[index];
    final bool isSelected = _selectedInstruction == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedInstruction = index),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? _bg : _card,
          border: Border.all(
              color: isSelected ? _brand : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(instruction.icon,
                color: isSelected ? _brand : Colors.grey[600], size: 24),
            const SizedBox(height: 8),
            Text(
              instruction.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? _brand : Colors.black87,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GSTIN
  // ---------------------------------------------------------------------------
  Widget _buildGSTINSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add GSTIN',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Claim input tax credit of up to 18% on the Grokly items in this order.',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gstinController,
                        textCapitalization:
                            TextCapitalization.characters,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          hintText: '22AAAAA0000A1Z5',
                          hintStyle:
                              const TextStyle(color: Colors.black26),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _brand),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _applyGstin,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                            color: _brand,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Apply',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _applyGstin() {
    FocusScope.of(context).unfocus();
    final value = _gstinController.text.trim();
    final valid = value.length == 15;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(valid
            ? 'GSTIN applied'
            : 'Enter a valid 15-character GSTIN'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Give back, earn back
  // ---------------------------------------------------------------------------
  Widget _buildGiveBackEarnBack() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Give back, earn back',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReturnAndEarnScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _brand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.recycling,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Return packaging, earn wallet credits',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      SizedBox(height: 4),
                      Text(
                          "Hand empty bottles, boxes & packets back to your rider. We'll verify & credit your wallet.",
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('Earn up to ${_inr(15)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bill details
  // ---------------------------------------------------------------------------
  Widget _buildBillDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bill details',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$_itemCount items · $_serviceCount services',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildBillRow('Items total', _inr(_itemsTotal)),
                const SizedBox(height: 12),
                _buildBillRow(
                  'Delivery charge',
                  _itemCount == 0 ? _inr(0) : (_freeDelivery ? 'FREE' : _inr(_deliveryCharge)),
                  valueColor: (_freeDelivery && _itemCount > 0) ? Colors.green : null,
                  strikethrough:
                      (_freeDelivery && _itemCount > 0) ? _inr(_originalDeliveryCharge) : null,
                ),
                const SizedBox(height: 12),
                _buildBillRow('Handling charge', _inr(_handlingCharge)),
                const SizedBox(height: 12),
                _buildBillRow('Platform fee', _inr(_platformFee)),
                if (_tipAmount > 0 && _itemCount > 0) ...[
                  const SizedBox(height: 12),
                  _buildBillRow(
                      'Delivery partner tip', _inr(_tipAmount)),
                ],
                if (_roundUpAmount > 0 && _itemCount > 0) ...[
                  const SizedBox(height: 12),
                  _buildBillRow('Round up for Annapurna Meals',
                      _inr(_roundUpAmount)),
                ],
                if (_giftPackaging && _itemCount > 0) ...[
                  const SizedBox(height: 12),
                  _buildBillRow(
                      'Gift packaging', _inr(_giftCharge)),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand total',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_inr(_grandTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _brand)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.check,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You're saving ${_inr(_bundleSavings)} by checking out together, incl. free delivery",
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value,
      {Color? valueColor, String? strikethrough}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.black54, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (strikethrough != null) ...[
              Text(
                strikethrough,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: valueColor ?? Colors.black87)),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Cancellation policy
  // ---------------------------------------------------------------------------
  Widget _buildCancellationPolicy() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Cancellation policy',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: TextStyle(
                    color: Colors.black54, fontSize: 12, height: 1.4),
                children: [
                  TextSpan(text: 'Once placed, cancelling '),
                  TextSpan(
                      text: 'Swadishtt',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold)),
                  TextSpan(
                      text:
                          ' items may attract a fee as preparation begins immediately. '),
                  TextSpan(
                      text: 'Grokly',
                      style: TextStyle(
                          color: _brand,
                          fontWeight: FontWeight.bold)),
                  TextSpan(
                      text:
                          " items can be cancelled free of charge until they're picked for delivery. Full refunds apply for delays on our end."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom checkout bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomCheckoutBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _card,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: InkWell(
            onTap: () async {
              if (_grandTotal <= 0) return;

              // 1. Razorpay payment process
              final paymentResult = await RazorpayService.openPayment(
                amount: _grandTotal.toDouble(),
                description: 'ACCESCO Living Unified Checkout',
              );

              if (paymentResult.success) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saving order to VPS...')),
                );

                // 2. Firebase ko HATA kar apna naya VPS API lagaya
                bool success = await ApiService.checkoutCart(_grandTotal);

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Order Placed Successfully via VPS!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CheckoutScreen(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ VPS Checkout failed, check console.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                // Ye wo else block hai jo tumhara pehle se tha (Payment failed ke liye)
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment cancelled or failed.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: _brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Proceed to Checkout',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_inr(_grandTotal),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 16),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------
  Widget _thumbnail(UnifiedCartItem item,
      {double size = 70, double radius = 12}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: Colors.grey[100],
        child: item.imageUrl != null
            ? Image.network(item.imageUrl!, fit: BoxFit.cover)
            : Icon(item.icon ?? Icons.fastfood,
                color: Colors.grey, size: size * 0.45),
      ),
    );
  }
}

// =============================================================================
// Models
// =============================================================================


class CrossSellProduct {
  final String id;
  final String title;
  final int price;
  final String imageUrl;
  final String vendorName;
  final dynamic originalItem;

  const CrossSellProduct(
    this.id,
    this.title,
    this.price,
    this.imageUrl,
    this.vendorName,
    this.originalItem,
  );
}

class _Instruction {
  final IconData icon;
  final String label;
  const _Instruction(this.icon, this.label);
}
