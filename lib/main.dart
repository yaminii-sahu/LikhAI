import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/localization.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'widgets/likh_logo.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-load documents from local storage into memory cache
  await StorageService.getDocuments();
  // Restore user authentication session
  await AuthService.init();

  runApp(const LikhAIApp());
}

class LikhAIApp extends StatefulWidget {
  const LikhAIApp({super.key});

  @override
  State<LikhAIApp> createState() => _LikhAIAppState();
}

class _LikhAIAppState extends State<LikhAIApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final themeStr = await StorageService.getThemeMode();
    final langStr = await StorageService.getLanguage();

    if (mounted) {
      setState(() {
        _language = langStr;
        _themeMode = themeStr == 'dark'
            ? ThemeMode.dark
            : themeStr == 'light'
                ? ThemeMode.light
                : ThemeMode.system;
      });
    }
  }

  Future<void> _changeTheme(String mode) async {
    await StorageService.setThemeMode(mode);
    setState(() {
      _themeMode = mode == 'dark'
          ? ThemeMode.dark
          : mode == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
    });
  }

  Future<void> _changeLanguage(String lang) async {
    await StorageService.setLanguage(lang);
    setState(() {
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LIKH AI',
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: SplashScreen(
        nextScreen: MainNavigationHost(
          language: _language,
          themeMode: _themeMode,
          onThemeChanged: _changeTheme,
          onLanguageChanged: _changeLanguage,
        ),
      ),
    );
  }
}

class MainNavigationHost extends StatefulWidget {
  final String language;
  final ThemeMode themeMode;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const MainNavigationHost({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<MainNavigationHost> createState() => _MainNavigationHostState();
}

class _MainNavigationHostState extends State<MainNavigationHost> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(language: widget.language),
      DocumentsScreen(language: widget.language),
      HistoryScreen(language: widget.language),
      ProfileScreen(
        language: widget.language,
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final isDesktop = constraints.maxWidth >= 1024;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  extended: isDesktop,
                  minExtendedWidth: 220,
                  onDestinationSelected: (idx) {
                    setState(() {
                      _currentIndex = idx;
                    });
                  },
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
                    child: isDesktop
                        ? const LikhBrandLogo(
                            markSize: 38,
                            fontSize: 18,
                            isVertical: false,
                            showTagline: true,
                            tagline: 'Your handwriting. Digitized.',
                          )
                        : const LikhLogoMark(size: 38),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: Text(AppLocale.text(widget.language, 'Home', 'होम')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.description_outlined),
                      selectedIcon: const Icon(Icons.description_rounded),
                      label: Text(AppLocale.text(widget.language, 'Documents', 'दस्तावेज़')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.history_outlined),
                      selectedIcon: const Icon(Icons.history_rounded),
                      label: Text(AppLocale.text(widget.language, 'History', 'इतिहास')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: const Icon(Icons.person_rounded),
                      label: Text(AppLocale.text(widget.language, 'Profile', 'प्रोफ़ाइल')),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: IndexedStack(
                        index: _currentIndex,
                        children: pages,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile layout (< 640px)
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: AppLocale.text(widget.language, 'Home', 'होम'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.description_outlined),
                selectedIcon: const Icon(Icons.description_rounded),
                label: AppLocale.text(widget.language, 'Documents', 'दस्तावेज़'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history_rounded),
                label: AppLocale.text(widget.language, 'History', 'इतिहास'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: AppLocale.text(widget.language, 'Profile', 'प्रोफ़ाइल'),
              ),
            ],
          ),
        );
      },
    );
  }
}