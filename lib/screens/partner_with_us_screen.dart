import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PartnerWithUsScreen extends StatefulWidget {
  const PartnerWithUsScreen({super.key});

  @override
  State<PartnerWithUsScreen> createState() => _PartnerWithUsScreenState();
}

class _PartnerWithUsScreenState extends State<PartnerWithUsScreen> {

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _briefController = TextEditingController();

  int _briefCharCount = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _briefController.addListener(_onBriefChanged);
  }

  void _onBriefChanged() {
    if (mounted) {
      setState(() {
        _briefCharCount = _briefController.text.length;
      });
    }
  }

  @override
  void dispose() {
    _briefController.removeListener(_onBriefChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _briefController.dispose();
    super.dispose();
  }
  static const Color primaryDark = Color(0xFF1E2638);
  static const Color primaryMaroon = Color(0xFF860038);
  static const Color fieldBgColor = Color(0xFFFCF7F8);
  static const Color fieldBorderColor = Color(0xFFF3D8E2);
  static const Color subtextColor = Color(0xFF757D8A);

  final List<String> collaborationOptions = [
    'Instagram / Socials',
    'YouTube Integration',
    'UGC Creation',
    'Ambassadorship',
    'Barter / Exchange',
  ];

  final Set<String> selectedCollaborations = {'Instagram / Socials'};
  String? selectedBudget;

  final List<String> budgetRanges = [
    '₹10,000 - ₹50,000',
    '₹50,000 - ₹1,00,000',
    '₹1,00,000 - ₹5,00,000',
    '₹5,00,000+',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Partner with us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  fontFamily: 'sans-serif',
                ),
                children: [
                  TextSpan(
                    text: "Let's build\nsomething great\n",
                    style: TextStyle(color: primaryDark),
                  ),
                  TextSpan(
                    text: "together.",
                    style: TextStyle(color: primaryMaroon),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Fill in your details below and our team will get back to you to explore collaboration opportunities.',
              style: TextStyle(fontSize: 14, color: subtextColor, height: 1.4),
            ),
            const SizedBox(height: 24),

            // First Name & Last Name
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('First Name'),
                      _buildTextField(hint: 'First Name', controller: _firstNameController),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Last Name'),
                      _buildTextField(hint: 'Last Name', controller: _lastNameController),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Work Email
            _buildLabel('Work Email'),
            _buildTextField(
              hint: 'you@company.com',
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            const SizedBox(height: 20),

            // Company / Brand Name
            _buildLabel('Company / Brand Name'),
            _buildTextField(hint: 'Company / Brand Name', controller: _companyController),
            const SizedBox(height: 20),

            // Nature of Collaboration
            _buildLabel('Nature of Collaboration'),
            Wrap(
              spacing: 8.0,
              runSpacing: 10.0,
              children: collaborationOptions.map((tag) {
                final isSelected = selectedCollaborations.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedCollaborations.remove(tag);
                      } else {
                        selectedCollaborations.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFBEBF1)
                          : fieldBgColor,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: isSelected ? primaryMaroon : fieldBorderColor,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? primaryMaroon : primaryDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Estimated Budget
            _buildLabel('Estimated Budget (INR)'),
            DropdownButtonFormField<String>(
              value: selectedBudget,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black87,
              ),
              hint: const Text(
                'Select Budget Range',
                style: TextStyle(color: Color(0xFFB4B0B3), fontSize: 14),
              ),
              decoration: _inputDecoration(),
              items: budgetRanges.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedBudget = newValue;
                });
              },
            ),
            const SizedBox(height: 20),

            // Campaign Brief
            _buildLabel('Campaign Brief'),
            _buildTextField(
              hint: 'Tell us about your brand and collaboration ideas...',
              maxLines: 4,
              maxLength: 300,
              controller: _briefController,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_briefCharCount/300',
                style: const TextStyle(fontSize: 12, color: subtextColor),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryMaroon,
                  disabledBackgroundColor: primaryMaroon.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26.0),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Submit request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 36),

            // Divider Line
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 20),

            // Stats Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('150+', 'Brand Partners'),
                _buildStatItem('48hr', 'Response Time'),
                _buildStatItem('3 Cities', 'Live & Expanding'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  void _submitForm() async {
    if (_isSubmitting) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final company = _companyController.text.trim();
    final message = _briefController.text.trim();

    if (firstName.isEmpty) {
      _showErrorSnackBar('Please enter your First Name.');
      return;
    }

    if (lastName.isEmpty) {
      _showErrorSnackBar('Please enter your Last Name.');
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showErrorSnackBar('Please enter a valid Work Email address.');
      return;
    }

    if (company.isEmpty) {
      _showErrorSnackBar('Please enter your Company / Brand Name.');
      return;
    }

    if (selectedCollaborations.isEmpty) {
      _showErrorSnackBar('Please select at least one Nature of Collaboration.');
      return;
    }

    if (selectedBudget == null || selectedBudget!.isEmpty) {
      _showErrorSnackBar('Please select an Estimated Budget Range.');
      return;
    }

    if (message.isEmpty) {
      _showErrorSnackBar('Please enter a Campaign Brief.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final applicationData = {
        'userId': uid ?? 'anonymous',
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'email': email,
        'company': company,
        'natureOfCollaboration': selectedCollaborations.toList(),
        'estimatedBudget': selectedBudget,
        'campaignBrief': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('vendor_applications').add(applicationData);

      if (!mounted) return;

      // Clear input fields
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _companyController.clear();
      _briefController.clear();
      setState(() {
        selectedCollaborations.clear();
        selectedCollaborations.add('Instagram / Socials');
        selectedBudget = null;
        _briefCharCount = 0;
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Request Submitted'),
            ],
          ),
          content: const Text(
            'Your partnership request has been submitted for review. Our team will get back to you within 48 hours!',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('OK', style: TextStyle(color: primaryMaroon, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error submitting partner request: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to submit request. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primaryDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB4B0B3), fontSize: 14),
      filled: true,
      fillColor: fieldBgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fieldBorderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryMaroon, width: 1.2),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint: hint).copyWith(
        counterText: '', // Hide built-in counter
      ),
    );
  }

  Widget _buildStatItem(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryMaroon,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: subtextColor),
        ),
      ],
    );
  }
}
