-- Migration: Add secure RLS policies for products, draft_invoices, and expenses
-- Created At: 2026-05-21

-- Create expenses table if it does not exist
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  amount NUMERIC(12, 2) NOT NULL,
  category TEXT NOT NULL DEFAULT 'General',
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_expenses_shop_id ON expenses(shop_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_timestamp ON expenses(timestamp);

-- Enable RLS on all targeted tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE draft_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- -------------------------------------------------------------
-- 1. PRODUCTS RLS POLICIES
-- -------------------------------------------------------------
DROP POLICY IF EXISTS products_read_all ON products;
DROP POLICY IF EXISTS "Shop owners can see their own products" ON products;
DROP POLICY IF EXISTS "Shop owners can insert their own products" ON products;
DROP POLICY IF EXISTS "Shop owners can update their own products" ON products;
DROP POLICY IF EXISTS "Shop owners can delete their own products" ON products;

CREATE POLICY "Shop owners can see their own products"
  ON products
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can insert their own products"
  ON products
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can update their own products"
  ON products
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can delete their own products"
  ON products
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

-- -------------------------------------------------------------
-- 2. DRAFT_INVOICES RLS POLICIES
-- -------------------------------------------------------------
DROP POLICY IF EXISTS draft_invoices_read_all ON draft_invoices;
DROP POLICY IF EXISTS draft_invoices_insert_all ON draft_invoices;
DROP POLICY IF EXISTS "Shop owners can see their own draft_invoices" ON draft_invoices;
DROP POLICY IF EXISTS "Shop owners can insert their own draft_invoices" ON draft_invoices;
DROP POLICY IF EXISTS "Shop owners can update their own draft_invoices" ON draft_invoices;
DROP POLICY IF EXISTS "Shop owners can delete their own draft_invoices" ON draft_invoices;

CREATE POLICY "Shop owners can see their own draft_invoices"
  ON draft_invoices
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can insert their own draft_invoices"
  ON draft_invoices
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can update their own draft_invoices"
  ON draft_invoices
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can delete their own draft_invoices"
  ON draft_invoices
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

-- -------------------------------------------------------------
-- 3. EXPENSES RLS POLICIES
-- -------------------------------------------------------------
DROP POLICY IF EXISTS "Shop owners can see their own expenses" ON expenses;
DROP POLICY IF EXISTS "Shop owners can insert their own expenses" ON expenses;
DROP POLICY IF EXISTS "Shop owners can update their own expenses" ON expenses;
DROP POLICY IF EXISTS "Shop owners can delete their own expenses" ON expenses;

CREATE POLICY "Shop owners can see their own expenses"
  ON expenses
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can insert their own expenses"
  ON expenses
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can update their own expenses"
  ON expenses
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can delete their own expenses"
  ON expenses
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );
