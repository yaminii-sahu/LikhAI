import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/localization.dart';
import '../../services/auth_service.dart';
import '../../widgets/likh_logo.dart';

class LoginScreen extends StatefulWidget {
  final String language;

  const LoginScreen({
    super.key,
    this.language = 'English',
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sign In form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;
  bool _rememberMe = true;
  bool _isLoggingIn = false;
  String? _loginError;

  // Sign Up form controllers
  final _signupFormKey = GlobalKey<FormState>();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  bool _signupObscure = true;
  bool _signupConfirmObscure = true;
  bool _isSigningUp = false;
  String? _signupError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    final res = await AuthService.login(
      email: _loginEmailController.text,
      password: _loginPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoggingIn = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.text(
              widget.language,
              'Welcome back, ${res['user'].name}! ✓',
              'स्वागत है, ${res['user'].name}! ✓',
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loginError = res['message'] ?? 'Login failed. Please check credentials.';
      });
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    setState(() {
      _isSigningUp = true;
      _signupError = null;
    });

    final res = await AuthService.register(
      name: _signupNameController.text,
      email: _signupEmailController.text,
      password: _signupPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isSigningUp = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.text(
              widget.language,
              'Account created successfully! Welcome, ${res['user'].name} ✓',
              'खाता सफलतापूर्वक बनाया गया! स्वागत है, ${res['user'].name} ✓',
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _signupError = res['message'] ?? 'Sign up failed. Please try again.';
      });
    }
  }

  Future<void> _handleDemoLogin() async {
    setState(() {
      _isLoggingIn = true;
      _loginError = null;
      _loginEmailController.text = 'demo@likhai.com';
      _loginPasswordController.text = 'likhai123';
    });

    final res = await AuthService.demoLogin();

    if (!mounted) return;

    setState(() => _isLoggingIn = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.text(
              widget.language,
              'Signed in as Demo User ✓',
              'डेमो उपयोगकर्ता के रूप में साइन इन किया ✓',
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loginError = res['message'] ?? 'Demo login failed.';
      });
    }
  }

  Future<void> _handleGuest() async {
    await AuthService.guestLogin();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.text(
              widget.language,
              'Continuing as Guest User',
              'अतिथि उपयोगकर्ता के रूप में जारी रख रहे हैं',
            ),
          ),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _loginEmailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.text(widget.language, 'Reset Password', 'पासवर्ड रीसेट करें')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocale.text(
                widget.language,
                'Enter your account email to receive reset instructions.',
                'रीसेट निर्देश प्राप्त करने के लिए अपना ईमेल दर्ज करें।',
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocale.text(widget.language, 'Cancel', 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocale.text(
                      widget.language,
                      'Password reset link sent to ${emailCtrl.text} ✓',
                      'पासवर्ड रीसेट लिंक भेजा गया ✓',
                    ),
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(AppLocale.text(widget.language, 'Send', 'भेजें')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIKH AI'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LIKH AI Official Brand Logo
                  const LikhBrandLogo(
                    markSize: 68,
                    fontSize: 28,
                    isVertical: true,
                    showTagline: true,
                    tagline: 'Your handwriting. Digitized.',
                  ),

                  const SizedBox(height: 24),

                  // Tab Selector: Sign In / Create Account
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                      tabs: [
                        Tab(text: AppLocale.text(widget.language, 'Sign In', 'साइन इन')),
                        Tab(text: AppLocale.text(widget.language, 'Create Account', 'नया खाता')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab Views
                  SizedBox(
                    height: 420,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // --- SIGN IN TAB ---
                        _buildSignInTab(theme, isDark),

                        // --- SIGN UP TAB ---
                        _buildSignUpTab(theme, isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick Demo / Guest Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoggingIn ? null : _handleDemoLogin,
                          icon: const Icon(Icons.flash_on_rounded, size: 18),
                          label: Text(
                            AppLocale.text(widget.language, 'Demo Login', 'डेमो लॉगिन'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _handleGuest,
                          icon: const Icon(Icons.person_outline_rounded, size: 18),
                          label: Text(
                            AppLocale.text(widget.language, 'Guest Mode', 'अतिथि मोड'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInTab(ThemeData theme, bool isDark) {
    return Form(
      key: _loginFormKey,
      child: ListView(
        children: [
          if (_loginError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loginError!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Email
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: AppLocale.text(widget.language, 'Email', 'ईमेल'),
              hintText: 'name@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return AppLocale.text(widget.language, 'Please enter email', 'कृपया ईमेल दर्ज करें');
              }
              if (!val.contains('@') || !val.contains('.')) {
                return AppLocale.text(widget.language, 'Enter valid email', 'मान्य ईमेल दर्ज करें');
              }
              return null;
            },
          ),

          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _loginObscure,
            decoration: InputDecoration(
              labelText: AppLocale.text(widget.language, 'Password', 'पासवर्ड'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _loginObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _loginObscure = !_loginObscure),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return AppLocale.text(widget.language, 'Please enter password', 'कृपया पासवर्ड दर्ज करें');
              }
              if (val.length < 6) {
                return AppLocale.text(widget.language, 'Minimum 6 characters', 'न्यूनतम 6 अक्षर');
              }
              return null;
            },
          ),

          const SizedBox(height: 6),

          // Remember Me & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _rememberMe = val ?? true),
                  ),
                  Text(
                    AppLocale.text(widget.language, 'Remember me', 'याद रखें'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  AppLocale.text(widget.language, 'Forgot Password?', 'पासवर्ड भूल गए?'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Sign In Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoggingIn ? null : _handleLogin,
              child: _isLoggingIn
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      AppLocale.text(widget.language, 'Sign In', 'साइन इन'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpTab(ThemeData theme, bool isDark) {
    return Form(
      key: _signupFormKey,
      child: ListView(
        children: [
          if (_signupError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _signupError!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Full Name
          TextFormField(
            controller: _signupNameController,
            decoration: InputDecoration(
              labelText: AppLocale.text(widget.language, 'Full Name', 'पूरा नाम'),
              hintText: 'John Doe',
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return AppLocale.text(widget.language, 'Please enter name', 'कृपया नाम दर्ज करें');
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Email
          TextFormField(
            controller: _signupEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: AppLocale.text(widget.language, 'Email', 'ईमेल'),
              hintText: 'name@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return AppLocale.text(widget.language, 'Please enter email', 'कृपया ईमेल दर्ज करें');
              }
              if (!val.contains('@') || !val.contains('.')) {
                return AppLocale.text(widget.language, 'Enter valid email', 'मान्य ईमेल दर्ज करें');
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: _signupPasswordController,
            obscureText: _signupObscure,
            decoration: InputDecoration(
              labelText: AppLocale.text(widget.language, 'Password', 'पासवर्ड'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _signupObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _signupObscure = !_signupObscure),
              ),
            ),
            validator: (val) {
              if (val == null || val.length < 6) {
                return AppLocale.text(widget.language, 'Minimum 6 characters', 'न्यूनतम 6 अक्षर');
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Confirm Password
          TextFormField(
            controller: _signupConfirmPasswordController,
            obscureText: _signupConfirmObscure,
            decoration: InputDecoration(
              labelText: AppLocale.text(widget.language, 'Confirm Password', 'पासवर्ड की पुष्टि करें'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _signupConfirmObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _signupConfirmObscure = !_signupConfirmObscure),
              ),
            ),
            validator: (val) {
              if (val != _signupPasswordController.text) {
                return AppLocale.text(widget.language, 'Passwords do not match', 'पासवर्ड मेल नहीं खाते');
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Create Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSigningUp ? null : _handleSignup,
              child: _isSigningUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      AppLocale.text(widget.language, 'Create Account', 'नया खाता बनाएँ'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
