import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  static const Color primaryText = Color(0xFF171923);
  static const Color secondaryText = Color(0xFF69707D);
  static const Color accentColor = Color(0xFF8B0045); // Deep magenta
  static const Color bgColor = Color(0xFFFDF7F9);
  static const Color cardBorder = Color(0xFFE4C9D5);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);

  TextStyle _montserrat({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = primaryText,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Addresses',
          style: _montserrat(size: 18, weight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: primaryText),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR PLACES',
                          style: _montserrat(
                            size: 10,
                            weight: FontWeight.w800,
                            color: accentColor,
                          ).copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Delivering\nto what matters.',
                          style: _montserrat(size: 28, weight: FontWeight.w800).copyWith(height: 1.1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Manage your addresses for seamless delivery, shopping and return pickups.',
                          style: _montserrat(size: 14, color: secondaryText).copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Image.asset(
                      'assets/images/delivery.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shopping_basket, color: accentColor, size: 40),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Saved addresses header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved addresses',
                    style: _montserrat(size: 16, weight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      Text(
                        'View on map',
                        style: _montserrat(size: 13, weight: FontWeight.w700, color: accentColor),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.map_outlined, color: accentColor, size: 16),
                      const Icon(Icons.chevron_right, color: accentColor, size: 18),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Consumer<AddressProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (provider.addresses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'No saved addresses found.\nAdd a new address to continue.',
                          textAlign: TextAlign.center,
                          style: _montserrat(size: 14, color: secondaryText),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: provider.addresses.map((address) {
                      final isHome = address.type.toLowerCase() == 'home';
                      final icon = isHome ? Icons.home : (address.type.toLowerCase() == 'work' ? Icons.work_outline : Icons.location_on);
                      final iconColor = isHome ? const Color(0xFF2E7D32) : accentColor;
                      final iconBg = isHome ? const Color(0xFFC8E6C9) : const Color(0xFFFDF0F5);
                      final cardBg = address.isDefault ? const Color(0xFFF4FBF5) : Colors.white;
                      final cardBorderColor = address.isDefault ? const Color(0xFFD4E6D6) : cardBorder;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cardBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: !isHome ? Border.all(color: cardBorder) : null,
                                    ),
                                    child: Icon(icon, color: iconColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              address.type,
                                              style: _montserrat(size: 16, weight: FontWeight.w700),
                                            ),
                                            if (address.isDefault) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFC8E6C9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Default',
                                                  style: _montserrat(size: 11, weight: FontWeight.w600, color: const Color(0xFF2E7D32)),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address.fullAddress,
                                          style: _montserrat(size: 13, color: secondaryText).copyWith(height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.more_vert, color: primaryText),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _actionPill(Icons.edit, 'Edit', true),
                                  const SizedBox(width: 8),
                                  _actionPill(Icons.near_me_outlined, 'Get directions', false),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Add New Address Button
              InkWell(
                onTap: () => _showAddAddressBottomSheet(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Address',
                              style: _montserrat(size: 16, weight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add a new address for faster checkouts and reverse pickups',
                              style: _montserrat(size: 11, color: const Color(0xFFE4C9D5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.add, color: Colors.white, size: 32),
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

  Widget _actionPill(IconData icon, String label, bool filled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFC8E6C9) : Colors.transparent,
        border: Border.all(color: const Color(0xFFA5D6A7)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text(
            label,
            style: _montserrat(size: 12, weight: FontWeight.w600, color: const Color(0xFF2E7D32)),
          ),
        ],
      ),
    );
  }

  void _showAddAddressBottomSheet(BuildContext context) {
    final flatController = TextEditingController();
    final areaController = TextEditingController();
    final landmarkController = TextEditingController();
    bool showError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String selectedType = 'Home';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add New Address', style: _montserrat(size: 20, weight: FontWeight.w800)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Flat / House no. / Building',
                      controller: flatController,
                      errorText: showError && flatController.text.trim().isEmpty ? 'This field is required' : null,
                      onChanged: (val) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Area / Sector / Locality',
                      controller: areaController,
                      errorText: showError && areaController.text.trim().isEmpty ? 'This field is required' : null,
                      onChanged: (val) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Landmark (Optional)',
                      controller: landmarkController,
                      onChanged: (val) => setModalState(() {}),
                    ),
                    const SizedBox(height: 24),
                    Text('Save as', style: _montserrat(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildAddressTypeChip('Home', selectedType, (type) => setModalState(() => selectedType = type)),
                        const SizedBox(width: 12),
                        _buildAddressTypeChip('Work', selectedType, (type) => setModalState(() => selectedType = type)),
                        const SizedBox(width: 12),
                        _buildAddressTypeChip('Other', selectedType, (type) => setModalState(() => selectedType = type)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (flatController.text.trim().isEmpty || areaController.text.trim().isEmpty) {
                            setModalState(() {
                              showError = true;
                            });
                            return;
                          }
                          
                          final fullAddress = '${flatController.text.trim()}, ${areaController.text.trim()}${landmarkController.text.trim().isNotEmpty ? ', ${landmarkController.text.trim()}' : ''}';

                          await Provider.of<AddressProvider>(context, listen: false)
                              .addAddress(selectedType, fullAddress, setAsDefault: false);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Address saved successfully!')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Save Address', style: _montserrat(size: 16, weight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _montserrat(size: 12, color: Colors.black54),
        errorText: errorText,
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
          borderSide: const BorderSide(color: accentColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildAddressTypeChip(String type, String selectedType, Function(String) onSelect) {
    final isSelected = type == selectedType;
    return GestureDetector(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1A8B0045) : Colors.transparent, // accentColor with 10% opacity
          border: Border.all(color: isSelected ? accentColor : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          type,
          style: _montserrat(
            size: 13,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? accentColor : Colors.black87,
          ),
        ),
      ),
    );
  }
}


