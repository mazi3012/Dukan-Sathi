import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Data Provider - Manages admin data (users, roles, permissions)
class DataProvider extends ChangeNotifier {
  final ApiService api = ApiService();

  // Collections
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _permissions = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _auditLog = [];

  // UI State
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get roles => _roles;
  List<Map<String, dynamic>> get permissions => _permissions;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get auditLog => _auditLog;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================================
  // ROLES
  // ============================================================================

  Future<void> fetchRoles() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _roles = await api.getRoles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  String? getRoleName(String roleId) {
    try {
      final role = _roles.firstWhere((r) => r['id'] == roleId);
      return role['role_name'];
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? getRole(String roleId) {
    try {
      return _roles.firstWhere((r) => r['id'] == roleId);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // PERMISSIONS
  // ============================================================================

  Future<void> fetchPermissions() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _permissions = await api.getPermissions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  String? getPermissionName(String permId) {
    try {
      final perm = _permissions.firstWhere((p) => p['id'] == permId);
      return perm['permission_name'];
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // USERS
  // ============================================================================

  Future<void> fetchUsers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _users = await api.getAdminUsers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String email,
    required String passwordHash,
    required String roleId,
    required String fullName,
    String? phone,
    String? shopId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newUser = await api.createAdminUser(
        email: email,
        passwordHash: passwordHash,
        roleId: roleId,
        fullName: fullName,
        phone: phone,
        shopId: shopId,
      );

      _users.add(newUser);
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

  Future<bool> updateUser(
    String userId, {
    String? email,
    String? fullName,
    String? phone,
    String? roleId,
    bool? isActive,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await api.updateAdminUser(
        userId,
        email: email,
        fullName: fullName,
        phone: phone,
        roleId: roleId,
        isActive: isActive,
      );

      // Update local list
      final index = _users.indexWhere((u) => u['id'] == userId);
      if (index >= 0) {
        if (email != null) _users[index]['email'] = email;
        if (fullName != null) _users[index]['full_name'] = fullName;
        if (phone != null) _users[index]['phone'] = phone;
        if (roleId != null) _users[index]['role_id'] = roleId;
        if (isActive != null) _users[index]['is_active'] = isActive;
      }

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

  Future<bool> deactivateUser(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await api.deactivateAdminUser(userId);

      // Update local list
      final index = _users.indexWhere((u) => u['id'] == userId);
      if (index >= 0) {
        _users[index]['is_active'] = false;
      }

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

  // ============================================================================
  // AUDIT LOG
  // ============================================================================

  Future<void> fetchAuditLog({int limit = 50, int offset = 0}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _auditLog = await api.getAuditLog(limit: limit, offset: offset);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // INITIALIZE
  // ============================================================================

  /// Initialize all data
  Future<void> initialize() async {
    await Future.wait([
      fetchRoles(),
      fetchPermissions(),
      fetchUsers(),
      fetchAuditLog(),
    ]);
  }
}
