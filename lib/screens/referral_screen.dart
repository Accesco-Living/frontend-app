import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/referral_provider.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReferralProvider(),
      child: const _ReferralScreenContent(),
    );
  }
}

class _ReferralScreenContent extends StatefulWidget {
  const _ReferralScreenContent();

  @override
  State<_ReferralScreenContent> createState() => _ReferralScreenContentState();
}

class _ReferralScreenContentState extends State<_ReferralScreenContent> {
  static const Color accent = Color(0xFF7A0042);
  static const Color text = Color(0xFF171923);
  static const Color secondaryText = Color(0xFF8A8F9D);
  static const Color border = Color(0xFFE5E7EB);
  static const Color softPink = Color(0xFFFFF0F7);

  TextStyle _montserrat({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = text,
    double height = 1.0,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size + 3, // Automatically scales up all text on the screen
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  double getProgress(ReferralProvider provider) =>
      (provider.completedInvites / provider.targetInvites).clamp(0.0, 1.0);

  bool isDeliveryUnlocked(ReferralProvider provider) => provider.completedInvites >= provider.targetInvites;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReferralProvider>();
    
    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _header(context, provider),
                    _hero(provider),
                    _codeCard(context, provider),
                    _howItWorks(),
                    const SizedBox(height: 16),
                    _progressSection(provider),
                    const SizedBox(height: 24),
                    _recentReferralsList(provider),
                  ],
                ),
              ),
            ),
            _stickyCta(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ReferralProvider provider) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: text,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Refer & Earn',
                  style: _montserrat(
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        size: 20,
                        color: Color(0xFF69707D),
                      ),
                      onPressed: () => _showHelp(context),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: Color(0xFF69707D),
                      ),
                      onPressed: () => _openReferralHistory(context, provider),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(ReferralProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        children: [
          Text(
            "You've earned",
            style: _montserrat(
              size: 12,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${provider.earnedAmount.toInt()}',
            style: _montserrat(
              size: 34,
              weight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: getProgress(provider),
                    strokeWidth: 6,
                    backgroundColor: const Color(0xFFE4E6EA),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                Text(
                  '${(getProgress(provider) * 100).round()}%',
                  style: _montserrat(
                    size: 10,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Share the love. You both get rewarded.',
            style: _montserrat(
              size: 12,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: provider.isRedeemed ? null : provider.redeemNow,
            child: Text(
              provider.isRedeemed ? 'Redeemed' : 'Redeem now',
              style: _montserrat(
                size: 12,
                weight: FontWeight.w600,
                color: accent,
              ).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeCard(BuildContext context, ReferralProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Text(
            'YOUR REFERRAL CODE',
            style: _montserrat(
              size: 9,
              weight: FontWeight.w700,
              color: secondaryText,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            provider.referralCode,
            style: _montserrat(
              size: 20,
              weight: FontWeight.w600,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _outlineButton(
                Icons.copy_outlined,
                'Copy',
                () => _copyCode(context, provider),
              ),
              const SizedBox(width: 8),
              _filledButton(
                Icons.share_outlined,
                'Share',
                () => _shareCode(context, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _outlineButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF7D8490),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: _montserrat(
                size: 11,
                color: const Color(0xFF69707D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filledButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: _montserrat(
                size: 11,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _howItWorks() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: _montserrat(
              size: 16,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _step(
                  Icons.person_add_alt_1_outlined,
                  'Invite a friend',
                ),
              ),
              _divider(),
              Expanded(
                child: _step(
                  Icons.inventory_2_outlined,
                  'They place an\norder',
                ),
              ),
              _divider(),
              Expanded(
                child: _step(
                  Icons.card_giftcard_outlined,
                  'You both earn\n₹100',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _step(IconData icon, String title) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: softPink,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: accent,
            size: 26,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          textAlign: TextAlign.center,
          style: _montserrat(
            size: 10,
            color: const Color(0xFF353A45),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return SizedBox(
      width: 14,
      height: 52,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 1,
          height: 40,
          color: border,
        ),
      ),
    );
  }

  Widget _progressSection(ReferralProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.completedInvites} of ${provider.targetInvites} invites',
                style: _montserrat(
                  size: 11,
                  color: secondaryText,
                ),
              ),
              Text(
                isDeliveryUnlocked(provider)
                    ? 'Free delivery unlocked'
                    : 'Free delivery unlock',
                style: _montserrat(
                  size: 11,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: getProgress(provider),
                backgroundColor: const Color(0xFFE6E7EA),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentReferralsList(ReferralProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent referrals',
            style: _montserrat(
              size: 16,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...provider.recentReferrals.map(_referralRow),
        ],
      ),
    );
  }

  Widget _referralRow(ReferralEntry referral) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: softPink,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              referral.initials,
              style: _montserrat(
                size: 11,
                weight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.name,
                  style: _montserrat(
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  referral.status,
                  style: _montserrat(
                    size: 10,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            referral.reward,
            style: _montserrat(
              size: 13,
              weight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickyCta(BuildContext context, ReferralProvider provider) {
    return Container(
      width: double.infinity,
      height: 88,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: border),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: accent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              provider.inviteFriend();
              _shareCode(context, provider);
            },
            child: Center(
              child: Text(
                'Invite friends',
                style: _montserrat(
                  size: 16,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyCode(BuildContext context, ReferralProvider provider) async {
    await Clipboard.setData(
      ClipboardData(text: provider.referralCode),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Referral code copied',
            style: _montserrat(size: 12, color: Colors.white),
          ),
          duration: Duration(seconds: 1),
        ),
      );
  }

  void _shareCode(BuildContext context, ReferralProvider provider) {
    Share.share(
      'Join me on Accesco Living! Use my referral code ${provider.referralCode} to get ₹100 off your first order.',
      subject: 'Accesco Living Referral Code',
    );
  }

  void _openReferralHistory(BuildContext context, ReferralProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const ReferralHistoryScreen(),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Refer & Earn',
          style: _montserrat(
            size: 18,
            weight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Invite a friend using your referral code. Your referral progress updates dynamically on this frontend screen.',
          style: _montserrat(
            size: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: _montserrat(
                size: 13,
                weight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReferralHistoryScreen extends StatelessWidget {
  const ReferralHistoryScreen({super.key});

  static const Color accent = Color(0xFF7A0042);
  static const Color text = Color(0xFF171923);
  static const Color secondaryText = Color(0xFF8A8F9D);
  static const Color border = Color(0xFFE5E7EB);
  static const Color softPink = Color(0xFFFFF0F7);

  TextStyle _montserrat({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = text,
    double height = 1.0,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReferralProvider>(
      builder: (context, provider, child) {
        final referrals = provider.recentReferrals;
        
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: text,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Referral history',
                          style: _montserrat(
                            size: 14,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: referrals.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: border),
                itemBuilder: (_, index) {
                  final referral = referrals[index];
                  return SizedBox(
                    height: 76,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: softPink,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            referral.initials,
                            style: _montserrat(
                              size: 11,
                              weight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                referral.name,
                                style: _montserrat(
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                referral.status,
                                style: _montserrat(
                                  size: 10,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          referral.reward,
                          style: _montserrat(
                            size: 13,
                            weight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
