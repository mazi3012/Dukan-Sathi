import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserSession extends ChangeNotifier {
  static final UserSession _instance = UserSession._();
  factory UserSession() => _instance;
  UserSession._();

  static const String _baseUrl = String.fromEnvironment('API_URL', defaultValue: '');
  static const String _userIdKey = 'ds_user_id';
  static const String _userNameKey = 'ds_user_name';
  static const String _shopIdKey = 'ds_shop_id';
  static const String _shopNameKey = 'ds_shop_name';

  String? _userId;
  String? _userName;
  String? _shopId;
  String? _shopName;
  bool _isLoading = true;

  String? get userId => _userId;
  String? get userName => _userName;
  String? get shopId => _shopId;
  String? get shopName => _shopName;
  bool get isLoggedIn => _userId != null && _shopId != null;
  bool get isLoading => _isLoading;

  /// Initialize session from local storage on app start.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(_userIdKey);
      _userName = prefs.getString(_userNameKey);
      _shopId = prefs.getString(_shopIdKey);
      _shopName = prefs.getString(_shopNameKey);

      // Validate session with backend if we have a userId
      if (_userId != null) {
        final valid = await _validateSession(_userId!);
        if (!valid) {
          await _clearLocal();
        }
      }
    } catch (e) {
      debugPrint('[Session] init error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Verify login code and establish session.
  Future<Map<String, dynamic>> verifyCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'] as Map<String, dynamic>;
        final shop = data['shop'] as Map<String, dynamic>?;

        _userId = user['id'] as String;
        _userName = user['full_name'] as String?;
        _shopId = shop?['id'] as String?;
        _shopName = shop?['name'] as String?;

        // Persist to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userIdKey, _userId!);
        if (_userName != null) await prefs.setString(_userNameKey, _userName!);
        if (_shopId != null) await prefs.setString(_shopIdKey, _shopId!);
        if (_shopName != null) await prefs.setString(_shopNameKey, _shopName!);

        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Verification failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Validate an existing session with the backend.
  Future<bool> _validateSession(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/session?userId=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          // Refresh shop info
          final shop = data['shop'] as Map<String, dynamic>?;
          if (shop != null) {
            _shopId = shop['id'] as String?;
            _shopName = shop['name'] as String?;
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      // If server is down, keep local session (offline-capable)
      debugPrint('[Session] validate error (keeping local): $e');
      return _userId != null;
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    await _clearLocal();
    notifyListeners();
  }

  Future<void> _clearLocal() async {
    _userId = null;
    _userName = null;
    _shopId = null;
    _shopName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_shopIdKey);
    await prefs.remove(_shopNameKey);
  }
}
