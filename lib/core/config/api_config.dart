import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String prefKey = 'custom_api_base_url';

  /// Compile-time configuration via `--dart-define=API_BASE_URL=http://...`
  static const String envUrl = String.fromEnvironment('API_BASE_URL');

  /// Development host IP for physical Android device on the local Wi-Fi network
  static const String devLanIp = '192.168.31.57';

  /// Standard Android emulator host loopback mapping
  static const String devEmulatorIp = '10.0.2.2';

  /// In-memory cache for resolved base URL during the active app session
  static String? _cachedResolvedUrl;

  /// Default fallback URL based on platform
  static String get defaultBaseUrl {
    if (envUrl.isNotEmpty) {
      return envUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Default to LAN IP for physical device or emulator mapping
      return 'http://$devLanIp:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Resolves the fastest working backend URL with automatic candidate probing
  static Future<String> getBaseUrl() async {
    // 1. If custom URL explicitly saved in SharedPreferences, respect it
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(prefKey);
      if (custom != null && custom.trim().isNotEmpty) {
        return custom.trim().replaceAll(RegExp(r'/+$'), '');
      }
    } catch (_) {}

    // 2. If compile-time environment variable provided, respect it
    if (envUrl.isNotEmpty) {
      return envUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }

    // 3. Return session-cached resolved URL if available
    if (_cachedResolvedUrl != null) {
      return _cachedResolvedUrl!;
    }

    // 4. For non-Android platforms, localhost is standard
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _cachedResolvedUrl = 'http://127.0.0.1:8000';
      return _cachedResolvedUrl!;
    }

    // 5. On Android: Probe physical Wi-Fi LAN and reverse-tunneled localhost first
    final candidates = [
      'http://$devLanIp:8000',      // Physical device Wi-Fi LAN
      'http://127.0.0.1:8000',      // Reverse-tunneled ADB host port
      'http://$devEmulatorIp:8000', // Android emulator loopback (10.0.2.2)
      'http://10.0.3.2:8000',       // Genymotion
    ];

    try {
      final completer = Completer<String>();
      int failures = 0;

      for (final candidate in candidates) {
        testConnection(candidate).then((isAlive) {
          if (isAlive && !completer.isCompleted) {
            completer.complete(candidate);
          } else {
            failures++;
            if (failures == candidates.length && !completer.isCompleted) {
              completer.complete('http://$devLanIp:8000');
            }
          }
        }).catchError((_) {
          failures++;
          if (failures == candidates.length && !completer.isCompleted) {
            completer.complete('http://$devLanIp:8000');
          }
        });
      }

      // Allow maximum 1200ms for parallel probe; fallback immediately if slow
      final resolved = await completer.future.timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () => 'http://$devLanIp:8000',
      );

      _cachedResolvedUrl = resolved;
      if (kDebugMode) {
        print('[ApiConfig] Auto-resolved active backend URL: $resolved');
      }
      return resolved;
    } catch (_) {
      _cachedResolvedUrl = 'http://$devLanIp:8000';
      return _cachedResolvedUrl!;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    _cachedResolvedUrl = clean;
    await prefs.setString(prefKey, clean);
  }

  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedResolvedUrl = null;
    await prefs.remove(prefKey);
  }

  static Future<bool> testConnection([String? testUrl]) async {
    try {
      final base = testUrl ?? await getBaseUrl();
      final uri = Uri.parse('$base/health');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 900));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
