import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../models/address.dart';
import 'checkout_screen.dart';

class CheckoutDeliveryAddressScreen extends StatefulWidget {
  final bool isFromCart;
  const CheckoutDeliveryAddressScreen({super.key, this.isFromCart = false});

  @override
  State<CheckoutDeliveryAddressScreen> createState() => _CheckoutDeliveryAddressScreenState();
}

class _CheckoutDeliveryAddressScreenState extends State<CheckoutDeliveryAddressScreen> {
  // Brand colors from the screenshot
  static const Color brandPink = Color(0xFFDE0A52); // The deep pink used in buttons and borders
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color bgPink = Color(0xFFFFF2F6); // Very light pink for selected card bg
  static const Color bgCream = Color(0xFFFAFAFA); // Background

  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    // Fetch addresses on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().fetchAddresses();
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.location_on_outlined; // From screenshot, Home has a pin
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  void _showAddAddressForm(BuildContext context) {
    final addressProvider = context.read<AddressProvider>();
    
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController houseController = TextEditingController();
    final TextEditingController areaController = TextEditingController();
    final TextEditingController landmarkController = TextEditingController();

    String selectedType = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(modalContext).size.height * 0.85,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enter complete address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: textDark),
                        onPressed: () => Navigator.pop(modalContext),
                      )
                    ],
                  ),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contact Details
                          const Text('Receiver Details', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 12),
                          _buildTextField(nameController, 'Receiver\'s Name', Icons.person_outline),
                          const SizedBox(height: 12),
                          _buildTextField(phoneController, 'Receiver\'s Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                          
                          const SizedBox(height: 24),
                          
                          // Address Details
                          const Text('Address Details', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 12),
                          _buildTextField(houseController, 'Flat / House No / Floor / Building', Icons.home_outlined),
                          const SizedBox(height: 12),
                          _buildTextField(areaController, 'Area / Sector / Locality', Icons.map_outlined),
                          const SizedBox(height: 12),
                          _buildTextField(landmarkController, 'Nearby Landmark (Optional)', Icons.flag_outlined),
                          
                          const SizedBox(height: 24),
                          
                          // Save As
                          const Text('Save As', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: ['Home', 'Work', 'Other'].map((type) {
                              final isSelected = selectedType == type;
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedType = type),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? brandPink.withOpacity(0.1) : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? brandPink : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      color: isSelected ? brandPink : textGray,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (houseController.text.trim().isEmpty || areaController.text.trim().isEmpty || nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                           ScaffoldMessenger.of(modalContext).showSnackBar(const SnackBar(content: Text('Please fill all mandatory fields')));
                           return;
                        }
                        
                        String fullAddr = '${houseController.text.trim()}, ${areaController.text.trim()}';
                        if (landmarkController.text.trim().isNotEmpty) {
                          fullAddr += ', Landmark: ${landmarkController.text.trim()}';
                        }
                        fullAddr += '\n${nameController.text.trim()} - ${phoneController.text.trim()}';

                        await addressProvider.addAddress(
                          selectedType,
                          fullAddr,
                          setAsDefault: addressProvider.addresses.isEmpty,
                        );
                        if (modalContext.mounted) {
                          Navigator.pop(modalContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandPink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Address',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: textGray),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandPink),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AddressProvider>(
        builder: (context, addressProvider, child) {
          var addresses = addressProvider.addresses;
          if (addresses.isEmpty) {
            addresses = [
              AddressModel(
                id: 'dummy-1',
                type: 'Home',
                fullAddress: 'A-24, Second Floor, Tower 3, Prestige Shantiniketan, Whitefield, Landmark: Near Forum Mall\nJohn Doe - 9876543210',
                isDefault: true,
              )
            ];
          }
          
          // Auto-select the default address if none is selected
          if (_selectedAddressId == null && addresses.isNotEmpty) {
            try {
              final defaultAddr = addresses.firstWhere((a) => a.isDefault);
              _selectedAddressId = defaultAddr.id;
            } catch (_) {
              _selectedAddressId = addresses.first.id;
            }
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header "2 Delivery Address"
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: brandPink,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Address List
                      if (addressProvider.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: brandPink),
                          ),
                        )
                      else if (addresses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              'No saved addresses found.\nPlease add one below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: addresses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            final isSelected = _selectedAddressId == address.id;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAddressId = address.id;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? bgPink : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? brandPink : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getIconForType(address.type),
                                          color: isSelected ? brandPink : textDark,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          address.type,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textDark,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (address.isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: brandPink.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'DEFAULT',
                                              style: TextStyle(
                                                color: brandPink,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      address.fullAddress,
                                      style: TextStyle(
                                        color: isSelected ? textDark : textGray,
                                        height: 1.5,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () {
                                            // Handle edit if needed
                                          },
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit, size: 14, color: textDark),
                                              SizedBox(width: 4),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: textDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      
                      // Add New Address Button
                      GestureDetector(
                        onTap: () => _showAddAddressForm(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: brandPink, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add New Address',
                                style: TextStyle(
                                  color: brandPink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40), // Spacing for scroll
                    ],
                  ),
                ),
              ),

              // Bottom Continue Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedAddressId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select an address')),
                          );
                          return;
                        }
                        
                        if (widget.isFromCart) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandPink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
