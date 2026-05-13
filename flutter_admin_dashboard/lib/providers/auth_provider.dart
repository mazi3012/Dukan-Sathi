import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth model
class AdminUser {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final bool isActive;
  final String roleId;
  final String? shopId;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.isActive,
    required this.roleId,
    this.shopId,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      roleId: json['role_id'] ?? '',
      shopId: json['shop_id'],
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'is_active': isActive,
      'role_id': roleId,
      'shop_id': shopId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Auth Provider - Manages authentication state
class AuthProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AdminUser? _currentUser;
  String? _sessionToken;
  bool _isLoading = false;
  String? _error;

  // Getters
  AdminUser? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /// Login with Google
  Future<bool> loginWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Sign out first to ensure fresh login
      await _googleSignIn.signOut();

      // Start Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _error = 'Google sign-in cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get Google authentication details
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _error = 'Failed to get Google authentication tokens';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Sign in with Supabase using Google provider
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );

      if (response.user == null) {
        _error = 'Failed to authenticate with Supabase';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userId = response.user!.id;
      final userEmail = response.user!.email ?? googleUser.email;
      final userName = googleUser.displayName ?? googleUser.email;

      // Create/update admin user record
      _currentUser = AdminUser(
        id: userId,
        email: userEmail,
        fullName: userName,
        phone: googleUser.photoUrl,
        isActive: true,
        roleId: 'admin',
        shopId: null,
        createdAt: DateTime.now(),
      );

      _sessionToken = 'admin_token_${DateTime.now().millisecondsSinceEpoch}';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  void logout() {
    _currentUser = null;
    _sessionToken = null;
    _error = null;
    notifyListeners();
  }

  /// Check if user is authenticated
  bool checkAuthentication() {
    return _currentUser != null && _sessionToken != null;
  }
}
