import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'return_containers_screen.dart';
import 'return_containers_review_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final ReturnContainer item;
  final List<ReturnContainer> allContainers;

  const ItemDetailsScreen({super.key, required this.item, required this.allContainers});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  static const Color _kPrimaryRed = Color(0xFFC00A27);
  String _selectedCondition = 'Like New';
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _conditions = [
    {'title': 'Like New', 'icon': Icons.favorite},
    {'title': 'Good', 'icon': Icons.thumb_up_alt_outlined},
    {'title': 'Used', 'icon': Icons.analytics_outlined},
    {'title': 'Damaged', 'icon': Icons.broken_image_outlined},
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
      }
    }
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Upload Photo',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _kPrimaryRed),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _kPrimaryRed),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder, color: _kPrimaryRed),
                title: const Text('Files'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery); // Fallback to gallery picker which usually handles local files
                },
              ),
            ],
          ),
        );
      },
    );
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
          'Item Details',
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Subtitle
                  Center(
                    child: Column(
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.type.replaceAll('•', '·'),
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Image and Return Value
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Placeholder Image
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset('assets/Swadishtt/container.png', height: 60, width: 60, fit: BoxFit.contain),
                      ),
                      
                      // Return Value Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAFCE0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Return Value',
                              style: TextStyle(color: Color(0xFF1E8449), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '₹${widget.item.pricePerPiece.toInt()}/Piece',
                              style: const TextStyle(color: Color(0xFF1E8449), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Condition Section
                  const Text(
                    'Condition of the item',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _conditions.map((condition) {
                      final isSelected = _selectedCondition == condition['title'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCondition = condition['title'];
                          });
                        },
                        child: Container(
                          width: 75,
                          height: 85,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF5F6) : Colors.white,
                            border: Border.all(
                              color: isSelected ? _kPrimaryRed : Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                condition['icon'],
                                color: isSelected ? _kPrimaryRed : Colors.grey.shade700,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                condition['title'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? _kPrimaryRed : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  
                  // Upload Image Section
                  RichText(
                    text: const TextSpan(
                      text: 'Upload Image ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      children: [
                        TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a clear image of the item',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  
                  // Upload Box
                  InkWell(
                    onTap: () => _showUploadOptions(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: _pickedImage != null ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _kPrimaryRed, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _pickedImage!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              children: [
                                Icon(Icons.file_download_outlined, color: _kPrimaryRed, size: 24),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to upload photo',
                                  style: TextStyle(color: _kPrimaryRed, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'JPG , PNG upto 5MB',
                                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title Field
                  RichText(
                    text: TextSpan(
                      text: 'Enter Title ',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      children: [
                        TextSpan(text: '(Optional)', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _kPrimaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Description Field
                  RichText(
                    text: TextSpan(
                      text: 'Add Description ',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      children: [
                        TextSpan(text: '(Optional)', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _kPrimaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
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
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReturnContainersReviewScreen(selectedContainers: widget.allContainers),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See Return Value',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
