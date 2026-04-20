# Phase 1: Admin Dashboard - Database & API Layer

**Date:** April 20, 2026 | **Status:** ✅ Complete | **Branch:** main

## Overview

Phase 1 establishes the complete database schema and API infrastructure for the admin dashboard. This provides a solid foundation for Flutter Web to connect to and manage the retail business system.

## What's Been Implemented

### 1. Database Schema (`supabase/migrations/20260420_admin_schema.sql`)

#### Tables Created
- **admin_roles** - Role definitions (super_admin, shop_owner, inventory_manager, viewer)
- **admin_permissions** - Granular permissions (manage_users, view_inventory, etc.)
- **role_permissions** - Junction table linking roles to permissions
- **admin_users** - Admin user accounts with email, password hash, and role assignment
- **admin_sessions** - Session tracking for security and audit
- **admin_audit_log** - Full audit trail of all admin actions

#### Key Features
- ✅ UUID primary keys for security
- ✅ Timestamps (created_at, updated_at) on all tables
- ✅ Foreign key relationships with CASCADE delete
- ✅ Performance indexes on frequently queried fields
- ✅ Default roles and permissions pre-populated
- ✅ Support for multi-tenant (shop_id) setups

### 2. Row-Level Security (RLS) (`supabase/migrations/20260420_admin_rls_policies.sql`)

#### Security Policies
- Super admin can view all users
- Admins can only view their own profile
- Super admin can edit users
- Users can only manage their own sessions
- Audit logging is automatically triggered

#### Audit Triggers
- Auto-insert audit logs on user creation
- Auto-update timestamps on row changes

### 3. Dart Models (`lib/models/`)

Created Freezed models for type safety:
- `AdminRole` - Role data model
- `AdminPermission` - Permission data model
- `AdminUser` - User data model
- `AdminSession` - Session data model
- `AdminAuditLog` - Audit log entry model

*Note:* Freezed code generation (.freezed.dart, .g.dart) requires Dart SDK installation.

### 4. Admin Service (`lib/services/admin_service.dart`)

Complete service layer handling:

#### User Management
```dart
- getAdminUsers() - List all users with filtering
- getAdminUserById(userId) - Get single user
- getAdminUserByEmail(email) - Lookup by email
- createAdminUser() - Add new admin
- updateAdminUser() - Edit admin details
- deactivateAdminUser() - Soft delete
```

#### Role & Permission Management
```dart
- getRoles() - List all roles
- getRolePermissions(roleId) - Get permissions for role
- getPermissions() - List all permissions
- userHasPermission(userId, permissionName) - Check permission
```

#### Session Management
```dart
- createAdminSession() - Start new session
- verifySessionToken() - Validate token
- revokeSession() - End session
- revokeAllUserSessions() - Logout all sessions
```

#### Audit & Logging
```dart
- logAuditEvent() - Log any administrative action
- getAuditLog() - Query audit trail
- updateLastLogin() - Track logins
```

### 5. Admin API Endpoints (`lib/tools/admin_api_handler.dart`)

RESTful API with Shelf Router:

#### User Management
```
GET  /admin/users                    - List all users
GET  /admin/users/<userId>           - Get user details
POST /admin/users                    - Create new user
PUT  /admin/users/<userId>           - Update user
POST /admin/users/<userId>/deactivate - Deactivate user
```

#### Roles & Permissions
```
GET  /admin/roles                           - List roles
GET  /admin/roles/<roleId>/permissions     - Get role permissions
GET  /admin/permissions                    - List all permissions
POST /admin/permissions/<userId>/check     - Check user permission
```

#### Sessions
```
POST /admin/sessions                       - Create session
POST /admin/sessions/verify                - Verify token
DELETE /admin/sessions/<sessionId>         - Revoke session
POST /admin/sessions/<userId>/revoke-all  - Logout all
```

#### Audit
```
GET /admin/audit-log - Query audit trail with filters
```

#### Authentication
```
POST /admin/login - Admin login endpoint
```

## API Usage Examples

### Login
```bash
curl -X POST http://localhost:3100/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@shop.com",
    "password": "hashed_password"
  }'
```

Response:
```json
{
  "success": true,
  "data": {
    "user": { ... },
    "session": { ... },
    "token": "token_hash_here"
  }
}
```

### List Users
```bash
curl http://localhost:3100/admin/users?role_id=xxx&is_active=true
```

### Update User
```bash
curl -X PUT http://localhost:3100/admin/users/<userId> \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Doe",
    "phone": "+1234567890"
  }'
```

### Check Permission
```bash
curl -X POST http://localhost:3100/admin/permissions/<userId>/check \
  -H "Content-Type: application/json" \
  -d '{"permission": "manage_inventory"}'
```

### Query Audit Log
```bash
curl 'http://localhost:3100/admin/audit-log?action=user_created&limit=50'
```

## Database Schema Diagram

```
admin_users (1) ──→ (∞) admin_sessions
    ↓
    ├─→ (1) admin_roles (1) ──→ (∞) role_permissions (∞) ← admin_permissions
    └─→ (1) admin_audit_log (audit trail)

product management:
    ├─→ products (from Phase 4.5)
    ├─→ draft_invoices (from Phase 4.5)
    └─→ admin_audit_log (tracks changes)
```

## Default Roles & Permissions

### Super Admin
- Full system access (all permissions)

### Shop Owner
- Manage inventory
- View analytics
- Manage shop settings
- Manage invoices
- View audit logs

### Inventory Manager
- Manage inventory only
- View inventory

### Viewer
- Read-only access to:
  - Users list
  - Inventory
  - Analytics
  - Audit logs
  - Invoices

## Security Features

✅ **Row-Level Security (RLS)** - Database-level access control
✅ **Audit Logging** - Track all administrative actions
✅ **Session Management** - Token-based authentication
✅ **Permission Checks** - Fine-grained access control
✅ **Last Login Tracking** - Security monitoring
✅ **Inactive User Support** - Soft delete capability
✅ **Multi-Tenant Ready** - shop_id support for scaling

## Integration Guide for Flutter Web

### 1. Setup Admin Service in Dart Backend

```dart
import 'package:supabase/supabase.dart';
import 'lib/services/admin_service.dart';
import 'lib/tools/admin_api_handler.dart';

// Initialize
final supabase = SupabaseClient(url, anonKey);
final adminService = AdminService(supabase);
final adminApi = AdminApiHandler(adminService);

// Add to your Shelf router
final router = Router()
  ..mount('/api/', adminApi.handler);
```

### 2. Connect Flutter Web

```dart
// In Flutter Web
final adminClient = AdminApiClient('http://localhost:3100');

// Login
final loginResult = await adminClient.login(email, password);
final token = loginResult.data['token'];

// List users
final users = await adminClient.getAdminUsers();

// Create user
await adminClient.createAdminUser(
  email: 'newadmin@shop.com',
  roleId: superAdminRoleId,
);
```

## Next Steps (Phase 2+)

- [ ] Implement password hashing (bcrypt) in login flow
- [ ] Add JWT token generation instead of hash-based tokens
- [ ] Create Flutter Web UI components
- [ ] Add 2FA support
- [ ] Implement rate limiting on login
- [ ] Add email verification for new admins
- [ ] Create dashboard analytics endpoint
- [ ] Implement inventory management endpoints

## Running on Your System

### Database Migrations
```bash
# Apply migrations to Supabase
supabase db push
```

### Starting the API Server
```bash
cd /workspaces/dukansathi-new
export PATH="/tmp/dart-sdk/bin:$PATH"
dart run bin/genkit_server.dart
```

The admin API will be available at: `http://localhost:3100/admin`

## Files Created/Modified

### New Files
- ✅ `supabase/migrations/20260420_admin_schema.sql` - Tables and seeding
- ✅ `supabase/migrations/20260420_admin_rls_policies.sql` - RLS and triggers
- ✅ `lib/models/admin_role.dart` - Role model
- ✅ `lib/models/admin_permission.dart` - Permission model
- ✅ `lib/models/admin_user.dart` - User model
- ✅ `lib/models/admin_session.dart` - Session model
- ✅ `lib/models/admin_audit_log.dart` - Audit log model
- ✅ `lib/services/admin_service.dart` - Service logic
- ✅ `lib/tools/admin_api_handler.dart` - API endpoints
- ✅ `docs/PHASE1_ADMIN_DATABASE.md` - This document

### Testing
You can test endpoints using curl or Postman after starting the server.

## Performance Considerations

- Indexes on `email`, `role_id`, `is_active` for fast user lookups
- Indexes on `user_id`, `token_hash`, `expires_at` for session queries
- Indexes on `created_at`, `action`, `user_id` for audit log queries
- Pagination support (limit/offset) on list endpoints

## Troubleshooting

### Issue: RLS errors in Supabase
**Solution:** Ensure migrations ran successfully in Supabase console

### Issue: Token verification fails
**Solution:** Check that token_hash is being properly hashed before storage

### Issue: Audit logs not appearing
**Solution:** Verify database triggers were created (check Functions tab in Supabase)

---

**Phase 1 complete!** 🎉

Next: Flutter Web dashboard implementation (Phase 2)
