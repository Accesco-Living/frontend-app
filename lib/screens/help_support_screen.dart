import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'my_orders.dart';
import 'redeem_code_screen.dart';
import 'partner_with_us_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  static const Color primaryText = Color(0xFF171923);
  static const Color secondaryText = Color(0xFF69707D);
  static const Color accentColor = Color(0xFF8B0045); // Deep magenta
  static const Color bgColor = Color(0xFFFDF7F9); // Light pinkish white
  static const Color cardColor = Colors.white;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoadingFaqs = true;

  final List<Map<String, dynamic>> _defaultFaqs = [
    {
      'id': 'faq_1',
      'category': 'General',
      'question': 'How long does it take to get a response?',
      'answer':
          'Our customer support team usually responds within 2–4 hours during operating hours (Mon-Sat, 9 AM – 6 PM IST). Urgent order issues receive priority response within 30 minutes.',
    },
    {
      'id': 'faq_2',
      'category': 'My Orders',
      'question': 'I have an issue with my order.',
      'answer':
          'To report an order issue, go to "My Orders" > Select your active order > Tap "Need Help" or "Report Issue". You can request an item replacement, refund, or delivery check directly.',
    },
    {
      'id': 'faq_3',
      'category': 'General',
      'question': 'I want to become a delivery partner, vendor or merchant.',
      'answer':
          'We welcome new business and delivery partners! Navigate to Profile > "Partner with us" and submit your business details. Our onboarding team will contact you within 48 hours.',
    },
    {
      'id': 'faq_4',
      'category': 'General',
      'question': 'Where is Accesco Living based?',
      'answer':
          'Accesco Living is headquartered in Bengaluru, Karnataka, India, operating across major metropolitan hubs to provide quick-commerce and living services.',
    },
    {
      'id': 'faq_5',
      'category': 'Payments & Refunds',
      'question': 'How do refunds work and when will I get my money back?',
      'answer':
          'Refunds for cancelled or returned orders are credited back to your original payment method or Accesco Wallet within 24–48 hours after verification.',
    },
    {
      'id': 'faq_6',
      'category': 'Delivery & Tracking',
      'question': 'How can I track my live order delivery?',
      'answer':
          'Open "My Orders" and select your ongoing order to view real-time delivery status, rider location, and estimated arrival time.',
    },
    {
      'id': 'faq_7',
      'category': 'Account & Login',
      'question': 'How do I update my profile details or mobile number?',
      'answer':
          'Go to Profile > "Account Settings" to edit your name, email, delivery addresses, or security preferences.',
    },
    {
      'id': 'faq_8',
      'category': 'Offers & Rewards',
      'question': 'How do I apply coupon codes or gift card rewards?',
      'answer':
          'Go to Profile > "Gift Cards & Coupons" or enter your 12-digit code or coupon code at checkout to claim instant discounts.',
    },
  ];

  List<Map<String, dynamic>> _faqs = [];

  TextStyle _montserrat({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = HelpSupportScreen.primaryText,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
    _fetchFaqs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFaqs() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('help_faqs').get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _faqs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          _isLoadingFaqs = false;
        });
      } else {
        setState(() {
          _faqs = List.from(_defaultFaqs);
          _isLoadingFaqs = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      setState(() {
        _faqs = List.from(_defaultFaqs);
        _isLoadingFaqs = false;
      });
    }
  }

  Future<void> _launchUrlString(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    return _faqs.where((faq) {
      final category = (faq['category'] ?? '').toString();
      final question = (faq['question'] ?? '').toString().toLowerCase();
      final answer = (faq['answer'] ?? '').toString().toLowerCase();

      final matchesCategory = _selectedCategory == 'All' ||
          category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          question.contains(_searchQuery) ||
          answer.contains(_searchQuery) ||
          category.toLowerCase().contains(_searchQuery);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _showFaqDetail(Map<String, dynamic> faq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF0F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                faq['category'] ?? 'General',
                style: _montserrat(
                  size: 11,
                  weight: FontWeight.w700,
                  color: HelpSupportScreen.accentColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              faq['question'] ?? '',
              style: _montserrat(
                size: 16,
                weight: FontWeight.w800,
                color: HelpSupportScreen.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              faq['answer'] ?? '',
              style: _montserrat(
                size: 13,
                color: const Color(0xFF4A4A4A),
              ).copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Was this answer helpful?',
              style: _montserrat(
                size: 12,
                weight: FontWeight.w600,
                color: HelpSupportScreen.secondaryText,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your feedback!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                  label: const Text('Yes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HelpSupportScreen.accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showContactSupportSheet();
                  },
                  icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
                  label: const Text('No, Contact Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: _montserrat(
                size: 13,
                weight: FontWeight.w700,
                color: HelpSupportScreen.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSupportSheet() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    String category = 'General Inquiry';
    bool isSubmitting = false;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      nameController.text = currentUser.displayName ?? '';
      emailController.text = currentUser.email ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Send us a message',
                        style: _montserrat(size: 18, weight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: 'Issue Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      'General Inquiry',
                      'My Orders',
                      'Payments & Refunds',
                      'Delivery & Tracking',
                      'Account & Login',
                      'Returns & Cancellations',
                    ].map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'How can we help you?',
                      hintText: 'Describe your issue or query...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final email = emailController.text.trim();
                              final msg = messageController.text.trim();

                              if (name.isEmpty || email.isEmpty || msg.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill in all fields.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                await FirebaseFirestore.instance
                                    .collection('support_tickets')
                                    .add({
                                  'userId': uid ?? 'guest',
                                  'name': name,
                                  'email': email,
                                  'category': category,
                                  'message': msg,
                                  'status': 'open',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                if (!mounted) return;
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Support ticket submitted! We will respond shortly.'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HelpSupportScreen.accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Submit Ticket',
                              style: _montserrat(
                                size: 15,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleTopicTap(String title) {
    if (title.contains('Orders')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
      );
    } else if (title.contains('Offers') || title.contains('Rewards')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RedeemCodeScreen()),
      );
    } else {
      setState(() {
        if (_selectedCategory == title) {
          _selectedCategory = 'All';
        } else {
          _selectedCategory = title;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredFaqs;

    return Scaffold(
      backgroundColor: HelpSupportScreen.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HelpSupportScreen.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: _montserrat(size: 18, weight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: HelpSupportScreen.accentColor),
            onPressed: _showContactSupportSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Text(
                "WE'RE HERE FOR YOU",
                style: _montserrat(
                  size: 11,
                  weight: FontWeight.w700,
                  color: HelpSupportScreen.secondaryText,
                ).copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'How can we\nhelp you today?',
                style: _montserrat(
                  size: 32,
                  weight: FontWeight.w800,
                  color: HelpSupportScreen.accentColor,
                ).copyWith(height: 1.1),
              ),
              const SizedBox(height: 12),
              Text(
                'Find answers, get support, or\nreach out to our team.',
                style: _montserrat(
                  size: 14,
                  color: HelpSupportScreen.secondaryText,
                ).copyWith(height: 1.4),
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAEF),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: HelpSupportScreen.accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for help (e.g. order, refund, payment...)',
                          hintStyle: _montserrat(
                            size: 13,
                            color: HelpSupportScreen.secondaryText,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Popular topics
              _sectionHeader(
                'Popular topics',
                _selectedCategory == 'All' ? 'View all' : 'Clear filter',
                () {
                  setState(() {
                    _selectedCategory = 'All';
                    _searchController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
                children: [
                  _topicCard(Icons.inventory_2_outlined, 'My Orders',
                      'Track, modify or cancel',
                      isSelected: _selectedCategory == 'My Orders'),
                  _topicCard(Icons.payment_outlined, 'Payments &\nRefunds',
                      'Payments, refunds and offers',
                      isSelected: _selectedCategory == 'Payments & Refunds'),
                  _topicCard(Icons.local_shipping_outlined,
                      'Delivery &\nTracking', 'Delivery status, delays & more',
                      isSelected: _selectedCategory == 'Delivery & Tracking'),
                  _topicCard(Icons.person_outline, 'Account &\nLogin',
                      'Profile, security and settings',
                      isSelected: _selectedCategory == 'Account & Login'),
                  _topicCard(Icons.sync_outlined, 'Returns &\nCancellations',
                      'Hassle-free returns',
                      isSelected: _selectedCategory == 'Returns & Cancellations'),
                  _topicCard(Icons.card_giftcard_outlined, 'Offers &\nRewards',
                      'Codes, offers and benefits',
                      isSelected: _selectedCategory == 'Offers & Rewards'),
                ],
              ),
              const SizedBox(height: 32),

              // Common questions
              _sectionHeader('Common questions', 'View all', () {
                setState(() {
                  _selectedCategory = 'All';
                });
              }),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: HelpSupportScreen.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isLoadingFaqs
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: HelpSupportScreen.accentColor,
                          ),
                        ),
                      )
                    : filteredList.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'No matching questions found.\nTry a different search term or contact us.',
                                textAlign: TextAlign.center,
                                style: _montserrat(
                                  size: 13,
                                  color: HelpSupportScreen.secondaryText,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => _divider(),
                            itemBuilder: (context, index) {
                              final faq = filteredList[index];
                              return _questionTile(faq);
                            },
                          ),
              ),
              const SizedBox(height: 32),

              // Contact Us
              Text(
                'Contact Us',
                style: _montserrat(size: 18, weight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchUrlString(
                          'mailto:support@accescoliving.com?subject=Support%20Inquiry'),
                      child: _contactCard(
                        Icons.email_outlined,
                        'Email us',
                        'support@accescoliving.com',
                        'We usually respond within 24 hours.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchUrlString('tel:+918012345678'),
                      child: _contactCard(
                        Icons.call_outlined,
                        'Call us',
                        '+91 8012345678',
                        'Mon - Sat · 9 AM - 6 PM IST',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchUrlString(
                          'https://maps.google.com/?q=Accesco+Living+Bengaluru'),
                      child: _contactCard(
                        Icons.location_on_outlined,
                        'Our Office',
                        'Bengaluru, Karnataka, India',
                        'Visit us at our registered office.',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Send us a message CTA
              GestureDetector(
                onTap: _showContactSupportSheet,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF0F5),
                    border: Border.all(color: const Color(0xFFF3E1E8)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: HelpSupportScreen.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send us a message',
                              style: _montserrat(size: 16, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Share your query and we'll get back to you soon.",
                              style: _montserrat(
                                size: 12,
                                color: HelpSupportScreen.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: HelpSupportScreen.accentColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: _montserrat(size: 18, weight: FontWeight.w700),
        ),
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              Text(
                action,
                style: _montserrat(
                  size: 14,
                  weight: FontWeight.w600,
                  color: HelpSupportScreen.accentColor,
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: HelpSupportScreen.accentColor, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topicCard(IconData icon, String title, String subtitle,
      {bool isSelected = false}) {
    final cleanTitle = title.replaceAll('\n', ' ');
    return GestureDetector(
      onTap: () => _handleTopicTap(cleanTitle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFDF0F5)
              : HelpSupportScreen.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? HelpSupportScreen.accentColor
                : const Color(0xFFF3EAEF),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? HelpSupportScreen.accentColor
                    : const Color(0xFFFDF0F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : HelpSupportScreen.accentColor,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: _montserrat(
                size: 13,
                weight: FontWeight.w700,
                color: isSelected
                    ? HelpSupportScreen.accentColor
                    : HelpSupportScreen.primaryText,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: _montserrat(
                size: 10,
                color: HelpSupportScreen.secondaryText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionTile(Map<String, dynamic> faq) {
    final question = (faq['question'] ?? '').toString();
    return InkWell(
      onTap: () => _showFaqDetail(faq),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                question,
                style: _montserrat(size: 14, weight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: HelpSupportScreen.accentColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: const Color(0xFFF3EAEF),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _contactCard(
      IconData icon, String title, String subtitle, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HelpSupportScreen.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3EAEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFDF0F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: HelpSupportScreen.accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: _montserrat(size: 14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: _montserrat(
              size: 13,
              weight: FontWeight.w600,
              color: HelpSupportScreen.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: _montserrat(
              size: 11,
              color: HelpSupportScreen.secondaryText,
            ).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
