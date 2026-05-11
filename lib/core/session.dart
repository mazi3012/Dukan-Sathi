import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart'; // Import supabase client

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
  bool get isLoggedIn => _userId != null;
  bool get hasShop => _shopId != null;
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

      // We still want to ensure we have a valid Supabase session
      if (_userId != null && supabase.auth.currentSession == null) {
        // If local state exists but Supabase session is gone, we might need to re-auth or clear
        // For now, we trust the local state if Supabase has a user (which it usually does if logged in)
        if (supabase.auth.currentUser == null) {
          await _clearLocal();
        }
      }
    } catch (e) {
      debugPrint('[Session] init error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with Supabase Email & Password
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;
        
        // Fetch additional info from our public tables
        final userResult = await supabase
            .from('users')
            .select('full_name')
            .eq('id', userId)
            .maybeSingle();
            
        final shopResult = await supabase
            .from('shops')
            .select('id, name')
            .eq('owner_id', userId)
            .eq('onboarding_completed', true)
            .maybeSingle();

        _userId = userId;
        _userName = userResult?['full_name'] as String?;
        _shopId = shopResult?['id'] as String?;
        _shopName = shopResult?['name'] as String?;

        // Persist to local storage
        final prefs = await SharedPreferences.getInstance();
        if (_userId != null) await prefs.setString(_userIdKey, _userId!);
        if (_userName != null) await prefs.setString(_userNameKey, _userName!);
        if (_shopId != null) await prefs.setString(_shopIdKey, _shopId!);
        if (_shopName != null) await prefs.setString(_shopNameKey, _shopName!);

        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Login failed'};
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('Email not confirmed')) {
        msg = 'Please check your email and confirm your account before logging in.';
      }
      return {'success': false, 'error': msg};
    }
  }

  /// Register a new user with Email & Password
  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        final userId = response.user!.id;
        if (response.session != null) {
          _userId = userId;
          _userName = fullName;
          
          // Persist registration session if immediate login is allowed
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userIdKey, userId);
          await prefs.setString(_userNameKey, fullName);
          
          notifyListeners();
        }
        
        return {
          'success': true, 
          'needsConfirmation': response.session == null,
        };
      } else {
        return {'success': false, 'error': 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString().replaceAll('Exception: ', '')};
    }
  }

  /// Create a new shop for the user
  Future<Map<String, dynamic>> createShop(String name, String state, String businessType) async {
    if (_userId == null) return {'success': false, 'error': 'No user logged in'};

    try {
      final result = await supabase.from('shops').insert({
        'owner_id': _userId,
        'name': name,
        'state': state,
        'business_type': businessType,
        'onboarding_completed': true,
      }).select().single();

      _shopId = result['id'] as String?;
      _shopName = result['name'] as String?;

      if (_shopId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_shopIdKey, _shopId!);
        if (_shopName != null) {
          await prefs.setString(_shopNameKey, _shopName!);
        }
      }

      notifyListeners();
      return {'success': true};
    } catch (e) {
      debugPrint('[Session] createShop error: $e');
      return {'success': false, 'error': e.toString().replaceAll('Exception: ', '')};
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    await supabase.auth.signOut();
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

