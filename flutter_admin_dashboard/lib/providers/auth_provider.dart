import 'package:flutter/foundation.dart';

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

  /// Simulate login (in real app, would call API)
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: Call actual login API endpoint
      // For now, simulate with a super_admin user
      await Future.delayed(Duration(seconds: 1));

      _currentUser = AdminUser(
        id: 'admin-001',
        email: email,
        fullName: 'Admin User',
        phone: '',
        isActive: true,
        roleId: 'super_admin',
        shopId: null,
        createdAt: DateTime.now(),
      );

      _sessionToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
