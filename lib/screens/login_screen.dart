import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

/// ---------------------------------------------------------------------------
/// ACCESCO LIVING — ONBOARDING & AUTHENTICATION (WELCOME / SIGN UP / LOGIN)
/// ---------------------------------------------------------------------------
/// Connected to Node.js/PostgreSQL VPS backend.
/// ---------------------------------------------------------------------------

// ----------------------------- THEME TOKENS --------------------------------

class _AL {
  // Brand Maroon / Magenta gradient background tokens
  static const Color headerBg = Color(0xFF700038);
  static const Color gradTop = Color(0xFF7A003E);
  static const Color gradMid = Color(0xFF6B0035);
  static const Color gradBottom = Color(0xFF59002B);

  // Accent Colors
  static const Color vibrantPink = Color(0xFFFF007A);
  static const Color primaryMaroon = Color(0xFF700038);
  static const Color darkPlumText = Color(0xFF5B002C);

  // Card & Field Fills
  static const Color fieldFill = Color(0xFFF5EEF3);
  static const Color fieldBorder = Color(0xFFE8DCE4);
  static const Color hintText = Color(0xFFA68E9C);
  static const Color inputText = Color(0xFF33001B);

  // OTP & Badge Tokens
  static const Color otpBoxFill = Color(0xFFF7EFF4);
  static const Color otpBoxBorder = Color(0xFFE5D5DE);
  static const Color phoneBadgeFill = Color(0xFFF7EEF4);

  static const BoxDecoration background = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [gradTop, gradMid, gradBottom],
    ),
  );
}

enum _AuthStep { welcome, signup, phone, login, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _signupFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureSignupPassword = true;
  bool _obscureSignupConfirmPassword = true;

  bool _isSignupFlow = false;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  int _loginTab = 0;

  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
  List.generate(6, (_) => FocusNode());

  int _resendSeconds = 45;
  Timer? _resendTimer;

  _AuthStep _step = _AuthStep.welcome;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final signedUpBefore = prefs.getBool('accesco_profile_completed') ?? false;

      final token = await ApiService.getToken();
      final profile = await ApiService.getUserProfile();
      if (token != null && token.isNotEmpty && profile != null && mounted) {
        context.read<UserProvider>().setVpsUser(
          uid: profile['uid']?.toString() ?? 'usr_1',
          name: profile['name']?.toString() ?? 'Accesco Member',
          email: profile['email']?.toString() ?? '',
          phone: profile['phone']?.toString(),
          householdId: profile['household_id']?.toString(),
          credits: (profile['credits'] as num?)?.toInt() ?? 500,
          cqsScore: (profile['cqs_score'] as num?)?.toDouble() ?? 85.0,
          role: profile['role']?.toString() ?? 'Resident',
        );
        _goHome();
        return;
      }

      if (!mounted) return;
      setState(() {
        _step = signedUpBefore ? _AuthStep.login : _AuthStep.welcome;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _step = _AuthStep.welcome;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String? _validateFirstName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'First name is required';
    if (name.length < 2) return 'Enter a valid name';
    return null;
  }

  String? _validateLastName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Last name is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[\w\.\-\+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(email);
    return ok ? null : 'Enter a valid email address';
  }

  String? _validatePassword(String? value) {
    final pw = value ?? '';
    if (pw.isEmpty) return 'Password is required';
    if (pw.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirm = value ?? '';
    if (confirm.isEmpty) return 'Please confirm your password';
    if (confirm != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').trim().replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String get _maskedPhone {
    final p = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (p.length < 4) return '+91 $p';
    // ✅ FIXED: Added missing minus operator
    final last4 = p.substring(p.length - 4);
    return '+91 •••• ••$last4';
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendSeconds = 0);
      } else {
        if (mounted) setState(() => _resendSeconds--);
      }
    });
  }

  void _changeNumber() {
    _resendTimer?.cancel();
    for (final c in _otpControllers) {
      c.clear();
    }
    setState(() => _step = _isSignupFlow ? _AuthStep.phone : _AuthStep.login);
  }

  void _handleSignupNext() {
    if (!(_signupFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSignupFlow = true;
      _step = _AuthStep.phone;
    });
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (!isResend) {
      final err = _validatePhone(phone);
      if (err != null) {
        _showMessage(err);
        return;
      }
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final res = await ApiService.sendOtp(phone);
      if (!mounted) return;
      setState(() => _submitting = false);

      if (res['success'] == true) {
        for (final c in _otpControllers) {
          c.clear();
        }
        _startResendTimer();
        setState(() => _step = _AuthStep.otp);
        _showMessage(
          res['message']?.toString() ?? 'Verification code sent to $phone',
          success: true,
        );
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && _otpFocusNodes.isNotEmpty) {
            _otpFocusNodes[0].requestFocus();
          }
        });
      } else {
        _showMessage(res['error']?.toString() ?? 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('Network error sending OTP: $e');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join().trim();
    if (otp.length != 6) {
      _showMessage('Please enter the full 6-digit verification code.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final phone = _phoneController.text.trim();
      final res = await ApiService.verifyOtp(phoneNumber: phone, otp: otp);

      if (!mounted) return;

      if (res['success'] == true) {
        if (_isSignupFlow) {
          final signupRes = await ApiService.signup(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: phone,
          );

          if (!mounted) return;

          if (signupRes['success'] == true) {
            final profile = signupRes['profile'] as Map<String, dynamic>;
            context.read<UserProvider>().setVpsUser(
              uid: profile['uid']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
              name: profile['name']?.toString() ?? '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
              email: profile['email']?.toString() ?? _emailController.text.trim(),
              phone: profile['phone']?.toString() ?? phone,
              householdId: profile['household_id']?.toString(),
              credits: (profile['credits'] as num?)?.toInt() ?? 500,
              cqsScore: (profile['cqs_score'] as num?)?.toDouble() ?? 85.0,
              role: profile['role']?.toString() ?? 'Resident',
            );

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('accesco_profile_completed', true);

            _showMessage('Account created & phone verified! Welcome to Accesco.', success: true);
            await _requestLocationPermission();
            if (mounted) _goHome();
          } else {
            setState(() => _submitting = false);
            _showMessage(signupRes['error']?.toString() ?? 'Signup failed. Please try again.');
          }
        } else {
          final profile = res['profile'] as Map<String, dynamic>;
          context.read<UserProvider>().setVpsUser(
            uid: profile['uid']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
            name: profile['name']?.toString() ?? 'Accesco Resident',
            email: profile['email']?.toString() ?? '',
            phone: profile['phone']?.toString() ?? phone,
            householdId: profile['household_id']?.toString(),
            credits: (profile['credits'] as num?)?.toInt() ?? 500,
            cqsScore: (profile['cqs_score'] as num?)?.toDouble() ?? 85.0,
            role: profile['role']?.toString() ?? 'Resident',
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('accesco_profile_completed', true);

          _showMessage('Phone verified successfully! Welcome to Accesco.', success: true);
          await _requestLocationPermission();
          if (mounted) _goHome();
        }
      } else {
        setState(() => _submitting = false);
        for (final c in _otpControllers) {
          c.clear();
        }
        if (_otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
        _showMessage(res['error']?.toString() ?? 'Invalid code. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('Verification error: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);

    try {
      final res = await ApiService.login(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final profile = res['profile'] as Map<String, dynamic>;
        context.read<UserProvider>().setVpsUser(
          uid: profile['uid']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: profile['name']?.toString() ?? 'Accesco Member',
          email: profile['email']?.toString() ?? _loginEmailController.text.trim(),
          householdId: profile['household_id']?.toString(),
          credits: (profile['credits'] as num?)?.toInt() ?? 500,
          cqsScore: (profile['cqs_score'] as num?)?.toDouble() ?? 85.0,
          role: profile['role']?.toString() ?? 'Resident',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('accesco_profile_completed', true);

        _showMessage('Welcome back, ${profile['name']}!', success: true);
        await _requestLocationPermission();
        if (mounted) _goHome();
      } else {
        setState(() => _submitting = false);
        _showMessage(res['error']?.toString() ?? 'Invalid credentials. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('Login error: $e');
    }
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: _AL.headerBg,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _AL.gradBottom,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _AL.headerBg,
        resizeToAvoidBottomInset: true,
        body: PopScope(
          canPop: _step == _AuthStep.welcome,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_step == _AuthStep.otp) {
              setState(() => _step = _isSignupFlow ? _AuthStep.phone : _AuthStep.login);
            } else if (_step == _AuthStep.phone) {
              setState(() => _step = _AuthStep.signup);
            } else if (_step == _AuthStep.login || _step == _AuthStep.signup) {
              setState(() => _step = _AuthStep.welcome);
            }
          },
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _AuthStep.welcome:
        return _buildWelcomeStep();
      case _AuthStep.signup:
        return _buildSignupStep();
      case _AuthStep.phone:
        return _buildPhoneStep();
      case _AuthStep.login:
        return _buildLoginStep();
      case _AuthStep.otp:
        return _buildOtpStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Container(
      key: const ValueKey('welcome-step'),
      decoration: _AL.background,
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/welcome_rider.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAccescoIcon(size: 64, isDark: true),
                const SizedBox(height: 14),
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    color: _AL.darkPlumText,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Accesco!',
                  style: TextStyle(
                    color: _AL.primaryMaroon,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 44,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: _AL.primaryMaroon,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "India's Everyday Living app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B1D4A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                _RedesignedButton(
                  label: 'Get Started',
                  onTap: () {
                    setState(() => _step = _AuthStep.signup);
                  },
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () {
                    setState(() => _step = _AuthStep.login);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: _AL.primaryMaroon,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                            decorationColor: _AL.primaryMaroon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    text: 'By tapping Get Started, I agree with the ',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: _AL.darkPlumText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: _AL.darkPlumText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupStep() {
    return Container(
      key: const ValueKey('signup-step'),
      color: _AL.headerBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(
              children: [
                _buildAccescoIcon(size: 64, isDark: false),
                const SizedBox(height: 14),
                const Text.rich(
                  TextSpan(
                    text: 'Create your\n',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: 'Accesco ',
                        style: TextStyle(
                          color: _AL.vibrantPink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: 'account',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Form(
                  key: _signupFormKey,
                  child: Column(
                    children: [
                      const _ProgressDots(activeIndex: 0),
                      const SizedBox(height: 14),
                      const Text(
                        'Enter your details to create your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PillTextField(
                              controller: _firstNameController,
                              hint: 'First Name',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              validator: _validateFirstName,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PillTextField(
                              controller: _lastNameController,
                              hint: 'Last Name',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              validator: _validateLastName,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _PillTextField(
                        controller: _emailController,
                        hint: 'Email Address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),
                      _PillTextField(
                        controller: _passwordController,
                        hint: 'Password (min. 6 characters)',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureSignupPassword,
                        validator: _validatePassword,
                        suffixWidget: IconButton(
                          icon: Icon(
                            _obscureSignupPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _AL.hintText,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureSignupPassword = !_obscureSignupPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PillTextField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm Password',
                        icon: Icons.lock_reset_rounded,
                        obscureText: _obscureSignupConfirmPassword,
                        validator: _validateConfirmPassword,
                        suffixWidget: IconButton(
                          icon: Icon(
                            _obscureSignupConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _AL.hintText,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureSignupConfirmPassword =
                              !_obscureSignupConfirmPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 26),
                      _RedesignedButton(
                        label: 'Continue',
                        loading: false,
                        onTap: _handleSignupNext,
                      ),
                      const SizedBox(height: 18),
                      Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Terms of Service\n',
                              style: TextStyle(
                                color: _AL.darkPlumText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: 'and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: _AL.darkPlumText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          setState(() => _step = _AuthStep.login);
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Log in',
                                style: TextStyle(
                                  color: _AL.primaryMaroon,
                                  fontWeight: FontWeight.w900,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _AL.primaryMaroon,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Container(
      key: const ValueKey('phone-step'),
      color: _AL.headerBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              children: [
                _buildAccescoIcon(size: 64, isDark: false),
                const SizedBox(height: 14),
                const Text.rich(
                  TextSpan(
                    text: 'Verify your\n',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: 'Mobile ',
                        style: TextStyle(
                          color: _AL.vibrantPink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: 'number',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Form(
                  key: _phoneFormKey,
                  child: Column(
                    children: [
                      const _ProgressDots(activeIndex: 1),
                      const SizedBox(height: 16),
                      const Text(
                        'One last step! Enter your phone number to receive a verification OTP.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _PillTextField(
                        controller: _phoneController,
                        hint: '10-digit Mobile Number',
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                        prefixWidget: Container(
                          margin: const EdgeInsets.only(left: 12, right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _AL.phoneBadgeFill,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _AL.otpBoxBorder),
                          ),
                          child: const Text(
                            '🇮🇳 +91',
                            style: TextStyle(
                              color: _AL.primaryMaroon,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'SHA-256 HMAC Protected Verification',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _RedesignedButton(
                        label: 'Send OTP',
                        loading: _submitting,
                        onTap: () {
                          if (_phoneFormKey.currentState?.validate() ?? false) {
                            _sendOtp(isResend: false);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          setState(() => _step = _AuthStep.signup);
                        },
                        child: const Text(
                          'Back to Account Details',
                          style: TextStyle(
                            color: _AL.primaryMaroon,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                            decorationColor: _AL.primaryMaroon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginStep() {
    return Container(
      key: const ValueKey('login-step'),
      color: _AL.headerBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              children: [
                _buildAccescoIcon(size: 68, isDark: false),
                const SizedBox(height: 14),
                const Text.rich(
                  TextSpan(
                    text: 'Welcome back\n',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: 'to ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: 'Accesco',
                        style: TextStyle(
                          color: _AL.vibrantPink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  children: [
                    const _ProgressDots(activeIndex: 0),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: _AL.fieldFill,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: _AL.fieldBorder),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_loginTab != 0) {
                                  setState(() => _loginTab = 0);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _loginTab == 0
                                      ? _AL.primaryMaroon
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: _loginTab == 0
                                      ? [
                                    const BoxShadow(
                                      color: Color(0x33700038),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Phone (OTP)',
                                  style: TextStyle(
                                    color: _loginTab == 0
                                        ? Colors.white
                                        : _AL.darkPlumText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_loginTab != 1) {
                                  setState(() => _loginTab = 1);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _loginTab == 1
                                      ? _AL.primaryMaroon
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: _loginTab == 1
                                      ? [
                                    const BoxShadow(
                                      color: Color(0x33700038),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Email & Password',
                                  style: TextStyle(
                                    color: _loginTab == 1
                                        ? Colors.white
                                        : _AL.darkPlumText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_loginTab == 0) ...[
                      const Text(
                        'Enter your mobile number to receive a secure OTP.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _phoneFormKey,
                        child: _PillTextField(
                          controller: _phoneController,
                          hint: 'Mobile Number',
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                          prefixWidget: Container(
                            margin: const EdgeInsets.only(left: 12, right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _AL.phoneBadgeFill,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _AL.otpBoxBorder),
                            ),
                            child: const Text(
                              '🇮🇳 +91',
                              style: TextStyle(
                                color: _AL.primaryMaroon,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 5),
                          Text(
                            'SHA-256 HMAC Encrypted Verification',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _RedesignedButton(
                        label: 'Get OTP',
                        loading: _submitting,
                        onTap: () {
                          if (_phoneFormKey.currentState?.validate() ?? false) {
                            _sendOtp(isResend: false);
                          }
                        },
                      ),
                    ] else ...[
                      const Text(
                        'Log in to continue where you left off.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _loginFormKey,
                        child: Column(
                          children: [
                            _PillTextField(
                              controller: _loginEmailController,
                              hint: 'Email Address',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            _PillTextField(
                              controller: _loginPasswordController,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscureLoginPassword,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                              suffixWidget: IconButton(
                                icon: Icon(
                                  _obscureLoginPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _AL.hintText,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureLoginPassword = !_obscureLoginPassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 26),
                            _RedesignedButton(
                              label: 'Log In',
                              loading: _submitting,
                              onTap: _handleLogin,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        setState(() => _step = _AuthStep.signup);
                      },
                      child: Text.rich(
                        TextSpan(
                          text: 'New to Accesco? ',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Create an account',
                              style: TextStyle(
                                color: _AL.primaryMaroon,
                                fontWeight: FontWeight.w900,
                                decoration: TextDecoration.underline,
                                decorationColor: _AL.primaryMaroon,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildOtpStep() {
    return Container(
      key: const ValueKey('otp-step'),
      color: _AL.headerBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              children: [
                _buildAccescoIcon(size: 64, isDark: false),
                const SizedBox(height: 12),
                const Text.rich(
                  TextSpan(
                    text: 'Enter Verification\n',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: 'Code',
                        style: TextStyle(
                          color: _AL.vibrantPink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
                child: Column(
                  children: [
                    _ProgressDots(activeIndex: _isSignupFlow ? 2 : 1),
                    const SizedBox(height: 14),
                    Text(
                      _isSignupFlow
                          ? 'Enter the 6-digit code to complete your signup'
                          : 'Enter the 6-digit code sent to your phone',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _submitting ? null : _changeNumber,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _AL.phoneBadgeFill,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: _AL.otpBoxBorder),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.smartphone_rounded,
                              size: 16,
                              color: _AL.primaryMaroon,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _maskedPhone,
                              style: const TextStyle(
                                color: _AL.primaryMaroon,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: _AL.primaryMaroon,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SHA-256 HMAC Protected Challenge',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, _buildOtpBox),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 15,
                              color: _resendSeconds > 0
                                  ? _AL.primaryMaroon
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '00:${_resendSeconds.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: _resendSeconds > 0
                                    ? _AL.primaryMaroon
                                    : Colors.grey.shade600,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: (_resendSeconds == 0 && !_submitting)
                              ? () => _sendOtp(isResend: true)
                              : null,
                          child: Text.rich(
                            TextSpan(
                              text: "Didn't get code? ",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Resend',
                                  style: TextStyle(
                                    color: _resendSeconds == 0
                                        ? _AL.primaryMaroon
                                        : Colors.grey.shade400,
                                    fontWeight: FontWeight.w800,
                                    decoration: _resendSeconds == 0
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                                    decorationColor: _AL.primaryMaroon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _RedesignedButton(
                      label: _isSignupFlow
                          ? 'Verify & Create Account'
                          : 'Verify & Proceed',
                      loading: _submitting,
                      onTap: _verifyOtp,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _changeNumber,
                      child: const Text(
                        'Edit Phone Number',
                        style: TextStyle(
                          color: _AL.primaryMaroon,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          decorationColor: _AL.primaryMaroon,
                        ),
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

  Widget _buildOtpBox(int index) {
    // ✅ FIXED: Corrected math logic for calculating box width
    final boxWidth = ((MediaQuery.of(context).size.width - 48 - 40) / 6).clamp(42.0, 52.0);

    final hasFocus = _otpFocusNodes[index].hasFocus;
    final hasText = _otpControllers[index].text.isNotEmpty;

    return Container(
      width: boxWidth,
      height: boxWidth + 8,
      decoration: BoxDecoration(
        color: _AL.otpBoxFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFocus || hasText ? _AL.primaryMaroon : _AL.otpBoxBorder,
          width: hasFocus ? 2.0 : 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          color: _AL.primaryMaroon,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        cursorColor: _AL.primaryMaroon,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty) {
            if (index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus();
              _verifyOtp();
            }
          } else if (index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
        onTap: () => setState(() {}),
      ),
    );
  }

  Widget _buildAccescoIcon({required double size, required bool isDark}) {
    return Image.asset(
      isDark ? 'assets/images/accesco_logo.png' : 'assets/images/accesco_white.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Icon(
        Icons.all_inclusive,
        color: isDark ? _AL.primaryMaroon : Colors.white,
        size: size,
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int activeIndex;

  const _ProgressDots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _AL.primaryMaroon : const Color(0xFFE5D5DE),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _PillTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Widget? prefixWidget;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _PillTextField({
    required this.controller,
    required this.hint,
    this.icon,
    this.prefixWidget,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixWidget,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: _AL.inputText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: _AL.primaryMaroon,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _AL.hintText,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _AL.fieldFill,
        prefixIcon: prefixWidget ??
            (icon != null
                ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Icon(
                icon,
                color: _AL.hintText,
                size: 21,
              ),
            )
                : null),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixWidget,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: _AL.fieldBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: _AL.primaryMaroon, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _RedesignedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _RedesignedButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _AL.primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: const Color(0x55700038),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}