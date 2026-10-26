import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final isInCart = cart.isInCart(product.id);
    final categoryText = (product.category.isNotEmpty ? product.category : 'FRESH PRODUCE').toUpperCase();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E8236), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Image container with rounded corners
          Flexible(
            fit: FlexFit.loose,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEBECEB),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFEBECEB),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF168A35),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            product.emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          product.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Category tag
          Text(
            categoryText,
            style: const TextStyle(
              color: Color(0xFF1B4D2E),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Product title
          Text(
            product.name,
            style: const TextStyle(
              color: Color(0xFF2C2825),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // Star rating
          const Row(
            children: [
              Icon(
                Icons.star_outline_rounded,
                size: 14,
                color: Color(0xFF1E8236),
              ),
              SizedBox(width: 3),
              Text(
                '4.7',
                style: TextStyle(
                  color: Color(0xFF2C2825),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Bottom Price & Action Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF2C2825),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '500 gm',
                      style: TextStyle(
                        color: Color(0xFF807C77),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  cart.addItem(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF168A35),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isInCart ? const Color(0xFF1B4D2E) : const Color(0xFF168A35),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Icon(
                    isInCart ? Icons.check_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


