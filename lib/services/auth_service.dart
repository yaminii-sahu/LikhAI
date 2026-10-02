import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/config/api_config.dart';

class AuthService {
  static const String _userKey = 'likh_ai_current_user_v1';
  static const String _tokenKey = 'likh_ai_auth_token_v1';
  static const String _localAccountsKey = 'likh_ai_local_accounts_v1';

  static UserModel? _currentUser;
  static String? _authToken;

  /// Notifier allowing screens to react immediately when login/logout occurs
  static final ValueNotifier<UserModel?> authNotifier = ValueNotifier<UserModel?>(null);

  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;
  static String? get token => _authToken;

  /// Restores session on app launch
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final token = prefs.getString(_tokenKey);

    if (userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(map);
        _authToken = token;
        authNotifier.value = _currentUser;
      } catch (e) {
        debugPrint('[AuthService] Error restoring user: $e');
      }
    }
  }

  /// Sign In with Email & Password (calls FastAPI with local fallback if offline)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPw = password.trim();

    // 1. Try remote FastAPI server
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final uri = Uri.parse('$baseUrl/auth/login');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail, 'password': cleanPw}),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = UserModel.fromJson(data['user']);
        final token = data['token'] as String?;

        await _saveSession(user, token);
        return {'success': true, 'user': user};
      } else {
        final data = jsonDecode(res.body);
        return {
          'success': false,
          'message': data['detail'] ?? 'Invalid credentials.',
        };
      }
    } catch (_) {
      // 2. Offline fallback: check local accounts or demo account
      return await _loginOffline(cleanEmail, cleanPw);
    }
  }

  /// Sign Up / Register new account
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPw = password.trim();

    // 1. Try remote FastAPI server
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final uri = Uri.parse('$baseUrl/auth/register');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': cleanName,
              'email': cleanEmail,
              'password': cleanPw,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = UserModel.fromJson(data['user']);
        final token = data['token'] as String?;

        await _saveSession(user, token);
        await _saveLocalAccount(cleanEmail, cleanPw, cleanName);
        return {'success': true, 'user': user};
      } else {
        final data = jsonDecode(res.body);
        return {
          'success': false,
          'message': data['detail'] ?? 'Registration failed.',
        };
      }
    } catch (_) {
      // 2. Offline registration fallback
      final user = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName.isNotEmpty ? cleanName : 'LIKH AI User',
        email: cleanEmail,
        createdAt: DateTime.now(),
      );
      await _saveSession(user, 'tok_offline_${DateTime.now().millisecondsSinceEpoch}');
      await _saveLocalAccount(cleanEmail, cleanPw, cleanName);
      return {'success': true, 'user': user};
    }
  }

  /// Quick Demo Sign In
  static Future<Map<String, dynamic>> demoLogin() async {
    return await login(email: 'demo@likhai.com', password: 'likhai123');
  }

  /// Continue as Guest
  static Future<void> guestLogin() async {
    final guest = UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Guest User',
      email: 'guest@likhai.local',
      createdAt: DateTime.now(),
    );
    await _saveSession(guest, null);
  }

  /// Sign Out
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);

    _currentUser = null;
    _authToken = null;
    authNotifier.value = null;
  }

  static Future<void> _saveSession(UserModel user, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
    _currentUser = user;
    _authToken = token;
    authNotifier.value = user;
  }

  static Future<Map<String, dynamic>> _loginOffline(String email, String password) async {
    // Check built-in demo credentials
    if (email == 'demo@likhai.com' && password == 'likhai123') {
      final user = UserModel(
        id: 'usr_demo',
        name: 'Demo User',
        email: 'demo@likhai.com',
        createdAt: DateTime.now(),
      );
      await _saveSession(user, 'tok_demo');
      return {'success': true, 'user': user};
    }

    // Check stored local accounts
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localAccountsKey);
    if (raw != null) {
      final accounts = jsonDecode(raw) as Map<String, dynamic>;
      if (accounts.containsKey(email)) {
        final acc = accounts[email];
        if (acc['password'] == password) {
          final user = UserModel(
            id: acc['id'] ?? 'usr_local',
            name: acc['name'] ?? 'LIKH AI User',
            email: email,
            createdAt: DateTime.now(),
          );
          await _saveSession(user, 'tok_local');
          return {'success': true, 'user': user};
        }
      }
    }

    return {
      'success': false,
      'message': 'Invalid email or password. Use demo@likhai.com / likhai123 or register.',
    };
  }

  static Future<void> _saveLocalAccount(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localAccountsKey);
    Map<String, dynamic> accounts = {};
    if (raw != null) {
      try {
        accounts = jsonDecode(raw);
      } catch (_) {}
    }
    accounts[email] = {
      'id': 'usr_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'password': password,
    };
    await prefs.setString(_localAccountsKey, jsonEncode(accounts));
  }
}
