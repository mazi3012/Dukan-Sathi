import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database.dart'; // Import supabase client
import 'package:dukansathi_new/models/shop_config.dart';

import 'session/session_storage.dart';
import 'session/auth_service.dart';
import 'session/shop_service.dart';
import 'session/cache_warmup_service.dart';

class UserSession extends ChangeNotifier {
  static final UserSession _instance = UserSession._();
  factory UserSession() => _instance;
  
  UserSession._() {
    _storage = SessionStorage();
    _auth = AuthService();
    _shop = ShopService();
    _cache = CacheWarmupService();
  }

  late final SessionStorage _storage;
  late final AuthService _auth;
  late final ShopService _shop;
  late final CacheWarmupService _cache;

  String? _userId;
  String? _userName;
  String? _shopId;
  String? _shopName;
  String? _shopState;
  String? _shopGstMode;
  String? _shopGstNum;
  String? _shopBusinessType;
  bool _emailVerified = true;
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
      final shopResult = await _shop.fetchShop(userId);
      if (shopResult != null) {
        _shopId = shopResult['id'] as String?;
        _shopName = shopResult['name'] as String?;
        _shopState = shopResult['state'] as String?;
        _shopGstMode = shopResult['gst_mode'] as String?;
        _shopGstNum = shopResult['gst_registration_number'] as String?;
        _shopBusinessType = shopResult['business_type'] as String?;

        await _storage.saveShop(
          id: _shopId!,
          name: _shopName ?? 'My Shop',
          state: _shopState ?? 'DL',
          gstMode: _shopGstMode ?? 'UNREGISTERED',
          gstNum: _shopGstNum,
          businessType: _shopBusinessType ?? 'Retail',
        );
      }
    } catch (e) {
      debugPrint('[UserSession] Fetch shop error: $e');
    }
  }

  /// Initialize session from local storage on app start.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(SessionStorage.userIdKey);
      _userName = prefs.getString(SessionStorage.userNameKey);
      _shopId = prefs.getString(SessionStorage.shopIdKey);
      _shopName = prefs.getString(SessionStorage.shopNameKey);
      _shopState = prefs.getString(SessionStorage.shopStateKey);
      _shopGstMode = prefs.getString(SessionStorage.shopGstModeKey);
      _shopGstNum = prefs.getString(SessionStorage.shopGstNumKey);
      _shopBusinessType = prefs.getString(SessionStorage.shopBusinessTypeKey);

      final currentSupabaseUser = supabase.auth.currentUser;
      
      if (currentSupabaseUser != null) {
        _userId = currentSupabaseUser.id;
        _userName = currentSupabaseUser.userMetadata?['full_name'] ?? currentSupabaseUser.email;
        
        await _storage.saveUser(_userId!, _userName ?? '');
        
        if (_shopId == null) {
          await _fetchAndPersistShop(_userId!);
        }
        if (_shopId != null) {
          triggerCacheWarmup();
        }
      } else if (_userId != null) {
        await _clearLocal();
      }
    } catch (e) {
      debugPrint('[UserSession] init error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with Google OAuth using Supabase integration.
  Future<Map<String, dynamic>> loginWithGoogle() async {
    final result = await _auth.loginWithGoogle();
    if (result['success'] == true) {
      if (kIsWeb) {
        return result;
      }
      _userId = result['userId'] as String?;
      _userName = result['userName'] as String?;
      _emailVerified = result['emailConfirmed'] as bool? ?? true;

      await _storage.saveUser(_userId!, _userName ?? '');

      final shopResult = await _shop.fetchShop(_userId!);
      if (shopResult != null) {
        _shopId = shopResult['id'] as String?;
        _shopName = shopResult['name'] as String?;
        _shopState = shopResult['state'] as String?;
        _shopGstMode = shopResult['gst_mode'] as String?;
        _shopGstNum = shopResult['gst_registration_number'] as String?;
        _shopBusinessType = shopResult['business_type'] as String?;

        await _storage.saveShop(
          id: _shopId!,
          name: _shopName ?? 'My Shop',
          state: _shopState ?? 'DL',
          gstMode: _shopGstMode ?? 'UNREGISTERED',
          gstNum: _shopGstNum,
          businessType: _shopBusinessType ?? 'Retail',
        );
      }

      if (_shopId != null) {
        triggerCacheWarmup();
      }

      notifyListeners();
    }
    return result;
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
      final result = await _shop.createShop(
        ownerId: _userId!,
        name: name,
        state: state,
        businessType: businessType,
        gstNumber: gstNumber,
        gstMode: gstMode,
        upiId: upiId,
      );

      _shopId = result['id'] as String?;
      _shopName = result['name'] as String?;
      _shopState = result['state'] as String?;
      _shopGstMode = result['gst_mode'] as String?;
      _shopGstNum = result['gst_registration_number'] as String?;
      _shopBusinessType = result['business_type'] as String?;

      if (_shopId != null) {
        await _storage.saveShop(
          id: _shopId!,
          name: _shopName ?? 'My Shop',
          state: _shopState ?? 'DL',
          gstMode: _shopGstMode ?? 'UNREGISTERED',
          gstNum: _shopGstNum,
          businessType: _shopBusinessType ?? 'Retail',
        );
        triggerCacheWarmup();
      }

      notifyListeners();
      return {'success': true};
    } catch (e) {
      debugPrint('[UserSession] createShop error: $e');
      return {'success': false, 'error': e.toString().replaceAll('Exception: ', '')};
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    await _auth.logout();
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
    await _storage.clear();
  }

  /// Mark the current user's email as verified and notify listeners.
  void markEmailVerified() {
    _emailVerified = true;
    notifyListeners();
  }

  /// Triggers a background cache warmup from Supabase to SQFlite.
  void triggerCacheWarmup() {
    if (_shopId != null) {
      _cache.triggerWarmup(_shopId!);
    }
  }
}
