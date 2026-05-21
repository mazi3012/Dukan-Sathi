import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database.dart'; // Import supabase client
import 'package:dukansathi_new/data/repositories/product_repository.dart';
import 'package:dukansathi_new/data/repositories/customer_repository.dart';
import 'package:dukansathi_new/data/repositories/sale_repository.dart';
import 'package:dukansathi_new/models/shop_config.dart';

class UserSession extends ChangeNotifier {
  static final UserSession _instance = UserSession._();
  factory UserSession() => _instance;
  UserSession._();

  static const String _baseUrl = String.fromEnvironment('API_URL', defaultValue: '');
  static const String _userIdKey = 'ds_user_id';
  static const String _userNameKey = 'ds_user_name';
  static const String _shopIdKey = 'ds_shop_id';
  static const String _shopNameKey = 'ds_shop_name';
  static const String _shopStateKey = 'ds_shop_state';
  static const String _shopGstModeKey = 'ds_shop_gst_mode';
  static const String _shopGstNumKey = 'ds_shop_gst_num';
  static const String _shopBusinessTypeKey = 'ds_shop_business_type';

  // Google Sign-In client
  late GoogleSignIn _googleSignIn;

  UserSession._internal() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? '648987320349-asplif3bmr9ai0k3lkp9ulth5gne9eru.apps.googleusercontent.com' : null,
      scopes: [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
    );
  }

  String? _userId;
  String? _userName;
  String? _shopId;
  String? _shopName;
  String? _shopState;
  String? _shopGstMode;
  String? _shopGstNum;
  String? _shopBusinessType;
  bool _emailVerified = true; // default true if not using email verification
  bool _isLoading = true;

  String? get userId => _userId;
  String? get userName => _userName;
  String? get shopId => _shopId;
  String? get shopName => _shopName;
  String? get shopState => _shopState;
  String? get shopGstMode => _shopGstMode;
  String? get shopGstNum => _shopGstNum;
  String? get shopBusinessType => _shopBusinessType;
  bool get isLoggedIn => _userId != null;
  bool get hasShop => _shopId != null;
  bool get emailVerified => _emailVerified;
  bool get isLoading => _isLoading;

  ShopConfig get shopConfig {
    final modeStr = _shopGstMode ?? 'UNREGISTERED';
    final gstMode = GSTMode.values.firstWhere(
      (e) => e.name == modeStr.toLowerCase(),
      orElse: () => GSTMode.unregistered,
    );
    return ShopConfig(
      shopId: _shopId ?? 'default',
      state: _shopState ?? 'DL',
      gstRegistrationNumber: _shopGstNum,
      gstMode: gstMode,
      businessType: _shopBusinessType ?? 'Retail',
      createdAt: DateTime.now(),
    );
  }

  Future<void> _fetchAndPersistShop(String userId) async {
    try {
      // Accept ANY shop, regardless of onboarding_completed status
      // This allows both Telegram-onboarded and form-onboarded users to proceed
      final shopResult = await supabase
          .from('shops')
          .select('id, name, state, gst_mode, gst_registration_number, business_type')
          .eq('owner_id', userId)
          .maybeSingle();

      if (shopResult != null) {
        _shopId = shopResult['id'] as String?;
        _shopName = shopResult['name'] as String?;
        _shopState = shopResult['state'] as String?;
        _shopGstMode = shopResult['gst_mode'] as String?;
        _shopGstNum = shopResult['gst_registration_number'] as String?;
        _shopBusinessType = shopResult['business_type'] as String?;

        final prefs = await SharedPreferences.getInstance();
        if (_shopId != null) await prefs.setString(_shopIdKey, _shopId!);
        if (_shopName != null) await prefs.setString(_shopNameKey, _shopName!);
        if (_shopState != null) await prefs.setString(_shopStateKey, _shopState!);
        if (_shopGstMode != null) await prefs.setString(_shopGstModeKey, _shopGstMode!);
        if (_shopGstNum != null) await prefs.setString(_shopGstNumKey, _shopGstNum!);
        if (_shopBusinessType != null) await prefs.setString(_shopBusinessTypeKey, _shopBusinessType!);
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
      // On web, wait a brief moment for Supabase to recover the session from the URL fragment/cookie
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(_userIdKey);
      _userName = prefs.getString(_userNameKey);
      _shopId = prefs.getString(_shopIdKey);
      _shopName = prefs.getString(_shopNameKey);
      _shopState = prefs.getString(_shopStateKey);
      _shopGstMode = prefs.getString(_shopGstModeKey);
      _shopGstNum = prefs.getString(_shopGstNumKey);
      _shopBusinessType = prefs.getString(_shopBusinessTypeKey);

      final currentSupabaseUser = supabase.auth.currentUser;
      
      if (currentSupabaseUser != null) {
        // We have a valid Supabase session (possibly just recovered from OAuth redirect)
        _userId = currentSupabaseUser.id;
        _userName = currentSupabaseUser.userMetadata?['full_name'] ?? currentSupabaseUser.email;
        
        // Ensure local storage is in sync
        await prefs.setString(_userIdKey, _userId!);
        if (_userName != null) await prefs.setString(_userNameKey, _userName!);
        
        if (_shopId == null) {
          await _fetchAndPersistShop(_userId!);
        }
        if (_shopId != null) {
          triggerCacheWarmup();
        }
      } else if (_userId != null) {
        // We have local data but no Supabase session - this is an invalid state
        await _clearLocal();
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
      debugPrint('[Session] Starting Google Sign-In flow (isWeb: $kIsWeb)');
      
      if (kIsWeb) {
        debugPrint('[Session] Web platform detected - using signInWithOAuth redirect');
        
        // Use the current origin for redirect back to ensure it works on localhost or production
        final String redirectTo = Uri.base.origin;
        debugPrint('[Session] Web redirect URL: $redirectTo');

        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectTo,
        );
        
        // The page will redirect, so we return success.
        return {'success': true, 'note': 'Redirecting to Google...'};
      }

      // Mobile platform: Use google_sign_in package with tokens
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[Session] Google sign-in cancelled by user');
        return {'success': false, 'error': 'Google sign-in cancelled'};
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null || idToken.isEmpty) {
        return {'success': false, 'error': 'Failed to get Google authentication tokens'};
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
          .select('id, name, state, gst_mode, gst_registration_number, business_type')
          .eq('owner_id', userId)
          .maybeSingle();

      _userId = userId;
      _userName = userName;
      _shopId = shopResult?['id'] as String?;
      _shopName = shopResult?['name'] as String?;
      _shopState = shopResult?['state'] as String?;
      _shopGstMode = shopResult?['gst_mode'] as String?;
      _shopGstNum = shopResult?['gst_registration_number'] as String?;
      _shopBusinessType = shopResult?['business_type'] as String?;
      _emailVerified = respUser.emailConfirmedAt != null || true; // Google users are pre-verified

      // Persist to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userNameKey, userName);
      if (_shopId != null) await prefs.setString(_shopIdKey, _shopId!);
      if (_shopName != null) await prefs.setString(_shopNameKey, _shopName!);
      if (_shopState != null) await prefs.setString(_shopStateKey, _shopState!);
      if (_shopGstMode != null) await prefs.setString(_shopGstModeKey, _shopGstMode!);
      if (_shopGstNum != null) await prefs.setString(_shopGstNumKey, _shopGstNum!);
      if (_shopBusinessType != null) await prefs.setString(_shopBusinessTypeKey, _shopBusinessType!);

      if (_shopId != null) {
        triggerCacheWarmup();
      }

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
      _shopState = result['state'] as String?;
      _shopGstMode = result['gst_mode'] as String?;
      _shopGstNum = result['gst_registration_number'] as String?;
      _shopBusinessType = result['business_type'] as String?;

      if (_shopId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_shopIdKey, _shopId!);
        if (_shopName != null) await prefs.setString(_shopNameKey, _shopName!);
        if (_shopState != null) await prefs.setString(_shopStateKey, _shopState!);
        if (_shopGstMode != null) await prefs.setString(_shopGstModeKey, _shopGstMode!);
        if (_shopGstNum != null) await prefs.setString(_shopGstNumKey, _shopGstNum!);
        if (_shopBusinessType != null) await prefs.setString(_shopBusinessTypeKey, _shopBusinessType!);
      }

      if (_shopId != null) {
        triggerCacheWarmup();
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
    _shopState = null;
    _shopGstMode = null;
    _shopGstNum = null;
    _shopBusinessType = null;
    _emailVerified = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_shopIdKey);
    await prefs.remove(_shopNameKey);
    await prefs.remove(_shopStateKey);
    await prefs.remove(_shopGstModeKey);
    await prefs.remove(_shopGstNumKey);
    await prefs.remove(_shopBusinessTypeKey);
  }

  /// Mark the current user's email as verified and notify listeners.
  /// Use this when handling deep-link callbacks from verification emails.
  void markEmailVerified() {
    _emailVerified = true;
    notifyListeners();
  }

  /// Triggers a background cache warmup from Supabase to SQFlite for products, customers, and sales.
  void triggerCacheWarmup() {
    if (_shopId != null) {
      Future.microtask(() async {
        try {
          debugPrint('[CacheWarmup] Warming up caches for shop $_shopId...');
          await ProductRepository().syncProductsFromCloud(_shopId!);
          await CustomerRepository().syncCustomersFromCloud(_shopId!);
          await SaleRepository().syncSalesFromCloud(_shopId!);
          debugPrint('[CacheWarmup] Caches warmed successfully!');
        } catch (e) {
          debugPrint('[CacheWarmup] Warmup failed: $e');
        }
      });
    }
  }
}


