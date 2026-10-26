import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../services/location_service.dart';

class ProfileAddressScreen extends StatelessWidget {
  const ProfileAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the AddressProvider specifically for this screen
    return ChangeNotifierProvider(
      create: (_) => AddressProvider(),
      child: const _ProfileAddressScreenContent(),
    );
  }
}

class _ProfileAddressScreenContent extends StatefulWidget {
  const _ProfileAddressScreenContent();

  @override
  State<_ProfileAddressScreenContent> createState() => _ProfileAddressScreenContentState();
}

class _ProfileAddressScreenContentState extends State<_ProfileAddressScreenContent> {
  // Brand colors
  static const Color brandPrimary = Color(0xFF90103B);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGray = Color(0xFF64748B);
  static const Color lightPinkBg = Color(0xFFFCF2F6);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFF7C0043),
      Color(0xFF940050),
      Color(0xFFAB005C),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'parents':
      case 'family':
        return Icons.favorite;
      default:
        return Icons.location_on;
    }
  }

  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandPrimary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showAddAddressModal(BuildContext context) {
    final addressProvider = context.read<AddressProvider>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController pincodeController = TextEditingController();
    final TextEditingController stateController = TextEditingController();
    final TextEditingController cityController = TextEditingController();
    final TextEditingController houseController = TextEditingController();
    final TextEditingController areaController = TextEditingController();

    String selectedType = 'Home';
    bool setAsDefault = false;
    bool isFetchingGps = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, -4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 24,
                    bottom: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add New Address',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                          ),
                          InkWell(
                            onTap: isFetchingGps
                                ? null
                                : () async {
                                    setModalState(() => isFetchingGps = true);
                                    final loc = await LocationService.fetchCurrentLocation();
                                    setModalState(() => isFetchingGps = false);

                                    if (loc != null) {
                                      pincodeController.text = loc.pincode;
                                      stateController.text = loc.state;
                                      cityController.text = loc.city;
                                      houseController.text = loc.houseNo;
                                      areaController.text = loc.area;

                                      if (modalContext.mounted) {
                                        ScaffoldMessenger.of(modalContext).showSnackBar(
                                          SnackBar(
                                            content: Text('Location detected: ${loc.city}, ${loc.state}'),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } else if (modalContext.mounted) {
                                      ScaffoldMessenger.of(modalContext).showSnackBar(
                                        const SnackBar(
                                          content: Text('Could not fetch location. Please check GPS settings.'),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: lightPinkBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: brandPrimary.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  isFetchingGps
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: brandPrimary),
                                        )
                                      : const Icon(Icons.my_location, size: 14, color: brandPrimary),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Use Location',
                                    style: TextStyle(color: brandPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildSimpleTextField(
                        controller: nameController,
                        hint: 'Full Name (Required)',
                      ),
                      _buildSimpleTextField(
                        controller: phoneController,
                        hint: 'Phone Number (Required)',
                        keyboardType: TextInputType.phone,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSimpleTextField(
                              controller: pincodeController,
                              hint: 'Pincode',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSimpleTextField(
                              controller: stateController,
                              hint: 'State',
                            ),
                          ),
                        ],
                      ),
                      _buildSimpleTextField(
                        controller: cityController,
                        hint: 'City',
                      ),
                      _buildSimpleTextField(
                        controller: houseController,
                        hint: 'House No., Building Name (Required)',
                      ),
                      _buildSimpleTextField(
                        controller: areaController,
                        hint: 'Road name, Area, Colony (Required)',
                      ),
                      
                      const SizedBox(height: 8),
                      const Text('Save as:', style: TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ['Home', 'Work', 'Parents', 'Other'].map((type) {
                          bool isSelected = selectedType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            selectedColor: lightPinkBg,
                            backgroundColor: Colors.grey[100],
                            side: BorderSide(
                              color: isSelected ? brandPrimary.withOpacity(0.5) : Colors.transparent,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? brandPrimary : textGray,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedType = type;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Checkbox(
                            value: setAsDefault,
                            activeColor: brandPrimary,
                            onChanged: (val) {
                              setModalState(() {
                                setAsDefault = val ?? false;
                              });
                            },
                          ),
                          const Text('Set as default address', style: TextStyle(color: textDark)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (nameController.text.trim().isEmpty || 
                                phoneController.text.trim().isEmpty ||
                                houseController.text.trim().isEmpty ||
                                areaController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all required fields'),
                                  backgroundColor: brandPrimary,
                                ),
                              );
                              return;
                            }
                            
                            final buffer = StringBuffer();
                            buffer.writeln(nameController.text.trim());
                            buffer.writeln('Phone: ${phoneController.text.trim()}');
                            buffer.writeln('${houseController.text.trim()}, ${areaController.text.trim()}');
                            
                            final cityState = [cityController.text.trim(), stateController.text.trim()]
                                .where((e) => e.isNotEmpty).join(', ');
                            if (cityState.isNotEmpty) {
                              buffer.write(cityState);
                              if (pincodeController.text.trim().isNotEmpty) {
                                buffer.write(' - ${pincodeController.text.trim()}');
                              }
                            }
                            
                            addressProvider.addAddress(
                              selectedType,
                              buffer.toString().trim(),
                              setAsDefault: setAsDefault,
                            );
                            Navigator.pop(modalContext);
                          },
                          child: const Text('Save Address', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Addresses',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner - Flat Style
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF5F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3E1E8)),
                  ),
                  child: Stack(
                    children: [
                      // Map background on the right
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 150,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          child: Image.asset(
                            'assets/images/map.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Find your place\non the map',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: brandPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'See all your saved locations\nand serviceable areas.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textGray,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // View on Map Button (Gradient)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: brandGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'View on map',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.chevron_right, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Saved addresses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (addressProvider.isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: brandPrimary),
                  ))
                else if (addressProvider.addresses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No addresses saved yet.\nClick below to add one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textGray, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: addressProvider.addresses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final address = addressProvider.addresses[index];
                      return _buildAddressCard(
                        id: address.id,
                        title: address.type,
                        address: address.fullAddress,
                        icon: _getIconForType(address.type),
                        isDefault: address.isDefault,
                        provider: addressProvider,
                      );
                    },
                  ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          // Fixed Bottom Button (Gradient)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: InkWell(
              onTap: () => _showAddAddressModal(context),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: brandGradient,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: brandPrimary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: brandPrimary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Address',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required String id,
    required String title,
    required String address,
    required IconData icon,
    required bool isDefault,
    required AddressProvider provider,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDefault ? lightPinkBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? const Color(0xFFF3E1E8) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandPrimary, width: 1.2),
                ),
                child: Icon(icon, color: brandPrimary, size: 24),
              ),
              if (isDefault)
                Positioned(
                  top: -6,
                  left: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: brandPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Action Buttons Column
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  // More Options Button (Set as Default)
                  InkWell(
                    onTap: () {
                      if (!isDefault) provider.setDefaultAddress(id);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(Icons.more_horiz, color: isDefault ? textGray : textDark, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete Button
                  InkWell(
                    onTap: () => provider.deleteAddress(id),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                    ),
                  ),
                ],
              ),
              if (isDefault) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: brandPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
