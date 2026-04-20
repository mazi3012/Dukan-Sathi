# 🚀 Supabase Migration Guide - Phase 1 Admin Dashboard

## 📋 Summary

This guide walks you through executing the Phase 1 database schema in your Supabase project.

**File:** `MIGRATION_CONSOLIDATED.sql`  
**Size:** 290 lines  
**Duration:** ~5-10 seconds to execute  
**Status:** ✅ Ready to run

---

## ✅ 3-Step Process

### Step 1️⃣: Open Supabase Console

1. Go to: **https://supabase.com/dashboard**
2. Log in with your credentials
3. You should see your projects listed
4. Click on project: **owvtyqccmiurlwwpocoj**

**Screenshot location:** Top dashboard where you see all projects

---

### Step 2️⃣: Navigate to SQL Editor

1. Once inside your project, look at the **left sidebar**
2. Find and click **"SQL Editor"** (looks like a code/script icon)
3. You should see existing queries on the right
4. Click the **"+ New Query"** button (top right)

**Keyboard shortcut:** You might see a shortcut listed

---

### Step 3️⃣: Copy & Paste Migration SQL

#### Option A: Copy from File (Recommended)

```bash
# From your terminal/project root:
cat MIGRATION_CONSOLIDATED.sql | pbcopy  # Mac
# or
cat MIGRATION_CONSOLIDATED.sql | xclip -selection clipboard  # Linux
# or copy manually from the file
```

#### Option B: Copy from Web Editor

1. Open this file in any text editor:
   - `MIGRATION_CONSOLIDATED.sql`
2. **Select All** (Ctrl+A)
3. **Copy** (Ctrl+C)

#### Option C: Direct File Path

File location in your project:
```
/workspaces/dukansathi-new/MIGRATION_CONSOLIDATED.sql
```

---

### Step 4️⃣: Execute in Supabase

1. **Paste the SQL** into the editor window (Ctrl+V)
2. You should see the SQL code fill the editor
3. Click the **"RUN"** button (green button, top right)
   - **Keyboard:** Press `Ctrl+Enter`

4. **Wait for execution** (5-10 seconds)
5. You should see a **success message** at the bottom

---

## ✨ What Gets Created

Once the migration completes successfully:

### 📊 Database Tables (6)
- `admin_roles` - Role definitions
- `admin_permissions` - Permission definitions  
- `admin_users` - Admin user accounts
- `admin_sessions` - Session management
- `role_permissions` - Role-permission mapping
- `admin_audit_log` - Audit trail

### 🔐 Default Roles (4)
- `super_admin` - Full system access
- `shop_owner` - Shop management
- `inventory_manager` - Inventory only
- `viewer` - Read-only access

### 🔑 Default Permissions (11)
- `manage_users`, `view_users`
- `manage_inventory`, `view_inventory`
- `manage_analytics`, `view_analytics`
- `manage_shop`, `manage_roles`
- `manage_invoices`, `view_invoices`
- `view_audit_log`

### 🛡️ Security Features
- Row-Level Security (RLS) policies
- Automatic audit logging
- Permission-based access control
- Timestamp auto-update triggers

### ⚡ Performance Indexes (9)
- Email lookups: `idx_admin_users_email`
- Role queries: `idx_admin_users_role_id`
- Session management: `idx_admin_sessions_*`
- Audit queries: `idx_admin_audit_*`

---

## 🧪 Verify Migration Success

After execution, verify the tables were created:

```sql
-- In Supabase SQL Editor, run this query:
SELECT table_name FROM information_schema.tables 
WHERE table_schema='public' 
AND table_name LIKE 'admin_%';
```

You should see 6 tables:
- admin_roles
- admin_permissions
- admin_users
- admin_sessions
- admin_audit_log
- role_permissions (created implicitly)

---

## 🚀 Test Admin API Endpoints

After migration is complete, test your new endpoints:

```bash
# Get all roles
curl http://localhost:3100/api/admin/roles

# Get all permissions
curl http://localhost:3100/api/admin/permissions

# Get all users (should be empty)
curl http://localhost:3100/api/admin/users

# Get audit log
curl http://localhost:3100/api/admin/audit-log
```

**Expected responses:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-here",
      "role_name": "super_admin",
      "description": "Full system access",
      "created_at": "2026-04-20T...",
      "updated_at": "2026-04-20T..."
    },
    ...
  ]
}
```

---

## ❌ Troubleshooting

### Issue: "Table already exists" error
**Cause:** Migration was already run  
**Solution:** This is normal - `IF NOT EXISTS` clauses prevent duplicates.

### Issue: "Permission denied" error
**Cause:** You're using a role with insufficient permissions  
**Solution:** Make sure you're logged in with the project owner account in Supabase

### Issue: RLS policies fail to create
**Cause:** Tables need to exist first  
**Solution:** Run the schema part first, then RLS policies. They're in the same file though, so just re-run.

### Issue: "exec_sql not found"
**Cause:** Custom function doesn't exist  
**Solution:** This is expected - the migrations don't depend on it.

---

## 📊 Timeline

| Step | Time |
|------|------|
| Copy SQL | 30 seconds |
| Paste in editor | 10 seconds |
| Click Run | Instant |
| Execute | 5-10 seconds |
| **Total** | **< 1 minute** |

---

## 📚 Next Steps

✅ **Migration executed successfully?**

Now you can:

1. **Create admin users** via API
   ```bash
   POST /api/admin/users
   ```

2. **Manage roles & permissions**
   ```bash
   GET /api/admin/roles
   GET /api/admin/permissions
   ```

3. **Track all actions** with audit logging
   ```bash
   GET /api/admin/audit-log
   ```

4. **Build Flutter Web UI** (Phase 2)
   - Admin dashboard interface
   - User management screens
   - Role assignment UI
   - Audit log viewer

---

## 🔗 Reference Links

- **Supabase Dashboard:** https://supabase.com/dashboard
- **Supabase SQL Reference:** https://supabase.com/docs/guides/database/sql
- **Project Migration Files:** `/supabase/migrations/`
- **API Documentation:** `/docs/PHASE1_ADMIN_DATABASE.md`

---

## ✅ Checklist

- [ ] Opened Supabase console
- [ ] Navigated to SQL Editor
- [ ] Copied MIGRATION_CONSOLIDATED.sql
- [ ] Created new query
- [ ] Pasted SQL code
- [ ] Clicked "RUN" button
- [ ] Saw success message
- [ ] Verified tables in Supabase Tables view
- [ ] Tested API endpoints
- [ ] Ready for Phase 2 development

---

**🎉 Migration Complete!**

Your admin database is now ready for the Flutter Web UI (Phase 2).

For questions, check the comprehensive docs:
- `docs/PHASE1_ADMIN_DATABASE.md`
- `docs/PHASE1_QUICKSTART.md`
- `docs/PHASE1_COMPLETION_SUMMARY.md`
