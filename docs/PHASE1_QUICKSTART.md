# Phase 1: Quick Start Guide

**Status:** ✅ All components implemented  
**Date:** April 20, 2026

## 📦 What You Have

```
Backend (Dart + Supabase):
  ✅ Database schema with 6 tables
  ✅ RLS policies for security
  ✅ AdminService (21 methods)
  ✅ 15+ REST API endpoints

Frontend (Flutter Web):
  ✅ Project structure
  ✅ Theme and routing configured
  ✅ Placeholder screens
  ✅ Dependency list

Documentation:
  ✅ Full API reference
  ✅ Integration guide
  ✅ Data model documentation
  ✅ Troubleshooting guide
```

## 🚀 Running Phase 1

### Step 1: Apply Database Migrations

Push the migrations to Supabase:

```bash
# In Supabase console:
1. Go to SQL Editor
2. Create new query
3. Copy content from: supabase/migrations/20260420_admin_schema.sql
4. Run it
5. Repeat for: supabase/migrations/20260420_admin_rls_policies.sql

# OR use Supabase CLI:
cd /workspaces/dukansathi-new
supabase db push
```

**Verify:** Check Supabase console → Tables
- Should see: admin_users, admin_roles, admin_permissions, admin_sessions, role_permissions, admin_audit_log

### Step 2: Set Up Backend Environment

Ensure `.env` has database credentials:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
GOOGLE_API_KEY=your_genai_api_key
MODEL_ID=gemini-3.1-flash-lite-preview
TELEGRAM_BOT_TOKEN=your_bot_token
```

### Step 3: Generate Dart Code (When Dart SDK Available)

```bash
cd /workspaces/dukansathi-new
dart pub get
dart run build_runner build  # Generates .freezed.dart and .g.dart
```

### Step 4: Test API Endpoints

Start the backend server:

```bash
cd /workspaces/dukansathi-new
export PATH="/tmp/dart-sdk/bin:$PATH"  # Add Dart to PATH if needed
dart run bin/genkit_server.dart
```

The API will be available on: `http://localhost:3100/api/admin/`

**Test endpoints with curl:**

```bash
# 1. Get roles
curl http://localhost:3100/api/admin/roles

# 2. Get permissions
curl http://localhost:3100/api/admin/permissions

# 3. List users
curl http://localhost:3100/api/admin/users

# 4. Test login
curl -X POST http://localhost:3100/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@shop.com",
    "password": "test123"
  }'
```

### Step 5: Set Up Flutter Web

```bash
cd /workspaces/dukansathi-new/flutter_admin_dashboard
flutter pub get
flutter run -d chrome
```

Dashboard will open at: `http://localhost:5000`

## 📝 API Endpoint Examples

### User Management

**List all users:**
```bash
curl http://localhost:3100/api/admin/users?limit=10&offset=0
```

**Get user by ID:**
```bash
curl http://localhost:3100/api/admin/users/{userId}
```

**Create user:**
```bash
curl -X POST http://localhost:3100/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@shop.com",
    "password_hash": "hashed_password",
    "role_id": "role-uuid",
    "full_name": "John Doe"
  }'
```

**Update user:**
```bash
curl -X PUT http://localhost:3100/api/admin/users/{userId} \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Jane Doe",
    "is_active": true
  }'
```

### Role & Permission Management

**Get all roles:**
```bash
curl http://localhost:3100/api/admin/roles
```

**Get permissions for a role:**
```bash
curl http://localhost:3100/api/admin/roles/{roleId}/permissions
```

**List all permissions:**
```bash
curl http://localhost:3100/api/admin/permissions
```

**Check if user has permission:**
```bash
curl -X POST http://localhost:3100/api/admin/permissions/{userId}/check \
  -H "Content-Type: application/json" \
  -d '{"permission": "manage_users"}'
```

### Session Management

**Create session:**
```bash
curl -X POST http://localhost:3100/api/admin/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user-uuid",
    "token_hash": "hashed_token",
    "expires_at": "2026-04-27T00:00:00Z",
    "ip_address": "192.168.1.1"
  }'
```

**Verify token:**
```bash
curl -X POST http://localhost:3100/api/admin/sessions/verify \
  -H "Content-Type: application/json" \
  -d '{"token_hash": "token_hash_here"}'
```

**Revoke session:**
```bash
curl -X DELETE http://localhost:3100/api/admin/sessions/{sessionId}
```

### Audit Log

**Get audit log:**
```bash
curl 'http://localhost:3100/api/admin/audit-log?action=user_created&limit=50'
```

**Filter audit log:**
```bash
curl 'http://localhost:3100/api/admin/audit-log?user_id={userId}&action=login&limit=100'
```

## 🗄️ Default Roles

When migrations run, these roles are created:

```
1. super_admin       → Full system access
2. shop_owner        → Shop management access
3. inventory_manager → Inventory only
4. viewer            → Read-only access
```

## 📊 Database Schema Quick Reference

### admin_users
- id (UUID)
- email (unique)
- password_hash
- full_name, phone
- is_active (boolean)
- role_id (FK → admin_roles)
- shop_id (optional, for multi-tenant)
- last_login, created_at, updated_at

### admin_roles
- id (UUID)
- role_name (unique)
- description
- created_at, updated_at

### admin_permissions
- id (UUID)
- permission_name (unique)
- description
- resource, action
- created_at

### admin_sessions
- id (UUID)
- user_id (FK → admin_users)
- token_hash (unique)
- ip_address, user_agent
- expires_at
- created_at

### admin_audit_log
- id (UUID)
- user_id (FK → admin_users, nullable)
- action, resource, resource_id
- changes (JSONB)
- ip_address, status, error_message
- created_at

## 🔧 Configuration

### Environment Variables

Add to `.env`:
```env
# Supabase
SUPABASE_URL=https://project.supabase.co
SUPABASE_ANON_KEY=your_key

# Backend Server
API_PORT=3100
API_HOST=0.0.0.0

# Flutter (web/admin_dashboard)
API_BASE_URL=http://localhost:3100/api/admin
APP_NAME=Dukan Sathi Admin
APP_VERSION=1.0.0
```

### API Server Configuration

In `bin/genkit_server.dart`, add:
```dart
import 'lib/tools/admin_api_handler.dart';

final adminService = AdminService(supabase);
final adminApiHandler = AdminApiHandler(adminService);

router.mount('/api/admin/', adminApiHandler.handler);
```

## ✅ Testing Checklist

- [ ] Migrations applied to Supabase
- [ ] Database tables visible in Supabase console
- [ ] API server starts without errors
- [ ] curl requests to endpoints return 200 OK
- [ ] Login endpoint authenticates correctly
- [ ] Audit log records actions
- [ ] Flutter project builds without errors
- [ ] Flutter Web opens in Chrome

## 📚 Next Steps

### Phase 2: UI Implementation
1. Create login screen in Flutter Web
2. Implement user management UI
3. Build inventory management interface
4. Add dashboard widgets
5. Connect API client to backend

### Current Files to Review

**Backend:**
- [lib/services/admin_service.dart](../../lib/services/admin_service.dart)
- [lib/tools/admin_api_handler.dart](../../lib/tools/admin_api_handler.dart)
- [supabase/migrations/20260420_admin_schema.sql](../../supabase/migrations/20260420_admin_schema.sql)

**Frontend:**
- [flutter_admin_dashboard/lib/main.dart](../../flutter_admin_dashboard/lib/main.dart)
- [flutter_admin_dashboard/lib/config/theme.dart](../../flutter_admin_dashboard/lib/config/theme.dart)
- [flutter_admin_dashboard/lib/config/routes.dart](../../flutter_admin_dashboard/lib/config/routes.dart)

**Documentation:**
- [docs/PHASE1_ADMIN_DATABASE.md](PHASE1_ADMIN_DATABASE.md)
- [docs/PHASE1_COMPLETION_SUMMARY.md](PHASE1_COMPLETION_SUMMARY.md)

## 🆘 Troubleshooting

### API Returns 404
**Problem:** Endpoint not found  
**Solution:** Verify AdminApiHandler is mounted in router with correct path prefix

### Database RLS Errors
**Problem:** "new row violates row-level security policy"  
**Solution:** Check that RLS policies are created (see migrations)

### Flutter Can't Connect to API
**Problem:** Connection refused on http://localhost:3100  
**Solution:** 
1. Verify backend server is running
2. Check API_BASE_URL in Flutter config
3. CORS headers configured on API server

### Dart Code Generation Fails
**Problem:** Can't generate .freezed.dart files  
**Solution:** Install Dart SDK and run `dart pub get && dart run build_runner build`

## 📞 Support

Review comprehensive documentation:
- **API Reference:** docs/PHASE1_ADMIN_DATABASE.md
- **Architecture:** docs/PHASE1_COMPLETION_SUMMARY.md
- **Schema Details:** supabase/migrations/20260420_admin_schema.sql

---

**Phase 1 - Quick Start Guide Complete** ✅

Ready to move to Phase 2: Flutter Web UI Implementation
