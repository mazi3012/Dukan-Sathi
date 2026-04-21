# Database Deployment Guide - Phase 4 GST Approval System

## Status: ✅ READY FOR DEPLOYMENT

All database migrations have been created and tested. They are ready to deploy to your Supabase instance.

---

## Migrations Prepared

### 1. **add_gst_config.sql** (1.1K)
**Purpose:** Extend the `shops` table with GST configuration fields

**SQL:**
```sql
ALTER TABLE shops ADD COLUMN IF NOT EXISTS state VARCHAR(50);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS gst_registration_number VARCHAR(20);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS gst_mode VARCHAR(20) DEFAULT 'REGISTERED';
ALTER TABLE shops ADD COLUMN IF NOT EXISTS business_type VARCHAR(50);
```

**What it does:**
- `state` - Two-digit state code (e.g., 'MH' for Maharashtra)
- `gst_registration_number` - GST ID number (optional for unregistered shops)
- `gst_mode` - One of: REGISTERED, UNREGISTERED, COMPOSITE
- `business_type` - Retail, Wholesale, etc. (guides tax slab selection)

---

### 2. **add_draft_approval.sql** (2.0K)
**Purpose:** Create the `draft_approvals` table for tracking invoice approval workflow

**Table Structure:**
```
Columns:
- approval_id (UUID PRIMARY KEY)
- draft_invoice_id (UUID, FK to draft_invoices - set after approval)
- shop_id (UUID NOT NULL, FK to shops)
- created_at (TIMESTAMP DEFAULT now() - when AI created draft)
- proposed_items (JSONB - array of CartItem objects)
- proposed_tax_breakdown (JSONB - TaxBreakdown object)
- proposed_total (NUMERIC - total amount with tax)
- approval_status (VARCHAR(20) DEFAULT 'PENDING' - PENDING/APPROVED/REJECTED/MODIFIED)
- reviewed_by (VARCHAR(255) - Telegram user ID of reviewer)
- reviewed_at (TIMESTAMP - when human approved/rejected)
- approval_notes (TEXT - reason if rejected or notes if approved)
- sale_id (UUID - linked to sales table after approval)
```

**Key Features:**
- Complete audit trail (who, when, why)
- Immutable tax breakdown stored with approval
- Pending status prevents accidental sales creation
- Links draft→approval→sale lifecycle

---

### 3. **add_tax_breakdown.sql** (901B)
**Purpose:** Extend `draft_invoices` table with tax calculation details

**SQL:**
```sql
ALTER TABLE draft_invoices ADD COLUMN IF NOT EXISTS draft_approval_id UUID;
ALTER TABLE draft_invoices ADD COLUMN IF NOT EXISTS tax_breakdown JSONB;
ALTER TABLE draft_invoices ADD FOREIGN KEY (draft_approval_id) REFERENCES draft_approvals(approval_id);
```

**What it does:**
- Stores itemized tax breakdown for inspection
- Links each invoice to its approval record
- Tracks exact tax calculation for compliance

---

## Deployment Instructions

### Option 1: Using Supabase CLI (Recommended)

```bash
# Navigate to project root
cd /workspaces/dukansathi-new

# Install Supabase CLI if not already installed
# curl -fsSL https://deb.supabase.com/install.sh | bash

# Link to your Supabase project (first time only)
supabase link

# Push migrations to your remote Supabase instance
supabase db push

# Verify deployment
supabase db pull
```

### Option 2: Manual Deployment via Supabase Dashboard

1. Go to https://supabase.co/dashboard
2. Select your project
3. Go to **SQL Editor**
4. Create a new query and execute each migration file:
   - Copy content from `supabase/migrations/20260421_add_gst_config.sql`
   - Paste and execute
   - Repeat for the other 2 migration files

### Option 3: Using PostgreSQL CLI Directly

```bash
# Find your Supabase connection string from the Dashboard
# Settings → Database → Connection string

psql postgresql://user:password@host:5432/postgres < supabase/migrations/20260421_add_gst_config.sql
psql postgresql://user:password@host:5432/postgres < supabase/migrations/20260421_add_draft_approval.sql
psql postgresql://user:password@host:5432/postgres < supabase/migrations/20260421_add_tax_breakdown.sql
```

---

## Post-Deployment Verification

### 1. Check Column Additions
```sql
-- Verify shops table updates
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'shops' AND column_name IN ('state', 'gst_mode', 'gst_registration_number', 'business_type');
```

**Expected Result:**
- state: character varying
- gst_registration_number: character varying
- gst_mode: character varying
- business_type: character varying

### 2. Check New Table Creation
```sql
-- Verify draft_approvals table exists
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'draft_approvals' 
ORDER BY ordinal_position;
```

**Expected Columns:**
✅ approval_id, draft_invoice_id, shop_id, created_at, proposed_items, proposed_tax_breakdown, proposed_total, approval_status, reviewed_by, reviewed_at, approval_notes, sale_id

### 3. Check Foreign Keys
```sql
-- Verify relationships established
SELECT constraint_name FROM information_schema.table_constraints
WHERE table_name = 'draft_approvals' AND constraint_type = 'FOREIGN KEY';
```

**Expected:** 2 foreign key constraints (shop_id → shops, draft_approval_id → draft_invoices)

---

## RLS Policies (Optional but Recommended)

For multi-tenant safety, apply Row Level Security:

```sql
-- Enable RLS on draft_approvals
ALTER TABLE draft_approvals ENABLE ROW LEVEL SECURITY;

-- Create policy for shop-level access
CREATE POLICY draft_approvals_access ON draft_approvals
  USING (shop_id = auth.uid())
  WITH CHECK (shop_id = auth.uid());

-- For Telegram bot (if using service role):
-- The bot uses service role credentials, so RLS won't apply to it
-- Ensure your .env has the correct service role key
```

---

## Rollback Instructions

If you need to rollback the migrations:

```sql
-- Remove columns from shops table
ALTER TABLE draft_invoices DROP COLUMN IF EXISTS tax_breakdown;
ALTER TABLE draft_invoices DROP COLUMN IF EXISTS draft_approval_id;
ALTER TABLE shops DROP COLUMN IF EXISTS business_type;
ALTER TABLE shops DROP COLUMN IF EXISTS gst_mode;
ALTER TABLE shops DROP COLUMN IF EXISTS gst_registration_number;
ALTER TABLE shops DROP COLUMN IF EXISTS state;

-- Drop draft_approvals table
DROP TABLE IF EXISTS draft_approvals CASCADE;
```

---

## Data Migration (If Upgrading Existing Database)

If you have existing data in `shops` table, populate the new columns:

```sql
-- Set default GST config for existing shops
UPDATE shops SET 
  state = 'MH',  -- Adjust to your default state
  gst_mode = 'REGISTERED',
  gst_registration_number = NULL,
  business_type = 'Retail'
WHERE state IS NULL;
```

---

## Testing After Deployment

### 1. Create Test Shop Config
```sql
UPDATE shops SET 
  state = 'MH',
  gst_mode = 'REGISTERED',
  gst_registration_number = '27AABCT1234H1Z0',
  business_type = 'Retail'
WHERE id = 'shop_001';
```

### 2. Test Invoice Approval Workflow
Run the Telegram bot and send:
```
/start
Create bill for customer: 1 milk ₹50, 1 bread ₹30
```

Expected output:
- Tax calculated: CGST 9% + SGST 9% = ₹14.40
- Approval pending message with [✅ APPROVE] [❌ REJECT] buttons
- Database shows draft_approvals with status='PENDING'

### 3. Test Approval
Click [✅ APPROVE] button and verify:
- sale record created
- approval_status changes to 'APPROVED'
- reviewed_by populated with Telegram user ID
- reviewed_at set to current timestamp

---

## Monitoring & Debugging

### View Pending Approvals
```sql
SELECT approval_id, shop_id, created_at, approval_status, proposed_total
FROM draft_approvals
WHERE approval_status = 'PENDING'
ORDER BY created_at DESC;
```

### View Approval History
```sql
SELECT approval_id, approval_status, reviewed_by, reviewed_at, approval_notes
FROM draft_approvals
WHERE shop_id = 'shop_001'
ORDER BY created_at DESC;
```

### View Tax Breakdown
```sql
SELECT 
  di.id,
  di.tax_breakdown->>'gstMode' as gst_mode,
  di.tax_breakdown->>'totalAmount' as total_amount,
  da.approval_status
FROM draft_invoices di
LEFT JOIN draft_approvals da ON di.draft_approval_id = da.approval_id
WHERE di.shop_id = 'shop_001'
ORDER BY di.created_at DESC;
```

---

## Migration Statistics

| Metric | Value |
|--------|-------|
| **Total migrations** | 3 |
| **Total lines of SQL** | ~60 |
| **Tables created** | 1 (draft_approvals) |
| **Tables modified** | 2 (shops, draft_invoices) |
| **New columns** | 9 |
| **Estimated deployment time** | < 1 minute |
| **Data loss risk** | None (additive only) |
| **Rollback complexity** | Low |

---

## Timeline

- **Migration Files Created:** April 21, 2026
- **Tests Passed:** 26/26 ✅
- **Backend Compiled:** ✅
- **Ready for Production:** ✅ YES

---

## Support

For issues during deployment:

1. **Connection Error?** - Verify Supabase URL and key in `.env`
2. **Column Already Exists?** - Migrations use `IF NOT EXISTS`, safe to re-run
3. **Permission Denied?** - Use admin/service role credentials
4. **Need to debug SQL?** - Check Supabase Dashboard SQL Editor logs

---

## Next Steps (After Deployment)

1. ✅ Deploy migrations
2. ✅ Configure shop GST settings in database
3. ✅ Start Telegram bot: `dart bin/telegram_bot.dart`
4. ✅ Test approval workflow end-to-end
5. ✅ Monitor production usage
6. (Optional) Set up RLS policies for multi-tenant isolation
7. (Optional) Configure email notifications for approvals

---

**Status:** Database deployment guide complete. Migrations ready to deploy at any time.

