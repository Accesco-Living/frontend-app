import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'help_and_support_screen.dart';
import 'login_screen.dart';
import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';

class SecurityLoginScreen extends StatefulWidget {
  const SecurityLoginScreen({super.key});

  @override
  State<SecurityLoginScreen> createState() => _SecurityLoginScreenState();
}

class _SecurityLoginScreenState extends State<SecurityLoginScreen> {
  static const Color primaryMaroon = Color(0xFF9D1C50); 
  static const Color lightBg = Color(0xFFFFF7FA);
  
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityPreferences();
  }

  Future<void> _loadSecurityPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? true;
      _twoFactorEnabled = prefs.getBool('two_factor_enabled') ?? true;
    });

    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['twoFactorEnabled'] != null) {
            setState(() {
              _twoFactorEnabled = data['twoFactorEnabled'] as bool;
            });
            await prefs.setBool('two_factor_enabled', _twoFactorEnabled);
          }
        }
      } catch (e) {
        debugPrint('Error loading Firestore security preferences: $e');
      }
    }
  }

  Future<void> _toggleTwoFactor() async {
    final newState = !_twoFactorEnabled;
    setState(() => _twoFactorEnabled = newState);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('two_factor_enabled', newState);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'twoFactorEnabled': newState,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating 2FA state: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newState ? 'Two-Step Verification Enabled' : 'Two-Step Verification Disabled'),
        backgroundColor: newState ? Colors.green : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _biometricEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Biometric Login Enabled' : 'Biometric Login Disabled'),
        backgroundColor: value ? Colors.green : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account & Login',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF1E293B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpAndSupportScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildHeroSection(),
              const SizedBox(height: 24),
              _buildLoginSecuritySection(),
              const SizedBox(height: 16),
              _buildTipsSection(),
              const SizedBox(height: 16),
              _buildNeedHelpSection(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 22),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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

  Widget _buildHeroSection() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'YOUR SECURITY MATTERS',
                style: TextStyle(color: primaryMaroon, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
              SizedBox(height: 6),
              Text(
                'A Safer Stay.',
                style: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
              ),
              Text(
                'A Worry-Free You.',
                style: TextStyle(color: primaryMaroon, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
              ),
              SizedBox(height: 12),
              Text(
                'Manage your account, keep your\ninformation secure, and stay in control.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: Image.asset(
              'assets/images/secure.png',
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.shield, color: primaryMaroon, size: 80),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Login & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        const Text('Manage how you access your account and keep it secure.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 16),
        _buildItemCard(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your password regularly for better security.',
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          onTap: () => _showChangePasswordDialog(context),
        ),
        _buildItemCard(
          icon: Icons.shield_outlined,
          title: 'Two-Step Verification',
          subtitle: 'Add an extra layer of security to your account.',
          onTap: _toggleTwoFactor,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _twoFactorEnabled ? const Color(0xFFE6F4EA) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _twoFactorEnabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    color: _twoFactorEnabled ? const Color(0xFF137333) : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
        _buildItemCard(
          icon: Icons.devices_outlined,
          title: 'Manage Devices',
          subtitle: 'View and manage devices where you\'re logged in.',
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          onTap: _showManageDevicesModal,
        ),
        _buildItemCard(
          icon: Icons.gpp_maybe_outlined,
          title: 'Login Activity',
          subtitle: 'Check your recent login activity.',
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          onTap: _showLoginActivityModal,
        ),
        _buildItemCard(
          icon: Icons.fingerprint,
          title: 'Biometric Login',
          subtitle: 'Use fingerprint or face ID for faster access.',
          trailing: Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
              activeColor: primaryMaroon,
            ),
          ),
        ),
        _buildItemCard(
          icon: Icons.logout,
          title: 'Logout from All Devices',
          subtitle: 'Sign out from all devices for your security.',
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          onTap: _showLogoutAllDialog,
        ),
        _buildItemCard(
          icon: Icons.logout,
          title: 'Log Out',
          subtitle: 'Sign out of your account on this device.',
          iconColor: const Color(0xFFDC2626),
          titleColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
          borderColor: const Color(0xFFFECACA),
          cardBgColor: const Color(0xFFFEF2F2),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFEF4444), size: 20),
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildItemCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? iconColor,
    Color? titleColor,
    Color? iconBgColor,
    Color? borderColor,
    Color? cardBgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor ?? const Color(0xFFFFF0F5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? primaryMaroon, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: titleColor ?? const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return GestureDetector(
      onTap: _showSecurityTipsModal,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb_outline, color: primaryMaroon, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tips to keep your account safe', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  _buildTipBullet('Use a strong, unique password.'),
                  _buildTipBullet('Enable two-step verification.'),
                  _buildTipBullet('Never share your OTP or password with anyone.'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTipBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5.0, right: 6.0),
            child: Icon(Icons.circle, size: 5, color: primaryMaroon),
          ),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.3))),
        ],
      ),
    );
  }

  Widget _buildNeedHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headset_mic_outlined, color: primaryMaroon, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Need Help?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
                SizedBox(height: 4),
                Text('If you\'re facing issues\nwith your account or\nlogin, our support team is\nhere to help.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.3)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpAndSupportScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text('Get Support', style: TextStyle(color: primaryMaroon, fontWeight: FontWeight.bold, fontSize: 11)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: primaryMaroon, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Change Password',
                      style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 24),
                    ),
                    const SizedBox(height: 24),
                    const Text('Current Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: currentPasswordController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        hintText: 'Enter current password',
                        hintStyle: const TextStyle(fontSize: 15, color: Colors.black38, fontWeight: FontWeight.w500),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey.shade600),
                          onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: TextButton(
                          onPressed: () async {
                            final email = FirebaseAuth.instance.currentUser?.email;
                            if (email != null && email.isNotEmpty) {
                              try {
                                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                if (modalContext.mounted) {
                                  ScaffoldMessenger.of(modalContext).showSnackBar(
                                    SnackBar(content: Text('Password reset email sent to $email')),
                                  );
                                }
                              } catch (e) {
                                debugPrint('Reset email error: $e');
                              }
                            }
                          },
                          child: const Text('Forgot password?', style: TextStyle(color: primaryMaroon, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('New Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        hintStyle: const TextStyle(fontSize: 15, color: Colors.black38, fontWeight: FontWeight.w500),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey.shade600),
                          onPressed: () => setModalState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                        hintStyle: const TextStyle(fontSize: 15, color: Colors.black38, fontWeight: FontWeight.w500),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey.shade600),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final currentPass = currentPasswordController.text;
                                    final newPass = newPasswordController.text;
                                    final confirmPass = confirmPasswordController.text;

                                    if (newPass.length < 6) {
                                      ScaffoldMessenger.of(modalContext).showSnackBar(
                                        const SnackBar(content: Text('New password must be at least 6 characters')),
                                      );
                                      return;
                                    }
                                    if (newPass != confirmPass) {
                                      ScaffoldMessenger.of(modalContext).showSnackBar(
                                        const SnackBar(content: Text('New passwords do not match')),
                                      );
                                      return;
                                    }

                                    setModalState(() => isSubmitting = true);
                                    try {
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user != null && user.email != null) {
                                        final cred = EmailAuthProvider.credential(
                                          email: user.email!,
                                          password: currentPass,
                                        );
                                        await user.reauthenticateWithCredential(cred);
                                        await user.updatePassword(newPass);

                                        if (modalContext.mounted) {
                                          Navigator.pop(modalContext);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Password updated successfully!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      setModalState(() => isSubmitting = false);
                                      if (modalContext.mounted) {
                                        ScaffoldMessenger.of(modalContext).showSnackBar(
                                          SnackBar(content: Text('Failed to update password: $e'), backgroundColor: Colors.redAccent),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: primaryMaroon,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManageDevicesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Manage Devices', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 20)),
              const SizedBox(height: 8),
              const Text('Active sessions where your account is currently signed in.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 20),
              _buildDeviceItem('Android 14 (This Device)', 'Bengaluru, India • Active Now', isCurrent: true),
              _buildDeviceItem('Chrome Web Browser', 'Bengaluru, India • 2 hours ago', isCurrent: false),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out from all other devices.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryMaroon,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Sign Out Other Devices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceItem(String device, String details, {required bool isCurrent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFFFF0F5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCurrent ? primaryMaroon.withOpacity(0.3) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_android, color: isCurrent ? primaryMaroon : Colors.grey.shade600),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(device, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Text('THIS DEVICE', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(details, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginActivityModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Login Activity', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 20)),
              const SizedBox(height: 8),
              const Text('Recent login attempts and active sessions.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 20),
              _buildActivityItem('Today, 11:16 AM', 'Mobile App (OTP Auth)', 'Bengaluru, India', 'Successful'),
              _buildActivityItem('Yesterday, 04:30 PM', 'Web Browser (Google Sign-In)', 'Bengaluru, India', 'Successful'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(String time, String method, String location, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                Text('$method • $location', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
          Text(status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Text('Log Out', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of Accesco Living? You will need to log in again to access your account.',
          style: TextStyle(height: 1.4, fontSize: 14, color: Color(0xFF4B5563)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryMaroon),
                          ),
                          SizedBox(width: 16),
                          Text('Logging out...', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final cartProvider = Provider.of<CartProvider>(context, listen: false);
              final navigator = Navigator.of(context, rootNavigator: true);
              final messenger = ScaffoldMessenger.of(context);

              try {
                cartProvider.clearCart();
              } catch (_) {}

              try {
                await userProvider.logout();
              } catch (e) {
                debugPrint('Logout error: $e');
              }

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Color(0xFF1E293B),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Text('Sign out all devices?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This will revoke active sessions on all browsers, mobile devices, and tablets. You will need to log in again.',
          style: TextStyle(height: 1.4, fontSize: 14, color: Color(0xFF4B5563)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryMaroon),
                          ),
                          SizedBox(width: 16),
                          Text('Signing out all devices...', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final cartProvider = Provider.of<CartProvider>(context, listen: false);
              final navigator = Navigator.of(context, rootNavigator: true);
              final messenger = ScaffoldMessenger.of(context);

              try {
                cartProvider.clearCart();
              } catch (_) {}

              try {
                await userProvider.logout();
              } catch (e) {
                debugPrint('Logout all error: $e');
              }

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Signed out from all devices'),
                  backgroundColor: Color(0xFF1E293B),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Sign Out All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSecurityTipsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Security Best Practices', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 20)),
              const SizedBox(height: 16),
              _buildTipItem('1. Strong Passwords', 'Mix uppercase, lowercase, numbers, and symbols.'),
              _buildTipItem('2. Two-Factor Verification', 'Keep 2FA enabled for instant SMS/Email alerts.'),
              _buildTipItem('3. Never Share OTPs', 'Accesco team members will never ask for your password or OTP.'),
              _buildTipItem('4. Monitor Active Sessions', 'Regularly review signed-in devices.'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }
}
