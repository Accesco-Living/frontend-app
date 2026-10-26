import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

// ==========================================
// 1. STATE PROVIDER
// ==========================================
class NotificationProvider extends ChangeNotifier {
  // Everything default disabled
  bool allowNotification = false;
  
  bool orderDeliveries = false;
  bool offersPromotions = false;
  bool groklyUpdates = false;
  bool swadishttUpdates = false;
  bool xpenseMeterUpdates = false;
  bool importantAlerts = false;

  // Dynamic notification channels
  bool pushEnabled = false;
  bool emailEnabled = false;
  bool whatsAppEnabled = false;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await FirebaseService.getNotificationPreferences();
    if (prefs != null) {
      allowNotification = prefs['allowNotification'] ?? false;
      orderDeliveries = prefs['orderDeliveries'] ?? false;
      offersPromotions = prefs['offersPromotions'] ?? false;
      groklyUpdates = prefs['groklyUpdates'] ?? false;
      swadishttUpdates = prefs['swadishttUpdates'] ?? false;
      xpenseMeterUpdates = prefs['xpenseMeterUpdates'] ?? false;
      importantAlerts = prefs['importantAlerts'] ?? false;
      pushEnabled = prefs['pushEnabled'] ?? false;
      emailEnabled = prefs['emailEnabled'] ?? false;
      whatsAppEnabled = prefs['whatsAppEnabled'] ?? false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _savePreference(String key, bool value) async {
    await FirebaseService.updateNotificationPreferences({key: value});
  }

  void toggleAllow(bool val) {
    allowNotification = val;
    notifyListeners();
    _savePreference('allowNotification', val);
  }

  void toggleOrder(bool val) {
    orderDeliveries = val;
    notifyListeners();
    _savePreference('orderDeliveries', val);
  }

  void toggleOffers(bool val) {
    offersPromotions = val;
    notifyListeners();
    _savePreference('offersPromotions', val);
  }

  void toggleGrokly(bool val) {
    groklyUpdates = val;
    notifyListeners();
    _savePreference('groklyUpdates', val);
  }

  void toggleSwadishtt(bool val) {
    swadishttUpdates = val;
    notifyListeners();
    _savePreference('swadishttUpdates', val);
  }

  void toggleXpenseMeter(bool val) {
    xpenseMeterUpdates = val;
    notifyListeners();
    _savePreference('xpenseMeterUpdates', val);
  }

  void toggleAlerts(bool val) {
    importantAlerts = val;
    notifyListeners();
    _savePreference('importantAlerts', val);
  }

  void togglePushChannel() {
    pushEnabled = !pushEnabled;
    notifyListeners();
    _savePreference('pushEnabled', pushEnabled);
  }

  void toggleEmailChannel() {
    emailEnabled = !emailEnabled;
    notifyListeners();
    _savePreference('emailEnabled', emailEnabled);
  }

  void toggleWhatsAppChannel() {
    whatsAppEnabled = !whatsAppEnabled;
    notifyListeners();
    _savePreference('whatsAppEnabled', whatsAppEnabled);
  }
}

// ==========================================
// 2. MAIN VIEW WIDGET
// ==========================================
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationProvider(),
      child: const _NotificationViewContent(),
    );
  }
}

class _NotificationViewContent extends StatefulWidget {
  const _NotificationViewContent();

  @override
  State<_NotificationViewContent> createState() =>
      _NotificationViewContentState();
}

class _NotificationViewContentState extends State<_NotificationViewContent> {
  static const Color brandPrimary = Color(0xFF7A0042);
  static const Color brandGradientStart = Color(0xFFBE0067);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGray = Color(0xFF64748B);
  static const Color brandPinkTag = Color(0xFFC4126A);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final isAllowed = provider.allowNotification;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, size: 20, color: textDark),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.45,
          ),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.question_mark_rounded,
                  size: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      body: provider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  // Text Column
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Montserrat',
                              height: 1.2,
                            ),
                            children: [
                              TextSpan(
                                text: 'Stay Updated\n',
                                style: TextStyle(color: textDark),
                              ),
                              TextSpan(
                                text: 'on what matters.',
                                style: TextStyle(color: brandPinkTag),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Get real-time updates, offers and important alerts across all Accesco Living services.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '—— REAL PEOPLE. REAL SPACES.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: brandPinkTag,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Illustration
                  Expanded(
                    flex: 2,
                    child: Image.asset(
                      'assets/images/notification_hero.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Master "Allow Notification" Frame
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildIconCircle(
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      size: 24,
                      color: brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allow Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Receive updates, offers and alerts from Accesco Living',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSwitch(
                    value: provider.allowNotification,
                    onChanged: (v) => provider.toggleAllow(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // The rest of the settings depend on the master switch
            AnimatedOpacity(
              opacity: isAllowed ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !isAllowed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Notification Preferences
                    _buildSectionTitle(
                      'Notification Preferences',
                      'Choose what you’d like to be notified about.',
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildRowItem(
                            iconWidget: _buildIconCircle(
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 22,
                                color: brandPrimary,
                              ),
                            ),
                            title: 'Orders & Deliveries',
                            desc: 'Order confirmation, delivery updates, returns and more.',
                            val: provider.orderDeliveries,
                            onChanged: (v) => provider.toggleOrder(v),
                            divider: true,
                          ),
                          _buildRowItem(
                            iconWidget: _buildIconCircle(
                              child: const Icon(
                                Icons.local_offer_outlined,
                                size: 22,
                                color: brandPrimary,
                              ),
                            ),
                            title: 'Offers & Promotions',
                            desc: 'Exclusive deals, discounts and seasonal offers.',
                            val: provider.offersPromotions,
                            onChanged: (v) => provider.toggleOffers(v),
                            divider: true,
                          ),

                          // Grokly Updates
                          _buildRowItem(
                            iconWidget: _buildIconCircle(
                              child: Image.asset(
                                'assets/images/grokly_logo.png',
                                width: 24,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                isAntiAlias: true,
                              ),
                            ),
                            title: 'Grokly Updates',
                            desc: 'Daily essentials offers and new arrivals.',
                            val: provider.groklyUpdates,
                            onChanged: (v) => provider.toggleGrokly(v),
                            divider: true,
                          ),

                          // Swadishtt Updates
                          _buildRowItem(
                            iconWidget: _buildIconCircle(
                              child: Image.asset(
                                'assets/images/swadisht_logo.png',
                                width: 24,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            title: 'Swadishtt Updates',
                            desc: 'New menus, special offers and dining updates.',
                            val: provider.swadishttUpdates,
                            onChanged: (v) => provider.toggleSwadishtt(v),
                            divider: true,
                          ),

                          // Xpense Meter Updates
                          _buildRowItem(
                            iconWidget: _buildIconCircle(
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 22,
                                color: brandPrimary,
                              ),
                            ),
                            title: 'Xpense Meter Updates',
                            desc: 'Expense reminders, reports and insights.',
                            val: provider.xpenseMeterUpdates,
                            onChanged: (v) => provider.toggleXpenseMeter(v),
                            divider: true,
                          ),

                          // Important Alerts
                          _buildRowItem(
                            iconWidget: _buildIconCircle(
                              child: const Icon(
                                Icons.campaign_rounded,
                                size: 22,
                                color: brandPrimary,
                              ),
                            ),
                            title: 'Important Alerts',
                            desc: 'Account, security and service-related updates.',
                            val: provider.importantAlerts,
                            onChanged: (v) => provider.toggleAlerts(v),
                            divider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section 2: Channels
                    _buildSectionTitle(
                      'Notification Channels',
                      "Choose how you'd like to receive notifications.",
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildChannelRow(
                            iconWidget: _buildIconCircle(
                              child: const Icon(
                                Icons.phone_android_rounded,
                                size: 22,
                                color: brandPrimary,
                              ),
                            ),
                            title: 'Push Notifications',
                            desc: 'Receive notifications on your device.',
                            isEnabled: provider.pushEnabled,
                            onToggle: () => provider.togglePushChannel(),
                            divider: true,
                          ),
                          _buildChannelRow(
                            iconWidget: _buildIconCircle(
                              child: const Icon(
                                Icons.mail_outline_rounded,
                                size: 22,
                                color: brandPrimary,
                              ),
                            ),
                            title: 'Email Notifications',
                            desc: 'Get important updates via email.',
                            isEnabled: provider.emailEnabled,
                            onToggle: () => provider.toggleEmailChannel(),
                            divider: true,
                          ),
                          _buildChannelRow(
                            iconWidget: _buildIconCircle(
                              child: const Icon(
                                Icons.chat_outlined,
                                size: 22,
                                color: brandPrimary,
                              ),
                            ),
                            title: 'WhatsApp Notifications',
                            desc: 'Receive updates on WhatsApp.',
                            isEnabled: provider.whatsAppEnabled,
                            onToggle: () => provider.toggleWhatsAppChannel(),
                            divider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bottom Policy Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF0F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCE7F3), width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIconCircle(
                            child: const Icon(
                              Icons.info_outline_rounded,
                              size: 22,
                              color: brandPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [brandGradientStart, brandPrimary],
                                  ).createShader(
                                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                                  ),
                                  child: const Text(
                                    'You can change these preferences anytime.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "We'll only send you relevant and important updates.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle({required Widget child}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF0F4),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFCE7F3), width: 1.5),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildRowItem({
    required Widget iconWidget,
    required String title,
    required String desc,
    required bool val,
    required ValueChanged<bool> onChanged,
    required bool divider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textGray,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildSwitch(value: val, onChanged: onChanged),
            ],
          ),
        ),
        if (divider)
          const Divider(height: 1.5, thickness: 1.5, color: Color(0xFFF8FAFC)),
      ],
    );
  }

  Widget _buildChannelRow({
    required Widget iconWidget,
    required String title,
    required String desc,
    required bool isEnabled,
    required VoidCallback onToggle,
    required bool divider,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          splashColor: Colors.transparent,
          highlightColor: const Color(0xFFFAF0F4).withAlpha(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textGray,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? const Color(0xFFE8F8EE)
                        : const Color(0xFFFDECEF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEnabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isEnabled
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
        if (divider)
          const Divider(height: 1.5, thickness: 1.5, color: Color(0xFFF8FAFC)),
      ],
    );
  }

  Widget _buildSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: value
              ? const LinearGradient(
                  colors: [brandGradientStart, brandPrimary],
                )
              : null,
          color: value ? null : const Color(0xFFE2E8F0),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
