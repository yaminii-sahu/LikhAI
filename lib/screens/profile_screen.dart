import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/likh_components.dart';
import '../widgets/likh_logo.dart';
import 'settings_screen.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String language;
  final ThemeMode themeMode;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _docCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final docs = await StorageService.getDocuments();
    if (mounted) {
      setState(() {
        _docCount = docs.length;
      });
    }
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(language: widget.language),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.text(widget.language, 'Sign Out', 'साइन आउट')),
        content: Text(
          AppLocale.text(
            widget.language,
            'Are you sure you want to sign out of your account?',
            'क्या आप वास्तव में अपने खाते से साइन आउट करना चाहते हैं?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocale.text(widget.language, 'Cancel', 'रद्द करें')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocale.text(widget.language, 'Sign Out', 'साइन आउट')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocale.text(
                widget.language,
                'Signed out successfully',
                'सफलतापूर्वक साइन आउट किया गया',
              ),
            ),
          ),
        );
      }
    }
  }

  void _showAppearanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String current = widget.themeMode == ThemeMode.dark
            ? 'dark'
            : widget.themeMode == ThemeMode.light
                ? 'light'
                : 'system';

        return AlertDialog(
          title: Text(AppLocale.text(widget.language, 'Choose Theme', 'थीम चुनें')),
          content: RadioGroup<String>(
            groupValue: current,
            onChanged: (val) {
              if (val != null) {
                widget.onThemeChanged(val);
                Navigator.pop(ctx);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(AppLocale.text(widget.language, 'System Default', 'सिस्टम डिफ़ॉल्ट')),
                  value: 'system',
                ),
                RadioListTile<String>(
                  title: Text(AppLocale.text(widget.language, 'Light Mode', 'लाइट मोड')),
                  value: 'light',
                ),
                RadioListTile<String>(
                  title: Text(AppLocale.text(widget.language, 'Dark Mode', 'डार्क मोड')),
                  value: 'dark',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppLocale.text(widget.language, 'Select Language', 'भाषा चुनें')),
          content: RadioGroup<String>(
            groupValue: widget.language,
            onChanged: (val) {
              if (val != null) {
                widget.onLanguageChanged(val);
                Navigator.pop(ctx);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text('English'),
                  value: 'English',
                ),
                RadioListTile<String>(
                  title: Text('हिन्दी (Hindi)'),
                  value: 'Hindi',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const LikhBrandLogo(
          markSize: 32,
          fontSize: 18,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '“Your handwriting. Digitized.”',
              style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocale.text(
                widget.language,
                'LIKH AI is an intelligent handwriting digitization application that converts handwritten notes into clean, editable digital text and downloadable professional PDFs.',
                'LIKH AI एक बुद्धिमान हस्तलेखन डिजिटलीकरण एप्लिकेशन है जो हस्तलिखित नोट्स को साफ़, संपादन योग्य डिजिटल टेक्स्ट और डाउनलोड करने योग्य पेशेवर PDF में परिवर्तित करता है।',
              ),
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text('Version: 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocale.text(widget.language, 'Close', 'बंद करें')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.text(widget.language, 'Privacy & Security', 'गोपनीयता और सुरक्षा')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocale.text(
                  widget.language,
                  'Your privacy is our priority.',
                  'आपकी गोपनीयता हमारी प्राथमिकता है।',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocale.text(
                  widget.language,
                  '• All documents and digitized notes are stored locally on your device.\n'
                  '• Images uploaded for OCR are processed securely on the LIKH AI backend.\n'
                  '• No private notes or sensitive text are used for public model training.\n'
                  '• You can delete your documents and local data anytime in Settings.',
                  '• सभी दस्तावेज़ और डिजिटाइज़ किए गए नोट्स आपके डिवाइस पर स्थानीय रूप से संग्रहीत होते हैं।\n'
                  '• OCR के लिए अपलोड की गई छवियां LIKH AI बैकएंड पर सुरक्षित रूप से संसाधित की जाती हैं।\n'
                  '• किसी भी निजी नोट्स का उपयोग सार्वजनिक मॉडल प्रशिक्षण के लिए नहीं किया जाता है।\n'
                  '• आप सेटिंग्स में कभी भी अपने दस्तावेज़ और स्थानीय डेटा हटा सकते हैं।',
                ),
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocale.text(widget.language, 'OK', 'ठीक है')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService.authNotifier,
      builder: (context, user, _) {
        final isLoggedIn = user != null && user.email != 'guest@likhai.local';
        final isGuest = user != null && user.email == 'guest@likhai.local';
        final displayName = user?.name ?? 'LIKH AI User';
        final displayEmail = user?.email ?? 'Sign in to sync your notes';
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocale.text(widget.language, 'Profile', 'प्रोफ़ाइल')),
            actions: [
              if (isLoggedIn || isGuest)
                IconButton(
                  tooltip: AppLocale.text(widget.language, 'Sign Out', 'साइन आउट'),
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _handleSignOut,
                ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar & User Header Card
              LikhCard(
                padding: const EdgeInsets.all(22),
                borderRadius: 22,
                child: Column(
                  children: [
                    InkWell(
                      onTap: isLoggedIn ? null : _openLogin,
                      borderRadius: BorderRadius.circular(44),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(80),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: user != null && user.name.isNotEmpty
                              ? Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 46,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (!isLoggedIn)
                      LikhButton(
                        label: AppLocale.text(widget.language, 'Sign In / Register', 'साइन इन / रजिस्टर'),
                        icon: Icons.login_rounded,
                        onPressed: _openLogin,
                      )
                    else
                      LikhBadge(
                        label: AppLocale.text(widget.language, 'Logged In', 'लॉग इन किया'),
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats Banner (Single Centered Stat - Figma Intentionally Styled)
              LikhCard(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                borderRadius: 22,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$_docCount',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocale.text(widget.language, 'Saved Documents', 'सहेजे गए दस्तावेज़'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Menu items
              _ProfileItem(
                icon: Icons.tune_rounded,
                title: AppLocale.text(widget.language, 'Settings', 'सेटिंग्स'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        language: widget.language,
                        themeMode: widget.themeMode,
                        onThemeChanged: widget.onThemeChanged,
                        onLanguageChanged: widget.onLanguageChanged,
                      ),
                    ),
                  );
                },
              ),

              _ProfileItem(
                icon: Icons.dark_mode_rounded,
                title: AppLocale.text(widget.language, 'Appearance / Theme', 'दिखावट / थीम'),
                trailingText: widget.themeMode == ThemeMode.dark
                    ? 'Dark'
                    : widget.themeMode == ThemeMode.light
                        ? 'Light'
                        : 'System',
                onTap: _showAppearanceDialog,
              ),

              _ProfileItem(
                icon: Icons.language_rounded,
                title: AppLocale.text(widget.language, 'Language', 'भाषा'),
                trailingText: widget.language,
                onTap: _showLanguageDialog,
              ),

              _ProfileItem(
                icon: Icons.shield_outlined,
                title: AppLocale.text(widget.language, 'Privacy & Local Storage', 'गोपनीयता और स्थानीय डेटा'),
                onTap: _showPrivacyDialog,
              ),

              _ProfileItem(
                icon: Icons.info_outline_rounded,
                title: AppLocale.text(widget.language, 'About LIKH AI', 'LIKH AI के बारे में'),
                onTap: _showAboutDialog,
              ),

              if (isLoggedIn || isGuest) ...[
                const SizedBox(height: 10),
                LikhCard(
                  onTap: _handleSignOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  borderRadius: 18,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        AppLocale.text(widget.language, 'Sign Out', 'साइन आउट'),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  },
);
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.icon,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LikhCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 18,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: TextStyle(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
