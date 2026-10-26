import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../providers/bookmark_provider.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';

class SwadishtFoodDetailScreen extends StatefulWidget {
  final Product product;

  const SwadishtFoodDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<SwadishtFoodDetailScreen> createState() =>
      _SwadishtFoodDetailScreenState();
}

class _SwadishtFoodDetailScreenState extends State<SwadishtFoodDetailScreen> {
  
  bool _isSaving = false;
  int _quantity = 1;

  static const Color _kMaroon = Color(0xFFE30B2C); // Red color from the image
  static const Color _kLightPink = Color(0xFFFFF0F2);
  static const Color _kTextGrey = Color(0xFF6B6B6B);

  final currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  Future<void> _handleOrderNow() async {
    setState(() => _isSaving = true);

    const instructions = 'Standard Serving';

    // Save to firebase
    await FirebaseService.saveCustomizedItem(
      itemName: widget.product.name,
      basePrice: widget.product.price * _quantity,
      addOns: [],
      specialInstructions: instructions,
      totalPrice: widget.product.price * _quantity,
    );

    if (mounted) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      for (int i = 0; i < _quantity; i++) {
        cart.addItem(widget.product);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} added to cart!'),
          backgroundColor: _kMaroon,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Hero Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: _buildHeroImage(),
          ),

          // Back, Favorite, Share Buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleIconButton(
                    Icons.arrow_back, () => Navigator.pop(context)),
                Row(
                  children: [
                    Consumer<BookmarkProvider>(
                      builder: (context, provider, _) {
                        final isFav = provider.isSwadishttSaved(widget.product.id);
                        return _buildCircleIconButton(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          () => provider.toggleSwadishttProduct(widget.product),
                          iconColor: isFav ? Colors.red : Colors.black,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildCircleIconButton(
                      Icons.share_outlined,
                      () {
                        Share.share(
                          'Check out ${widget.product.name} on Swadishtt! ${widget.product.description.isNotEmpty ? widget.product.description : "Delicious food delivered fast!"} for only ${currencyFormat.format(widget.product.price)}.',
                          subject: 'Share ${widget.product.name}',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Content
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: _buildBodyContent(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStickyBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    final url =
        (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty)
            ? widget.product.imageUrl!
            : '';

    if (url.startsWith('http')) {
      return Image.network(url,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder());
    } else if (url.isNotEmpty) {
      return Image.asset(url,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder());
    } else {
      return _imagePlaceholder();
    }
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Text(widget.product.emoji, style: const TextStyle(fontSize: 80)),
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, VoidCallback onTap,
      {Color iconColor = Colors.black}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  Widget _buildBodyContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                currencyFormat.format(widget.product.price),
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: _kMaroon),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Serves
          Row(
            children: [
              const Icon(Icons.restaurant, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Serves 1–2',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),

          // Taste & Dietary Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: _kLightPink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('🌶️', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 6),
                          Text('Taste',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Medium Spice',
                              style: TextStyle(
                                  color: _kMaroon,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          SizedBox(width: 4),
                          Text('🌶️ 🌶️ 🌶️', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('🌿', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 6),
                          Text('Dietary',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Pure Veg',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            widget.product.description.isEmpty
                ? 'A creamy spinach gravy with soft paneer cubes, finished with aromatic spices for a rich and comforting taste.'
                : widget.product.description,
            style: const TextStyle(
                fontSize: 14,
                color: _kTextGrey,
                height: 1.5,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          _buildDottedDivider(),
          const SizedBox(height: 24),

          // List Items
          _buildListItem(Icons.restaurant_menu, 'Serving Size', '1–2 People'),
          const SizedBox(height: 24),
          _buildListItem(Icons.menu_book, 'Story',
              '"A classic Indian favourite made with fresh spinach and soft paneer".'),
          const SizedBox(height: 24),
          _buildListItem(Icons.settings, 'Customise', 'Spice Level • Add-ons'),
          const SizedBox(height: 24),
          _buildListItem(Icons.star, 'Reviews', '4.8 ⭐⭐⭐⭐⭐ (128 reviews)'),

          const SizedBox(height: 24),
          _buildDottedDivider(),
          const SizedBox(height: 24),

          // Quantity row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quantity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _kMaroon),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Text('-',
                            style: TextStyle(
                                color: _kMaroon,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Text('$_quantity',
                        style: const TextStyle(
                            color: _kMaroon,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () {
                        setState(() => _quantity++);
                      },
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Text('+',
                            style: TextStyle(
                                color: _kMaroon,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
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

  Widget _buildListItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: _kLightPink,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kMaroon, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 14,
                      color: _kTextGrey,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDottedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFFFC2C2))),
            );
          }),
        );
      },
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Container(
          height: 70,
          color: _kLightPink,
          child: Row(
            children: [
              // Left Total section
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black87)),
                      Text(
                        currencyFormat.format(widget.product.price * _quantity),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              // Right Custom Buttons
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: _isSaving
                      ? Container(
                          color: _kMaroon,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Material(
                                color: _kMaroon,
                                child: InkWell(
                                  onTap: _isSaving ? null : _handleOrderNow,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart_outlined,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text('ADD TO CART',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              letterSpacing: 0.5)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 4,
                              color: Colors.white,
                            ),
                            Expanded(
                              child: Material(
                                color: _kMaroon,
                                child: InkWell(
                                  onTap: () {
                                    // Separate action for cook this for me
                                  },
                                  child: const Center(
                                    child: Text('Cook This For Me',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12)),
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
        ),
      ),
    );
  }
}
