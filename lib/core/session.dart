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

  Future<void> _fetchAndPersistShop(String userId) async {
    try {
      final shopResult = await supabase
          .from('shops')
          .select('id, name')
          .eq('owner_id', userId)
          .eq('onboarding_completed', true)
          .maybeSingle();

      if (shopResult != null) {
        _shopId = shopResult['id'] as String?;
        _shopName = shopResult['name'] as String?;

        final prefs = await SharedPreferences.getInstance();
        if (_shopId != null) await prefs.setString(_shopIdKey, _shopId!);
        if (_shopName != null) await prefs.setString(_shopNameKey, _shopName!);
      }
    } catch (e) {
      debugPrint('[Session] Fetch shop error: $e');
    }
  }

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

      if (_userId != null) {
        // Always try to refresh shop info if we have a user but no shop ID locally
        // or just to ensure the session is still valid.
        if (supabase.auth.currentUser == null) {
          // If Supabase session is gone, we might need to re-auth or clear
          // but we'll try to keep the userId if it's still valid in the eyes of the app
          // Actually, if currentUser is null, we should probably clear.
          await _clearLocal();
        } else if (_shopId == null) {
          await _fetchAndPersistShop(_userId!);
        }
      }
    } catch (e) {
      debugPrint('[Session] init error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with Supabase Email & Password.
  /// Uses raw HTTP to pre-check for errors the SDK doesn't handle gracefully.
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    try {
      // Pre-check with raw HTTP to catch errors that crash the SDK
      final rawResponse = await http.post(
        Uri.parse('$resolvedSupabaseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': resolvedSupabaseAnonKey,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (rawResponse.statusCode == 429) {
        return {'success': false, 'error': 'Too many login attempts. Please wait a few minutes and try again.'};
      }

      if (rawResponse.statusCode == 400) {
        final body = jsonDecode(rawResponse.body);
        final errorCode = body['error_code'] ?? '';
        final errorMsg = body['msg'] ?? body['error_description'] ?? 'Invalid credentials';
        
        if (errorCode == 'email_not_confirmed' || errorMsg.toString().contains('Email not confirmed')) {
          return {'success': false, 'error': 'Please check your email and confirm your account before logging in.'};
        }
        return {'success': false, 'error': errorMsg};
      }

      if (rawResponse.statusCode != 200) {
        final body = jsonDecode(rawResponse.body);
        return {'success': false, 'error': body['msg'] ?? 'Login failed (${rawResponse.statusCode})'};
      }

      // Parse the successful login response
      final body = jsonDecode(rawResponse.body) as Map<String, dynamic>;
      final user = body['user'] as Map<String, dynamic>?;
      
      if (user == null) {
        return {'success': false, 'error': 'Login failed: No user returned'};
      }

      final userId = user['id'] as String;
      final accessToken = body['access_token'] as String;
      final refreshToken = body['refresh_token'] as String;

      // Set session in the Supabase client so subsequent queries work
      await supabase.auth.setSession(refreshToken);

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
      await prefs.setString(_userIdKey, userId);
      if (_userName != null) await prefs.setString(_userNameKey, _userName!);
      if (_shopId != null) await prefs.setString(_shopIdKey, _shopId!);
      if (_shopName != null) await prefs.setString(_shopNameKey, _shopName!);

      notifyListeners();
      return {'success': true};
    } catch (e, stack) {
      debugPrint('[Session] login error: $e\n$stack');
      String msg = e.toString();
      if (msg.contains('Null check')) {
        msg = 'Login service is temporarily unavailable. Please try again in a few minutes.';
      } else {
        msg = msg.replaceAll('Exception: ', '');
        if (msg.contains('Email not confirmed')) {
          msg = 'Please check your email and confirm your account before logging in.';
        }
      }
      return {'success': false, 'error': msg};
    }
  }

  /// Register a new user with Email & Password.
  /// Uses raw HTTP as a fallback because the gotrue SDK crashes on non-200
  /// responses (e.g. 429 rate limit) with "Null check operator used on a null value".
  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    try {
      // First try raw HTTP to check for rate limits and other errors
      // that the SDK doesn't handle gracefully.
      final rawResponse = await http.post(
        Uri.parse('$resolvedSupabaseUrl/auth/v1/signup'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': resolvedSupabaseAnonKey,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'data': {'full_name': fullName},
          'redirect_to': kIsWeb ? Uri.base.origin : null,
        }),
      );

      if (rawResponse.statusCode == 429) {
        return {'success': false, 'error': 'Too many signup attempts. Please wait a few minutes and try again.'};
      }

      if (rawResponse.statusCode == 422) {
        return {'success': false, 'error': 'This email is already registered. Try signing in instead.'};
      }

      if (rawResponse.statusCode != 200) {
        final body = jsonDecode(rawResponse.body);
        final msg = body['msg'] ?? body['message'] ?? body['error_description'] ?? 'Registration failed (${rawResponse.statusCode})';
        return {'success': false, 'error': msg};
      }

      // Parse the successful response
      final body = jsonDecode(rawResponse.body) as Map<String, dynamic>;
      final userId = body['id'] as String?;

      if (userId != null) {
        // Check if email confirmation is required (no access_token means confirmation needed)
        final hasSession = body['access_token'] != null;
        
        if (hasSession) {
          _userId = userId;
          _userName = fullName;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userIdKey, userId);
          await prefs.setString(_userNameKey, fullName);
          
          notifyListeners();
        }
        
        return {
          'success': true,
          'needsConfirmation': !hasSession,
        };
      } else {
        return {'success': false, 'error': 'Registration failed: No user returned'};
      }
    } catch (e, stack) {
      debugPrint('[Session] register error: $e\n$stack');
      String msg = e.toString();
      if (msg.contains('Null check')) {
        msg = 'Registration service is temporarily unavailable. Please try again in a few minutes.';
      } else {
        msg = msg.replaceAll('Exception: ', '');
      }
      return {'success': false, 'error': msg};
    }
  }

  /// Create a new shop for the user
  Future<Map<String, dynamic>> createShop({
    required String name,
    required String state,
    required String businessType,
    String? gstNumber,
    String gstMode = 'UNREGISTERED',
    String? upiId,
  }) async {
    if (_userId == null) return {'success': false, 'error': 'No user logged in'};

    try {
      final result = await supabase.from('shops').insert({
        'owner_id': _userId,
        'name': name,
        'state': state,
        'business_type': businessType,
        'gst_registration_number': gstNumber,
        'gst_mode': gstMode,
        'upi_id': upiId,
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

