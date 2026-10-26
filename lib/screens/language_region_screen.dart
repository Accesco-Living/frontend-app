import 'package:flutter/material.dart';
import 'help_and_support_screen.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';

class LanguageRegionScreen extends StatefulWidget {
  const LanguageRegionScreen({super.key});

  @override
  State<LanguageRegionScreen> createState() => _LanguageRegionScreenState();
}

class _LanguageRegionScreenState extends State<LanguageRegionScreen> {
  static const Color _bgColor = Color(0xFFFCF8FA);
  static const Color _primaryMaroon = Color(0xFF860038);
  static const Color _textDark = Color(0xFF1E2638);
  static const Color _textLight = Color(0xFF757D8A);
  static const Color _iconBg = Color(0xFFFDECEF);

  String _selectedRegion = 'Karnataka';
  
  final List<String> _indianStatesAndUTs = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Language & Region',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 28),
            _buildSectionHeader(AppLocalizations.of(context)?.appLanguage ?? 'App Language', 'Select the language you\'d like to use across the app.'),
            const SizedBox(height: 12),
            _buildLanguageList(),
            const SizedBox(height: 32),
            _buildSectionHeader('Region/Location', 'Set your location to get relevant content, services and offers.'),
            const SizedBox(height: 12),
            _buildRegionCards(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(text: 'A more personal\n'),
                    TextSpan(
                      text: 'experience.',
                      style: TextStyle(color: _primaryMaroon),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose your language and region/location for a more relevant and seamless experience across all Accesco Living',
                style: TextStyle(
                  fontSize: 11,
                  color: _primaryMaroon,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/language.png',
              fit: BoxFit.cover,
              height: 120,
              width: double.infinity,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: _textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildLanguageItem(context, 'en', 'EN', 'English', 'For a simple and seamless experience', isTop: true),
          _buildDivider(),
          _buildLanguageItem(context, 'hi', 'HI', 'हिन्दी', 'स्वच्छ और सरल अनुभव के लिए'),
          _buildDivider(),
          _buildLanguageItem(context, 'kn', 'KN', 'ಕನ್ನಡ', 'ಸ್ಪಷ್ಟ ಮತ್ತು ಸರಳ ಅನುಭವಕ್ಕಾಗಿ'),
          _buildDivider(),
          _buildLanguageItem(context, 'ta', 'TA', 'தமிழ்', 'தெளிவான மற்றும் எளிய அனுபவத்திற்காக'),
          _buildDivider(),
          _buildLanguageItem(context, 'ml', 'ML', 'മലയാളം', 'വ്യക്തമായതും ലളിതമായതുമായ അനുഭവത്തിനായി'),
          _buildDivider(),
          _buildMoreLanguagesItem(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade100, indent: 64);
  }

  Widget _buildLanguageItem(BuildContext context, String id, String shortCode, String title, String subtitle, {bool isTop = false}) {
    final currentLocale = context.watch<LocaleProvider>().locale.languageCode;
    final bool isSelected = currentLocale == id;
    
    return GestureDetector(
      onTap: () {
        context.read<LocaleProvider>().setLocale(Locale(id));
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language set to $title'),
            duration: const Duration(seconds: 2),
            backgroundColor: _primaryMaroon,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7E6ED) : Colors.transparent,
          borderRadius: isTop ? const BorderRadius.vertical(top: Radius.circular(16)) : null,
          border: isSelected ? Border.all(color: _primaryMaroon, width: 1.5) : Border.all(color: Colors.transparent, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                shortCode,
                style: const TextStyle(
                  color: _primaryMaroon,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryMaroon : Colors.grey.shade400,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreLanguagesItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.more_horiz, color: _primaryMaroon),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'More languages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildRegionCards() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.location_on,
          title: _selectedRegion,
          subtitle: 'India\nGet products, delivery options and offers for your location',
          actionWidget: GestureDetector(
            onTap: _showRegionSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Change',
                    style: TextStyle(
                      color: _primaryMaroon,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: _primaryMaroon),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.storefront_outlined,
          title: 'Why this matters?',
          subtitle: 'Your language and region help us show you the right content, prices, delivery options and local offers',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.headset_mic_outlined,
          title: 'Need help changing your location?',
          subtitle: 'Contact our support team for assistance',
          actionWidget: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpAndSupportScreen()),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Support',
                  style: TextStyle(
                    color: _primaryMaroon,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: _primaryMaroon),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRegionSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Region/Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: _indianStatesAndUTs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final region = _indianStatesAndUTs[index];
                      final isSelected = region == _selectedRegion;
                      return ListTile(
                        title: Text(
                          region,
                          style: TextStyle(
                            color: isSelected ? _primaryMaroon : _textDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: _primaryMaroon)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedRegion = region;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? actionWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: actionWidget != null 
            ? CrossAxisAlignment.start 
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: _primaryMaroon, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (actionWidget != null) ...[
            const SizedBox(width: 12),
            actionWidget,
          ],
        ],
      ),
    );
  }
}
