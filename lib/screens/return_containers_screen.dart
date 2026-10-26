import 'package:flutter/material.dart';
import 'item_details_screen.dart';

class ReturnContainer {
  final String id;
  final String name;
  final String type;
  final double pricePerPiece;
  int quantity;
  bool isSelected;

  ReturnContainer({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerPiece,
    this.quantity = 1,
    this.isSelected = false,
  });
}

class ReturnContainersScreen extends StatefulWidget {
  const ReturnContainersScreen({super.key});

  @override
  State<ReturnContainersScreen> createState() => _ReturnContainersScreenState();
}

class _ReturnContainersScreenState extends State<ReturnContainersScreen> {
  static const Color _kPrimaryRed = Color(0xFFC00A27);
  static const Color _kLightBg = Color(0xFFFFF7F5);

  List<ReturnContainer> containers = [
    ReturnContainer(id: '1', name: 'Tiffin Container', type: 'Reusable • PET', pricePerPiece: 5, quantity: 1, isSelected: false),
    ReturnContainer(id: '2', name: 'Dal Container', type: 'Reusable • PET', pricePerPiece: 10, quantity: 1, isSelected: false),
    ReturnContainer(id: '3', name: 'Water Bottle', type: 'Reusable • PET', pricePerPiece: 3),
    ReturnContainer(id: '4', name: 'Tiffin Container', type: 'Reusable • PET', pricePerPiece: 6),
    ReturnContainer(id: '5', name: 'Container', type: 'Reusable • PET', pricePerPiece: 8),
    ReturnContainer(id: '6', name: 'Container', type: 'Reusable • PET', pricePerPiece: 9),
  ];

  int get _selectedItemsCount {
    int count = 0;
    for (var c in containers) {
      if (c.isSelected) count += c.quantity;
    }
    return count;
  }

  double get _totalDiscount {
    double total = 0;
    for (var c in containers) {
      if (c.isSelected) {
        total += (c.pricePerPiece * c.quantity);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Items to return',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHowItWorks(),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Containers that you wanted to return',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  _buildContainersList(),
                ],
              ),
            ),
          ),
          _buildBottomStickyBar(),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kLightBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How it works ?!',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'We Sanitize and reuse good containers And in return you earn some discount for this order',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Container(
              height: 70,
              alignment: Alignment.center,
              child: Image.asset('assets/Swadishtt/how.png', height: 60, width: 60, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainersList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: containers.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
        itemBuilder: (context, index) {
          final item = containers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: item.isSelected,
                    activeColor: _kPrimaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        item.isSelected = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Image.asset('assets/Swadishtt/container.png', height: 60, width: 60, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),

                // Name and Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                // Quantity and Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (item.isSelected) {
                                    if (item.quantity > 1) {
                                      setState(() => item.quantity--);
                                    } else {
                                      setState(() {
                                        item.isSelected = false;
                                        item.quantity = 1; // Reset for next selection
                                      });
                                    }
                                  }
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: const Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                                ),
                              ),
                              Container(width: 1, color: Colors.grey.shade300),
                              Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '${item.isSelected ? item.quantity : 0}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                              Container(width: 1, color: Colors.grey.shade300),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (!item.isSelected) {
                                      item.isSelected = true;
                                      item.quantity = 1;
                                    } else {
                                      item.quantity++;
                                    }
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: const Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${item.pricePerPiece.toInt()}/Piece',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+₹${(item.pricePerPiece * (item.isSelected ? item.quantity : 0)).toInt()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E8449),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomStickyBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kLightBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedItemsCount} Items Selected',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                Text(
                  '+₹${_totalDiscount.toInt()}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedItemsCount == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one item to return')),
                  );
                  return;
                }
                final double? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailsScreen(
                      item: containers.firstWhere((c) => c.isSelected && c.quantity > 0),
                      allContainers: containers,
                    ),
                  ),
                );
                if (result != null) {
                  Navigator.pop(context, result);
                } else {
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add to return',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
