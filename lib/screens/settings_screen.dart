import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../services/storage_service.dart';
import '../widgets/likh_logo.dart';

class SettingsScreen extends StatefulWidget {
  final String language;
  final ThemeMode themeMode;
  final ValueChanged<String>? onThemeChanged;
  final ValueChanged<String>? onLanguageChanged;

  const SettingsScreen({
    super.key,
    this.language = 'English',
    this.themeMode = ThemeMode.system,
    this.onThemeChanged,
    this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSave = true;
  bool _aiSuggestions = true;
  late String _currentLanguage;
  late ThemeMode _currentThemeMode;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;
    _currentThemeMode = widget.themeMode;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final auto = await StorageService.getAutoSave();
    final ai = await StorageService.getAiSuggestions();

    if (mounted) {
      setState(() {
        _autoSave = auto;
        _aiSuggestions = ai;
      });
    }
  }

  void _showAppearanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocale.text(
            _currentLanguage,
            'Theme Preference',
            'थीम प्राथमिकता',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocale.text(_currentLanguage, 'System Default', 'सिस्टम डिफ़ॉल्ट')),
              trailing: _currentThemeMode == ThemeMode.system
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _currentThemeMode = ThemeMode.system);
                widget.onThemeChanged?.call('system');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(AppLocale.text(_currentLanguage, 'Light Mode', 'लाइट मोड')),
              trailing: _currentThemeMode == ThemeMode.light
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _currentThemeMode = ThemeMode.light);
                widget.onThemeChanged?.call('light');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(AppLocale.text(_currentLanguage, 'Dark Mode', 'डार्क मोड')),
              trailing: _currentThemeMode == ThemeMode.dark
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _currentThemeMode = ThemeMode.dark);
                widget.onThemeChanged?.call('dark');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocale.text(
            _currentLanguage,
            'Application Language',
            'एप्लिकेशन की भाषा',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English (Default)'),
              trailing: _currentLanguage == 'English'
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _currentLanguage = 'English');
                widget.onLanguageChanged?.call('English');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('हिंदी (Hindi)'),
              trailing: _currentLanguage == 'Hindi'
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _currentLanguage = 'Hindi');
                widget.onLanguageChanged?.call('Hindi');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.text(_currentLanguage, 'Clear All Data', 'सभी डेटा साफ़ करें')),
        content: Text(
          AppLocale.text(
            _currentLanguage,
            'This will permanently delete all stored documents and history. Are you sure?',
            'यह सभी सहेजे गए दस्तावेज़ों और इतिहास को हमेशा के लिए हटा देगा। क्या आप सुनिश्चित हैं?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocale.text(_currentLanguage, 'Cancel', 'रद्द करें')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocale.text(_currentLanguage, 'Delete All', 'सब हटाएं')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocale.text(
                _currentLanguage,
                'All data cleared ✓',
                'सभी डेटा साफ़ कर दिया गया ✓',
              ),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
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
                _currentLanguage,
                'LIKH AI is an intelligent handwriting digitization application that converts messy and handwritten notes into clean, editable digital text and downloadable professional PDFs.',
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
            child: Text(AppLocale.text(_currentLanguage, 'Close', 'बंद करें')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.text(_currentLanguage, 'Settings', 'सेटिंग्स')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ---------------------------------------------
              // Section 1: Appearance
              // ---------------------------------------------
              Text(
                AppLocale.text(_currentLanguage, 'Appearance', 'दिखावट'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                      title: Text(AppLocale.text(_currentLanguage, 'Theme Mode', 'थीम मोड')),
                      subtitle: Text(
                        _currentThemeMode == ThemeMode.dark
                            ? AppLocale.text(_currentLanguage, 'Dark Mode', 'डार्क मोड')
                            : _currentThemeMode == ThemeMode.light
                                ? AppLocale.text(_currentLanguage, 'Light Mode', 'लाइट मोड')
                                : AppLocale.text(_currentLanguage, 'System Default', 'सिस्टम डिफ़ॉल्ट'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: _showAppearanceDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                      title: Text(AppLocale.text(_currentLanguage, 'Language', 'भाषा')),
                      subtitle: Text(_currentLanguage, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: _showLanguageDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------------------------------------------
              // Section 2: Documents & Digitization
              // ---------------------------------------------
              Text(
                AppLocale.text(_currentLanguage, 'Documents', 'दस्तावेज़'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        AppLocale.text(_currentLanguage, 'Auto-save documents', 'दस्तावेज़ स्वतः सहेजें'),
                      ),
                      subtitle: Text(
                        AppLocale.text(
                          _currentLanguage,
                          'Automatically store documents after digitization',
                          'डिजिटलीकरण के बाद दस्तावेज़ों को स्वतः सहेजें',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _autoSave,
                      onChanged: (val) {
                        setState(() => _autoSave = val);
                        StorageService.setAutoSave(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        AppLocale.text(
                          _currentLanguage,
                          'AI Suggestions & Cleanup',
                          'AI सुझाव और सुधार',
                        ),
                      ),
                      subtitle: Text(
                        AppLocale.text(
                          _currentLanguage,
                          'Apply AI handwriting correction and formatting',
                          'AI लिखावट सुधार और स्वरूपण लागू करें',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _aiSuggestions,
                      onChanged: (val) {
                        setState(() => _aiSuggestions = val);
                        StorageService.setAiSuggestions(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------------------------------------------
              // Section 3: Storage & Privacy
              // ---------------------------------------------
              Text(
                AppLocale.text(_currentLanguage, 'Storage & Privacy', 'भंडारण और गोपनीयता'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.security_rounded, color: AppColors.success),
                      title: Text(
                        AppLocale.text(_currentLanguage, 'Local Storage', 'स्थानीय भंडारण'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        AppLocale.text(
                          _currentLanguage,
                          'All digitized notes and documents are stored securely on your device',
                          'सभी डिजिटाइज़ किए गए नोट्स और दस्तावेज़ आपके डिवाइस पर सुरक्षित रूप से संग्रहीत हैं',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                      title: Text(
                        AppLocale.text(_currentLanguage, 'Clear All Local Data', 'सभी स्थानीय डेटा साफ़ करें'),
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        AppLocale.text(
                          _currentLanguage,
                          'Permanently delete saved documents and image files',
                          'सहेजे गए दस्तावेज़ों और छवियों को स्थायी रूप से हटाएं',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: _clearAllData,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------------------------------------------
              // Section 4: About
              // ---------------------------------------------
              Text(
                AppLocale.text(_currentLanguage, 'About', 'के बारे में'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      title: const Text('LIKH AI', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        AppLocale.text(
                          _currentLanguage,
                          '“Your handwriting. Digitized.” • Version 1.0.0',
                          '“आपकी लिखावट। डिजिटाइज़्ड।” • संस्करण 1.0.0',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: _showAboutDialog,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
