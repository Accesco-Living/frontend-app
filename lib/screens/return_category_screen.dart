import 'package:flutter/material.dart';

class ReturnCategoryScreen extends StatefulWidget {
  const ReturnCategoryScreen({super.key});

  @override
  State<ReturnCategoryScreen> createState() => _ReturnCategoryScreenState();
}

class _ReturnCategoryScreenState extends State<ReturnCategoryScreen> {
  static const Color _kPrimaryRed = Color(0xFFC00A27);
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Plastic Containers', 'icon': Icons.takeout_dining},
    {'name': 'Glass Jars', 'icon': Icons.liquor},
    {'name': 'Paper Bags', 'icon': Icons.shopping_bag_outlined},
    {'name': 'Cutlery', 'icon': Icons.restaurant},
    {'name': 'Bottles', 'icon': Icons.local_drink},
    {'name': 'Other Packaging', 'icon': Icons.inventory_2_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Category',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What are you returning ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a category to see available items',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedIndex == index;
                  final category = _categories[index];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF7F5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _kPrimaryRed : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'],
                            size: 48,
                            color: isSelected ? _kPrimaryRed : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            category['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? _kPrimaryRed : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
