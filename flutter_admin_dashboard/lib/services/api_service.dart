import 'package:http/http.dart' as http;
import 'dart:convert';

/// API Service - Handles all backend API calls
class ApiService {
  late String baseUrl;

  ApiService() {
    final uri = Uri.base;
    final host = uri.host;

    // Codespaces web forwarding host pattern:
    // <space-name>-<port>.app.github.dev
    final match = RegExp(r'^(.*)-\d+\.app\.github\.dev$').firstMatch(host);
    if (match != null) {
      final prefix = match.group(1)!;
      final backendHost = '$prefix-3100.app.github.dev';
      baseUrl = '${uri.scheme}://$backendHost';
      return;
    }

    // Local/dev fallback.
    baseUrl = 'http://localhost:3100';
  }

  // ============================================================================
  // ROLES API
  // ============================================================================

  /// Get all admin roles
  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/admin/roles'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      throw Exception('Failed to fetch roles: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching roles: $e');
    }
  }

  // ============================================================================
  // PERMISSIONS API
  // ============================================================================

  /// Get all permissions
  Future<List<Map<String, dynamic>>> getPermissions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/admin/permissions'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      throw Exception('Failed to fetch permissions: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching permissions: $e');
    }
  }

  /// Get permissions for a specific role
  Future<List<Map<String, dynamic>>> getRolePermissions(String roleId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/admin/roles/$roleId/permissions'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      throw Exception('Failed to fetch role permissions: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching role permissions: $e');
    }
  }

  // ============================================================================
  // USERS API
  // ============================================================================

  /// Get all admin users
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/admin/users'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      throw Exception('Failed to fetch admin users: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching admin users: $e');
    }
  }

  /// Get admin user by ID
  Future<Map<String, dynamic>> getAdminUser(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/admin/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      throw Exception('Failed to fetch admin user: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching admin user: $e');
    }
  }

  /// Create new admin user
  Future<Map<String, dynamic>> createAdminUser({
    required String email,
    required String passwordHash,
    required String roleId,
    required String fullName,
    String? phone,
    String? shopId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password_hash': passwordHash,
          'role_id': roleId,
          'full_name': fullName,
          'phone': phone,
          'shop_id': shopId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      throw Exception('Failed to create admin user: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating admin user: $e');
    }
  }

  /// Update admin user
  Future<Map<String, dynamic>> updateAdminUser(
    String userId, {
    String? email,
    String? fullName,
    String? phone,
    String? roleId,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (email != null) body['email'] = email;
      if (fullName != null) body['full_name'] = fullName;
      if (phone != null) body['phone'] = phone;
      if (roleId != null) body['role_id'] = roleId;
      if (isActive != null) body['is_active'] = isActive;

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      throw Exception('Failed to update admin user: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating admin user: $e');
    }
  }

  /// Deactivate admin user
  Future<void> deactivateAdminUser(String userId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/api/admin/users/$userId'));
      if (response.statusCode != 200) {
        throw Exception('Failed to deactivate admin user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deactivating admin user: $e');
    }
  }

  // ============================================================================
  // AUDIT LOG API
  // ============================================================================

  /// Get audit log
  Future<List<Map<String, dynamic>>> getAuditLog({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/admin/audit-log?limit=$limit&offset=$offset'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      throw Exception('Failed to fetch audit log: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching audit log: $e');
    }
  }
}
