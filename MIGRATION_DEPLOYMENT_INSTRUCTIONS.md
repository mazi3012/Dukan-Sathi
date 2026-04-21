# 🚀 Database Deployment - Manual SQL Instructions

Since Supabase CLI is not available in this environment, here are alternative methods to deploy your migrations:

---

## ✅ Services Status

Both services have been started in the background:
- **Backend:** `dart bin/genkit_dev.dart` (Port 4000)
- **Telegram Bot:** `dart bin/telegram_bot.dart` (listening)

---

## 🗄️ Database Migration Deployment

You have **3 migration files ready** in `supabase/migrations/`:

1. `20260421_add_gst_config.sql` (1.1K)
2. `20260421_add_draft_approval.sql` (2.0K)  
3. `20260421_add_tax_breakdown.sql` (901B)

### Option 1: Via Supabase Dashboard (Easiest) ✅

1. **Go to:** https://supabase.co/dashboard
2. **Select your project**
3. **Navigate to:** SQL Editor
4. **For each migration file:**
   - Click "New Query"
   - Copy entire content from the migration file
   - Paste into SQL editor
   - Click "Run"
   - Repeat for all 3 files in order

**File Order (IMPORTANT):**
1. First: `20260421_add_gst_config.sql`
2. Second: `20260421_add_draft_approval.sql`
3. Third: `20260421_add_tax_breakdown.sql`

---

### Option 2: Via psql Command Line

If you have `psql` installed and your Supabase credentials:

```bash
# Set your Supabase connection string
SUPABASE_URL="postgresql://postgres:PASSWORD@db.xxx.supabase.co:5432/postgres"

# Run migrations in order
psql "$SUPABASE_URL" < supabase/migrations/20260421_add_gst_config.sql
psql "$SUPABASE_URL" < supabase/migrations/20260421_add_draft_approval.sql
psql "$SUPABASE_URL" < supabase/migrations/20260421_add_tax_breakdown.sql

# Verify
psql "$SUPABASE_URL" -c "SELECT column_name FROM information_schema.columns WHERE table_name='shops' AND column_name='state';"
```

**Get your connection string:**
1. Supabase Dashboard → Settings → Database
2. Copy the "Connection string" URL
3. Replace PASSWORD with your actual password

---

### Option 3: Via DBeaver or TablePlus (GUI Tools)

1. Connect to your Supabase database
2. Open SQL query window
3. Copy-paste each migration SQL file
4. Execute in order

---

### Option 4: Use Supabase Migrations After CLI Install

Once Supabase CLI is available:

```bash
# Link to your Supabase project
supabase link

# Deploy migrations
supabase db push

# Verify
supabase db pull
```

---

## ✅ Verification Steps

After deploying migrations, verify they worked:

### 1. Check shops table updates
```sql
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'shops' 
AND column_name IN ('state', 'gst_mode', 'gst_registration_number', 'business_type')
ORDER BY column_name;
```

**Expected Result:**
- ✅ state (character varying)
- ✅ gst_mode (character varying)
- ✅ gst_registration_number (character varying)
- ✅ business_type (character varying)

### 2. Check draft_approvals table created
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'draft_approvals'
ORDER BY ordinal_position;
```

**Must have these columns:**
- ✅ approval_id (uuid)
- ✅ draft_invoice_id (uuid)
- ✅ shop_id (uuid)
- ✅ created_at (timestamp)
- ✅ proposed_items (jsonb)
- ✅ proposed_tax_breakdown (jsonb)
- ✅ proposed_total (numeric)
- ✅ approval_status (character varying)
- ✅ reviewed_by (character varying)
- ✅ reviewed_at (timestamp)
- ✅ approval_notes (text)
- ✅ sale_id (uuid)

### 3. Check foreign keys
```sql
SELECT constraint_name FROM information_schema.table_constraints
WHERE table_name = 'draft_approvals' AND constraint_type = 'FOREIGN KEY';
```

**Should show 2 foreign key constraints**

---

## 🔧 Troubleshooting

### Problem: "Table already exists"
→ Migrations use `IF NOT EXISTS`, safe to re-run

### Problem: "Permission denied"
→ Use admin/service role credentials with proper permissions

### Problem: "Column already exists"
→ Migrations are idempotent, can run multiple times

### Problem: Foreign key constraint error
→ Ensure you're running migrations in the correct order

---

## 📝 Next Steps After Deployment

1. **Configure Shop Settings:**
```sql
UPDATE shops SET 
  state = 'MH',
  gst_mode = 'REGISTERED',
  gst_registration_number = '27AABCT1234H1Z0',
  business_type = 'Retail'
WHERE id = 'shop_001';
```

2. **Test the Complete Workflow:**
   - Send message to Telegram bot: `@Sathiaibeta_bot`
   - Message: `Create bill for customer X: 1 milk ₹50, 1 bread ₹30`
   - Expected: Approval message with tax breakdown
   - Click [✅ APPROVE]
   - Expected: Sale record created

3. **Monitor Database:**
```sql
SELECT approval_id, approval_status, proposed_total, reviewed_by, reviewed_at
FROM draft_approvals
ORDER BY created_at DESC
LIMIT 10;
```

---

## 📋 Migration File Contents

### File 1: add_gst_config.sql
Extends `shops` table with GST configuration fields

### File 2: add_draft_approval.sql
Creates new `draft_approvals` table for approval tracking with complete audit trail

### File 3: add_tax_breakdown.sql
Adds tax tracking fields to `draft_invoices` table

---

## 🎯 Current System Status

| Component | Status |
|-----------|--------|
| Backend (Port 4000) | ✅ Running |
| Telegram Bot | ✅ Running |
| Migrations | ⏳ Ready to deploy |
| Tests | ✅ 26/26 passing |
| Compilation | ✅ Zero errors |

---

## 📞 Support

**After deploying migrations:**

1. Check if schema changes applied: Run verification queries above
2. If issues: Check Supabase dashboard "Activity" tab for errors
3. For RLS setup: See [DATABASE_DEPLOYMENT_GUIDE.md](DATABASE_DEPLOYMENT_GUIDE.md)
4. For rollback: See "Rollback Instructions" in deployment guide

---

**🟢 STATUS: Ready for deployment**

Deploy the migrations now using one of the methods above, then test with the Telegram bot!

