import 'package:flutter/material.dart';
import '../models/products_data.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/dish_details_popup.dart';
import 'swadisht_food_detail_screen.dart';
class CategoryProductsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryProductsScreen({Key? key, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get all products that match the selected category
    final products = (categoryName == 'Trending' || categoryName == 'Trending Near You')
        ? ProductsData.trendingProducts
        : ProductsData.getAllProducts()
            .where((p) => p.category.toLowerCase() == categoryName.toLowerCase())
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: products.isEmpty
          ? const Center(child: Text("No products found in this category."))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                // Mock rating based on ID to look like the design
                final rating = 4.0 + (product.id % 9) / 10;
                
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SwadishtFoodDetailScreen(product: product),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade100,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Image
                        (product.imageUrl != null && product.imageUrl!.startsWith('http'))
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  product.emoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                        
                        // Dark Gradient at the bottom
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.9),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Top-left Rating Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.star, color: Colors.orange, size: 10),
                              ],
                            ),
                          ),
                        ),
                        
                        // Bottom Content
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              
                              // Categories / Description
                              Text(
                                product.category.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Location
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 10),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      "Bangalore",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              
                              // Time and Price
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "30-35 mins",
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 9,
                                    ),
                                  ),
                                  Text(
                                    "₹${product.price.toInt()} for two",
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 9,
                                    ),
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
    );
  }
}
