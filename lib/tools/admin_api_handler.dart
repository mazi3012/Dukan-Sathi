import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/admin_service.dart';
import 'package:supabase/supabase.dart';

/// Admin API Handler - All admin endpoints for the dashboard
class AdminApiHandler {
  final AdminService adminService;
  final Router router = Router();

  AdminApiHandler(this.adminService) {
    _setupRoutes();
  }

  void _setupRoutes() {
    // User Management Routes
    router.get('/admin/users', _getAdminUsers);
    router.get('/admin/users/<userId>', _getAdminUserById);
    router.post('/admin/users', _createAdminUser);
    router.put('/admin/users/<userId>', _updateAdminUser);
    router.post('/admin/users/<userId>/deactivate', _deactivateAdminUser);

    // Role Management Routes
    router.get('/admin/roles', _getRoles);
    router.get('/admin/roles/<roleId>/permissions', _getRolePermissions);

    // Permission Management Routes
    router.get('/admin/permissions', _getPermissions);
    router.post('/admin/permissions/<userId>/check', _checkUserPermission);

    // Session Management Routes
    router.post('/admin/sessions', _createSession);
    router.post('/admin/sessions/verify', _verifySessionToken);
    router.delete('/admin/sessions/<sessionId>', _revokeSession);
    router.post('/admin/sessions/<userId>/revoke-all', _revokeAllUserSessions);

    // Audit Log Routes
    router.get('/admin/audit-log', _getAuditLog);

    // Login Route
    router.post('/admin/login', _adminLogin);
  }

  // ============================================================================
  // USER MANAGEMENT HANDLERS
  // ============================================================================

  Future<Response> _getAdminUsers(Request request) async {
    try {
      final roleId = request.url.queryParameters['role_id'];
      final isActive = request.url.queryParameters['is_active'];
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '50') ?? 50;
      final offset =
          int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;

      final users = await adminService.getAdminUsers(
        roleId: roleId,
        isActive: isActive == 'true' ? true : isActive == 'false' ? false : null,
        limit: limit,
        offset: offset,
      );

      return Response.ok(
        jsonEncode({'success': true, 'data': users}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _getAdminUserById(Request request, String userId) async {
    try {
      final user = await adminService.getAdminUserById(userId);
      if (user == null) {
        return Response.notFound(
          jsonEncode({'success': false, 'error': 'User not found'}),
        );
      }
      return Response.ok(
        jsonEncode({'success': true, 'data': user}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _createAdminUser(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final user = await adminService.createAdminUser(
        email: body['email'],
        passwordHash: body['password_hash'],
        roleId: body['role_id'],
        fullName: body['full_name'],
        phone: body['phone'],
        shopId: body['shop_id'],
      );

      await adminService.logAuditEvent(
        action: 'user_created',
        resource: 'admin_users',
        resourceId: user['id'],
        changes: body,
      );

      return Response.ok(
        jsonEncode({'success': true, 'data': user}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _updateAdminUser(Request request, String userId) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final user = await adminService.updateAdminUser(
        userId,
        email: body['email'],
        fullName: body['full_name'],
        phone: body['phone'],
        roleId: body['role_id'],
        isActive: body['is_active'],
      );

      return Response.ok(
        jsonEncode({'success': true, 'data': user}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _deactivateAdminUser(
    Request request,
    String userId,
  ) async {
    try {
      await adminService.deactivateAdminUser(userId);
      return Response.ok(
        jsonEncode({'success': true, 'message': 'User deactivated'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  // ============================================================================
  // ROLE & PERMISSION HANDLERS
  // ============================================================================

  Future<Response> _getRoles(Request request) async {
    try {
      final roles = await adminService.getRoles();
      return Response.ok(
        jsonEncode({'success': true, 'data': roles}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _getRolePermissions(
    Request request,
    String roleId,
  ) async {
    try {
      final permissions = await adminService.getRolePermissions(roleId);
      return Response.ok(
        jsonEncode({'success': true, 'data': permissions}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _getPermissions(Request request) async {
    try {
      final permissions = await adminService.getPermissions();
      return Response.ok(
        jsonEncode({'success': true, 'data': permissions}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _checkUserPermission(
    Request request,
    String userId,
  ) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final hasPermission =
          await adminService.userHasPermission(userId, body['permission']);

      return Response.ok(
        jsonEncode({'success': true, 'has_permission': hasPermission}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  // ============================================================================
  // SESSION HANDLERS
  // ============================================================================

  Future<Response> _createSession(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final session = await adminService.createAdminSession(
        userId: body['user_id'],
        tokenHash: body['token_hash'],
        expiresAt: DateTime.parse(body['expires_at']),
        ipAddress: body['ip_address'],
        userAgent: body['user_agent'],
      );

      return Response.ok(
        jsonEncode({'success': true, 'data': session}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _verifySessionToken(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final session = await adminService.verifySessionToken(body['token_hash']);

      if (session == null) {
        return Response.unauthorized(
          jsonEncode({'success': false, 'error': 'Invalid or expired token'}),
        );
      }

      return Response.ok(
        jsonEncode({'success': true, 'data': session}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _revokeSession(
    Request request,
    String sessionId,
  ) async {
    try {
      await adminService.revokeSession(sessionId);
      return Response.ok(
        jsonEncode({'success': true, 'message': 'Session revoked'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  Future<Response> _revokeAllUserSessions(
    Request request,
    String userId,
  ) async {
    try {
      await adminService.revokeAllUserSessions(userId);
      return Response.ok(
        jsonEncode({'success': true, 'message': 'All sessions revoked'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  // ============================================================================
  // AUDIT LOG HANDLERS
  // ============================================================================

  Future<Response> _getAuditLog(Request request) async {
    try {
      final userId = request.url.queryParameters['user_id'];
      final action = request.url.queryParameters['action'];
      final resource = request.url.queryParameters['resource'];
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final offset =
          int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;

      final logs = await adminService.getAuditLog(
        userId: userId,
        action: action,
        resource: resource,
        limit: limit,
        offset: offset,
      );

      return Response.ok(
        jsonEncode({'success': true, 'data': logs}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  // ============================================================================
  // AUTH HANDLERS
  // ============================================================================

  Future<Response> _adminLogin(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final email = body['email'] as String;
      final password = body['password'] as String;
      final ipAddress = request.headers['x-forwarded-for'] ??
          request.context['remote_addr'] as String?;

      // Get user by email
      final user = await adminService.getAdminUserByEmail(email);
      if (user == null) {
        await adminService.logAuditEvent(
          action: 'login_failed',
          resource: 'admin_auth',
          status: 'failed',
          errorMessage: 'User not found',
          ipAddress: ipAddress,
        );
        return Response.forbidden(
          jsonEncode({'success': false, 'error': 'Invalid credentials'}),
        );
      }

      // Check if user is active
      if (user['is_active'] != true) {
        await adminService.logAuditEvent(
          action: 'login_failed',
          resource: 'admin_auth',
          resourceId: user['id'],
          status: 'failed',
          errorMessage: 'User is inactive',
          ipAddress: ipAddress,
        );
        return Response.forbidden(
          jsonEncode({'success': false, 'error': 'Account is inactive'}),
        );
      }

      // Verify password (in production, use bcrypt)
      // This is a simplified example - implement proper password verification
      final passwordHash = body['password_hash'] ?? '';
      if (passwordHash != user['password_hash']) {
        await adminService.logAuditEvent(
          action: 'login_failed',
          resource: 'admin_auth',
          resourceId: user['id'],
          status: 'failed',
          errorMessage: 'Invalid password',
          ipAddress: ipAddress,
        );
        return Response.forbidden(
          jsonEncode({'success': false, 'error': 'Invalid credentials'}),
        );
      }

      // Update last login
      await adminService.updateLastLogin(user['id'], ipAddress: ipAddress);

      // Create session
      final tokenHash = _generateTokenHash();
      final expiresAt = DateTime.now().add(Duration(days: 7));

      final session = await adminService.createAdminSession(
        userId: user['id'],
        tokenHash: tokenHash,
        expiresAt: expiresAt,
        ipAddress: ipAddress,
        userAgent: request.headers['user-agent'],
      );

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': {
            'user': user,
            'session': session,
            'token': tokenHash,
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
      );
    }
  }

  String _generateTokenHash() {
    // In production, use a proper token generation library
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().millisecond * 1000).toString();
  }

  FutureOr<Response> Function(Request) get handler => router.call;
}
