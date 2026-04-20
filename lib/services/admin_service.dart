import 'package:supabase/supabase.dart';

/// Admin Service - Handles all admin operations including users, roles, permissions, and audit logging
class AdminService {
  final SupabaseClient supabase;

  AdminService(this.supabase);

  // ============================================================================
  // USER MANAGEMENT
  // ============================================================================

  /// Get all admin users (super_admin only)
  Future<List<Map<String, dynamic>>> getAdminUsers({
    String? roleId,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = supabase.from('admin_users').select('*');

      if (roleId != null) {
        query = query.eq('role_id', roleId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch admin users: $e');
    }
  }

  /// Get admin user by ID
  Future<Map<String, dynamic>?> getAdminUserById(String userId) async {
    try {
      final response = await supabase
          .from('admin_users')
          .select('*')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get admin user by email
  Future<Map<String, dynamic>?> getAdminUserByEmail(String email) async {
    try {
      final response = await supabase
          .from('admin_users')
          .select('*')
          .eq('email', email)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Create a new admin user
  Future<Map<String, dynamic>> createAdminUser({
    required String email,
    required String passwordHash,
    required String roleId,
    required String? fullName,
    String? phone,
    String? shopId,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await getAdminUserByEmail(email);
      if (existingUser != null) {
        throw Exception('User with email $email already exists');
      }

      final response = await supabase.from('admin_users').insert({
        'email': email,
        'password_hash': passwordHash,
        'full_name': fullName,
        'phone': phone,
        'role_id': roleId,
        'shop_id': shopId,
        'is_active': true,
      }).select().single();

      return response;
    } catch (e) {
      throw Exception('Failed to create admin user: $e');
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
      final updates = <String, dynamic>{};
      if (email != null) updates['email'] = email;
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (roleId != null) updates['role_id'] = roleId;
      if (isActive != null) updates['is_active'] = isActive;

      final response = await supabase
          .from('admin_users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      // Log audit
      await logAuditEvent(
        action: 'user_updated',
        resource: 'admin_users',
        resourceId: userId,
        changes: updates,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to update admin user: $e');
    }
  }

  /// Deactivate admin user
  Future<void> deactivateAdminUser(String userId) async {
    try {
      await supabase
          .from('admin_users')
          .update({'is_active': false}).eq('id', userId);

      await logAuditEvent(
        action: 'user_deactivated',
        resource: 'admin_users',
        resourceId: userId,
      );
    } catch (e) {
      throw Exception('Failed to deactivate admin user: $e');
    }
  }

  // ============================================================================
  // ROLE & PERMISSION MANAGEMENT
  // ============================================================================

  /// Get all roles
  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response =
          await supabase.from('admin_roles').select('*').order('role_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch roles: $e');
    }
  }

  /// Get permissions for a role
  Future<List<Map<String, dynamic>>> getRolePermissions(String roleId) async {
    try {
      final response = await supabase
          .from('role_permissions')
          .select('admin_permissions(*)')
          .eq('role_id', roleId);

      return response
          .map<Map<String, dynamic>>((item) =>
              Map<String, dynamic>.from(item['admin_permissions'] as Map))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch role permissions: $e');
    }
  }

  /// Get all permissions
  Future<List<Map<String, dynamic>>> getPermissions() async {
    try {
      final response = await supabase
          .from('admin_permissions')
          .select('*')
          .order('resource');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch permissions: $e');
    }
  }

  /// Check if user has permission
  Future<bool> userHasPermission(
    String userId,
    String permissionName,
  ) async {
    try {
      final response = await supabase.from('admin_users').select(
          'admin_roles(role_permissions(admin_permissions(permission_name)))')
          .eq('id', userId)
          .single();

      final role = response['admin_roles'] as Map?;
      if (role == null) return false;

      final permissions = role['role_permissions'] as List?;
      if (permissions == null || permissions.isEmpty) return false;

      return permissions.any((perm) =>
          (perm as Map<String, dynamic>)['admin_permissions']
              ['permission_name'] ==
          permissionName);
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Create admin session
  Future<Map<String, dynamic>> createAdminSession({
    required String userId,
    required String tokenHash,
    required DateTime expiresAt,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final response = await supabase.from('admin_sessions').insert({
        'user_id': userId,
        'token_hash': tokenHash,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'expires_at': expiresAt.toIso8601String(),
      }).select().single();

      return response;
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  /// Verify session token
  Future<Map<String, dynamic>?> verifySessionToken(String tokenHash) async {
    try {
      final response = await supabase
          .from('admin_sessions')
          .select('*, admin_users(*)')
          .eq('token_hash', tokenHash)
          .gt('expires_at', DateTime.now().toIso8601String())
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Revoke session
  Future<void> revokeSession(String sessionId) async {
    try {
      await supabase.from('admin_sessions').delete().eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to revoke session: $e');
    }
  }

  /// Revoke all user sessions
  Future<void> revokeAllUserSessions(String userId) async {
    try {
      await supabase
          .from('admin_sessions')
          .delete()
          .eq('user_id', userId);

      await logAuditEvent(
        action: 'all_sessions_revoked',
        resource: 'admin_sessions',
        resourceId: userId,
      );
    } catch (e) {
      throw Exception('Failed to revoke user sessions: $e');
    }
  }

  // ============================================================================
  // AUDIT LOGGING
  // ============================================================================

  /// Log audit event
  Future<void> logAuditEvent({
    required String action,
    required String resource,
    String? resourceId,
    Map<String, dynamic>? changes,
    String? ipAddress,
    String status = 'success',
    String? errorMessage,
  }) async {
    try {
      await supabase.from('admin_audit_log').insert({
        'action': action,
        'resource': resource,
        'resource_id': resourceId,
        'changes': changes,
        'ip_address': ipAddress,
        'status': status,
        'error_message': errorMessage,
      });
    } catch (e) {
      // Log errors but don't throw to avoid breaking main operations
      print('Failed to log audit event: $e');
    }
  }

  /// Get audit log
  Future<List<Map<String, dynamic>>> getAuditLog({
    String? userId,
    String? action,
    String? resource,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = supabase.from('admin_audit_log').select('*');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (action != null) {
        query = query.eq('action', action);
      }
      if (resource != null) {
        query = query.eq('resource', resource);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch audit log: $e');
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId, {String? ipAddress}) async {
    try {
      await supabase.from('admin_users').update({
        'last_login': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      await logAuditEvent(
        action: 'user_login',
        resource: 'admin_users',
        resourceId: userId,
        ipAddress: ipAddress,
      );
    } catch (e) {
      print('Failed to update last login: $e');
    }
  }
}
