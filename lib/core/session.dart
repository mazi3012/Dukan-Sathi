import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Google Sign-In client
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  String? _userId;
  String? _userName;
  String? _shopId;
  String? _shopName;
  bool _emailVerified = true; // default true if not using email verification
  bool _isLoading = true;

  String? get userId => _userId;
  String? get userName => _userName;
  String? get shopId => _shopId;
  String? get shopName => _shopName;
  bool get isLoggedIn => _userId != null;
  bool get hasShop => _shopId != null;
  bool get emailVerified => _emailVerified;
  bool get isLoading => _isLoading;

  Future<void> _fetchAndPersistShop(String userId) async {
    try {
      // Accept ANY shop, regardless of onboarding_completed status
      // This allows both Telegram-onboarded and form-onboarded users to proceed
      final shopResult = await supabase
          .from('shops')
          .select('id, name')
          .eq('owner_id', userId)
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

  /// Login with Google OAuth using Supabase integration.
  /// On web: Not yet fully supported - returning error message
  /// On mobile: Uses google_sign_in package with ID tokens
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Web platform: Not yet fully supported
      if (kIsWeb) {
        debugPrint('[Session] Web platform detected');
        return {'success': false, 'error': 'Google sign-in on web requires additional setup. Please use the mobile app or contact support.'};
      }
      
      // Mobile platform: Use google_sign_in package with tokens
      debugPrint('[Session] Mobile platform detected - using google_sign_in with tokens');
      // Sign out first to ensure fresh login
      await _googleSignIn.signOut();
      
      // Start Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[Session] Google sign-in cancelled by user');
        return {'success': false, 'error': 'Google sign-in cancelled'};
      }

      debugPrint('[Session] googleUser: ${googleUser.email} id:${googleUser.id}');

      // Get Google authentication details
      final googleAuth = await googleUser.authentication;
      debugPrint('[Session] googleAuth object: $googleAuth');
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      debugPrint('[Session] googleAuth.idToken: ${idToken?.substring(0, 20)}...');
      debugPrint('[Session] googleAuth.accessToken: ${accessToken?.substring(0, 20)}...');
      debugPrint('[Session] googleAuth tokens: hasId=${idToken!=null && idToken.isNotEmpty} hasAccess=${accessToken!=null && accessToken.isNotEmpty}');
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('[Session] ERROR: accessToken is null or empty');
        return {'success': false, 'error': 'Failed to get Google authentication tokens (no access token)'};
      }
      if (idToken == null || idToken.isEmpty) {
        debugPrint('[Session] ERROR: idToken is null or empty');
        return {'success': false, 'error': 'Failed to get Google authentication tokens (no ID token)'};
      }

      // Sign in with Supabase using Google provider (mobile only)
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final respUser = response.user;
      debugPrint('[Session] supabase response.user: ${respUser?.id}');
      if (respUser == null) {
        debugPrint('[Session] Supabase response.user is null');
        return {'success': false, 'error': 'Failed to authenticate with Supabase'};
      }

      final userId = respUser.id;
      final userEmail = respUser.email ?? googleUser.email;
      final userName = googleUser.displayName ?? googleUser.email;

      // Upsert user record in public users table with full_name
      await supabase.from('users').upsert({
        'id': userId,
        'email': userEmail,
        'full_name': userName,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Fetch user's shop if exists
      final shopResult = await supabase
          .from('shops')
          .select('id, name')
          .eq('owner_id', userId)
          .maybeSingle();

      _userId = userId;
      _userName = userName;
      _shopId = shopResult?['id'] as String?;
      _shopName = shopResult?['name'] as String?;
      _emailVerified = respUser.emailConfirmedAt != null || true; // Google users are pre-verified

      // Persist to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userNameKey, userName);
      if (_shopId != null) await prefs.setString(_shopIdKey, _shopId!);
      if (_shopName != null) await prefs.setString(_shopNameKey, _shopName!);

      notifyListeners();
      return {'success': true};
    } catch (e, stack) {
      debugPrint('[Session] Google login error: $e\n$stack');
      String msg = e.toString();
      if (msg.contains('PlatformException')) {
        msg = 'Failed to sign in with Google. Please try again.';
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
    _emailVerified = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_shopIdKey);
    await prefs.remove(_shopNameKey);
  }

  /// Mark the current user's email as verified and notify listeners.
  /// Use this when handling deep-link callbacks from verification emails.
  void markEmailVerified() {
    _emailVerified = true;
    notifyListeners();
  }
}

