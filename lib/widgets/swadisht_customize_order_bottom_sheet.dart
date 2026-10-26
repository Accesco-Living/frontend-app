import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';

class SwadishtAddOnItem {
  final String title;
  final double price;
  bool isSelected;

  SwadishtAddOnItem({
    required this.title,
    required this.price,
    this.isSelected = false,
  });
}

class SwadishtCustomizeOrderBottomSheet extends StatefulWidget {
  final String itemName;
  final double basePrice;
  final String? itemImage;
  final String? initialInstructions;
  final List<String>? initialAddOns;
  final int? existingProductId;

  const SwadishtCustomizeOrderBottomSheet({
    super.key,
    required this.itemName,
    required this.basePrice,
    this.itemImage,
    this.initialInstructions,
    this.initialAddOns,
    this.existingProductId,
  });

  static Future<void> show(
    BuildContext context, {
    required String itemName,
    required double basePrice,
    String? itemImage,
    String? initialInstructions,
    List<String>? initialAddOns,
    int? existingProductId,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SwadishtCustomizeOrderBottomSheet(
        itemName: itemName,
        basePrice: basePrice,
        itemImage: itemImage,
        initialInstructions: initialInstructions,
        initialAddOns: initialAddOns,
        existingProductId: existingProductId,
      ),
    );
  }

  @override
  State<SwadishtCustomizeOrderBottomSheet> createState() =>
      _SwadishtCustomizeOrderBottomSheetState();
}

class _SwadishtCustomizeOrderBottomSheetState
    extends State<SwadishtCustomizeOrderBottomSheet> {
  late final TextEditingController _instructionsController;
  late List<SwadishtAddOnItem> _addOns;
  bool _isSaving = false;

  static const Color _kRedAccent = Color(0xFFE53935);
  static const Color _kSelectedCardBg = Color(0xFFFFF0F2);

  @override
  void initState() {
    super.initState();
    _instructionsController =
        TextEditingController(text: widget.initialInstructions ?? '');

    final lowerName = widget.itemName.toLowerCase();
    if (lowerName.contains('burger')) {
      _addOns = [
        SwadishtAddOnItem(title: 'Extra Cheese Slice', price: 25.0, isSelected: true),
        SwadishtAddOnItem(title: 'Crispy French Fries (Small)', price: 50.0, isSelected: false),
        SwadishtAddOnItem(title: 'Extra Burger Patty', price: 60.0, isSelected: false),
        SwadishtAddOnItem(title: 'Coke (250ml)', price: 30.0, isSelected: false),
      ];
    } else {
      // Pizza Add-ons matching design reference
      _addOns = [
        SwadishtAddOnItem(title: 'Extra Cheese', price: 40.0, isSelected: true),
        SwadishtAddOnItem(title: 'Garlic Bread (2 pcs)', price: 60.0, isSelected: false),
        SwadishtAddOnItem(title: 'Chili Flakes', price: 10.0, isSelected: false),
        SwadishtAddOnItem(title: 'Extra Dip / Chutney', price: 20.0, isSelected: false),
      ];
    }

    // Pre-select add-ons if provided
    if (widget.initialAddOns != null && widget.initialAddOns!.isNotEmpty) {
      for (final addOn in _addOns) {
        addOn.isSelected = widget.initialAddOns!.any(
          (initName) => initName.toLowerCase().contains(addOn.title.toLowerCase()),
        );
      }
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  double get _addOnsTotal {
    return _addOns
        .where((item) => item.isSelected)
        .fold(0.0, (sum, item) => sum + item.price);
  }

  double get _totalToPay {
    return widget.basePrice + _addOnsTotal;
  }

  Future<void> _handleAddToCart() async {
    setState(() => _isSaving = true);

    final selectedAddOnsList = _addOns
        .where((a) => a.isSelected)
        .map((a) => '${a.title} (+₹${a.price.toInt()})')
        .toList();

    final selectedAddOnsRaw = _addOns
        .where((a) => a.isSelected)
        .map((a) => {'title': a.title, 'price': a.price})
        .toList();

    final instructions = _instructionsController.text.trim();

    // 1. Sync customization payload to Firebase Firestore
    await FirebaseService.saveCustomizedItem(
      itemName: widget.itemName,
      basePrice: widget.basePrice,
      addOns: selectedAddOnsRaw,
      specialInstructions: instructions,
      totalPrice: _totalToPay,
    );

    // 2. Add or Update in CartProvider
    if (mounted) {
      final customizedProduct = Product(
        id: widget.existingProductId ?? DateTime.now().millisecondsSinceEpoch,
        name: '${widget.itemName}${selectedAddOnsList.isNotEmpty ? " (Customized)" : ""}',
        description: instructions.isNotEmpty
            ? 'Instructions: $instructions'
            : 'Customized order',
        price: _totalToPay,
        category: 'Swadishtt',
        emoji: widget.itemName.toLowerCase().contains('burger') ? '🍔' : '🍕',
        imageUrl: widget.itemImage ?? 'assets/Swadishtt/burger.png',
        selectedAddOns: selectedAddOnsList,
        specialInstructions: instructions,
        basePrice: widget.basePrice,
      );

      final cart = Provider.of<CartProvider>(context, listen: false);
      if (widget.existingProductId != null) {
        cart.updateCustomizedProduct(widget.existingProductId!, customizedProduct);
      } else {
        cart.addItem(customizedProduct);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingProductId != null
                ? 'Updated customization for ${widget.itemName}!'
                : 'Customized ${widget.itemName} added to cart!',
          ),
          backgroundColor: _kRedAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Clean White Theme matching Swadishtt
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP DRAG HANDLE ──
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── HEADER WITH TITLE & CLOSE BUTTON ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Customize your order',
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF666666),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── ADD-ONS SECTION ──
              const Text(
                'ADD-ONS',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // ADD-ON CARDS LIST
              ..._addOns.map((item) => _buildAddOnCard(item)),

              const SizedBox(height: 24),

              // ── SPECIAL INSTRUCTIONS SECTION ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SPECIAL INSTRUCTIONS',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _instructionsController,
                    builder: (context, value, _) {
                      return Text(
                        '${value.text.length}/120',
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // SPECIAL INSTRUCTIONS TEXT FIELD
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _instructionsController,
                  maxLength: 120,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
                  decoration: const InputDecoration(
                    hintText:
                        'Add your special instructions (e.g., make it extra spicy, no onions, etc.)...',
                    hintStyle: TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── PRICE BREAKDOWN CARD ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Item Total',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${widget.basePrice.toInt()}',
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add-ons',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${_addOnsTotal.toInt()}',
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFEF9A9A), height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'To Pay',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '₹${_totalToPay.toInt()}',
                          style: const TextStyle(
                            color: _kRedAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── ACTION BUTTON ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRedAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.existingProductId != null
                                  ? 'Update Item • ₹${_totalToPay.toInt()}'
                                  : 'Add Item • ₹${_totalToPay.toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOnCard(SwadishtAddOnItem item) {
    final isSelected = item.isSelected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            item.isSelected = !item.isSelected;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? _kSelectedCardBg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _kRedAccent : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // CHECKBOX
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? _kRedAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? _kRedAccent : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // TITLE
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // PRICE
              Text(
                '+₹${item.price.toInt()}',
                style: TextStyle(
                  color: isSelected ? _kRedAccent : Colors.grey.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
