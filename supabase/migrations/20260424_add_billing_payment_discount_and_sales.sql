-- Add billing, payment, discount, and sales columns for invoice approval workflow

CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  current_balance NUMERIC(12, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE customers
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE customers
DROP CONSTRAINT IF EXISTS customers_current_balance_check;

ALTER TABLE customers
ADD CONSTRAINT customers_current_balance_check CHECK (current_balance >= 0);

CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_shop_phone ON customers(shop_id, phone);

ALTER TABLE draft_approvals
ADD COLUMN IF NOT EXISTS discount_type VARCHAR(20),
ADD COLUMN IF NOT EXISTS discount_value NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(12, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS subtotal_before_discount NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS subtotal_after_discount NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS original_items JSONB,
ADD COLUMN IF NOT EXISTS original_subtotal NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS customer_state TEXT,
ADD COLUMN IF NOT EXISTS customer_name TEXT,
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'UNPAID',
ADD COLUMN IF NOT EXISTS amount_paid NUMERIC(12, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS due_amount NUMERIC(12, 2) DEFAULT 0;

ALTER TABLE draft_invoices
ADD COLUMN IF NOT EXISTS customer_name TEXT;

ALTER TABLE draft_approvals
DROP CONSTRAINT IF EXISTS draft_approvals_payment_status_check;

ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_payment_status_check CHECK (
  payment_status IN ('PAID', 'PARTIAL', 'UNPAID')
);

ALTER TABLE draft_approvals
DROP CONSTRAINT IF EXISTS draft_approvals_discount_type_check;

ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_discount_type_check CHECK (
  discount_type IS NULL OR discount_type IN ('PERCENT', 'AMOUNT')
);

ALTER TABLE draft_approvals
DROP CONSTRAINT IF EXISTS draft_approvals_amount_paid_check;

ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_amount_paid_check CHECK (amount_paid >= 0);

ALTER TABLE draft_approvals
DROP CONSTRAINT IF EXISTS draft_approvals_due_amount_check;

ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_due_amount_check CHECK (due_amount >= 0);

ALTER TABLE draft_approvals
DROP CONSTRAINT IF EXISTS draft_approvals_discount_value_check;

ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_discount_value_check CHECK (discount_value IS NULL OR discount_value >= 0);

ALTER TABLE draft_approvals
DROP CONSTRAINT IF EXISTS draft_approvals_discount_amount_check;

ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_discount_amount_check CHECK (discount_amount >= 0);

ALTER TABLE draft_approvals
DROP CONSTRAINT IF EXISTS draft_approvals_discount_percent_check;

ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_discount_percent_check CHECK (
  discount_type IS DISTINCT FROM 'PERCENT' OR (discount_value BETWEEN 0 AND 100)
);

ALTER TABLE draft_approvals
DROP CONSTRAINT IF EXISTS draft_approvals_amount_paid_max_check;

ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_amount_paid_max_check CHECK (
  amount_paid <= proposed_total
);

ALTER TABLE draft_approvals
DROP CONSTRAINT IF EXISTS draft_approvals_due_amount_max_check;

ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_due_amount_max_check CHECK (
  due_amount <= proposed_total
);

CREATE INDEX IF NOT EXISTS idx_draft_approvals_payment_status ON draft_approvals(payment_status);

CREATE TABLE IF NOT EXISTS sales (
  id UUID PRIMARY KEY,
  invoice_number TEXT NOT NULL,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  invoice_id UUID NOT NULL,
  customer_id UUID,
  customer_name TEXT,
  customer_state TEXT,
  amount NUMERIC(12, 2) NOT NULL,
  amount_paid NUMERIC(12, 2) NOT NULL DEFAULT 0,
  due_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  payment_status VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
  discount_type VARCHAR(20),
  discount_value NUMERIC(12, 2),
  discount_amount NUMERIC(12, 2) DEFAULT 0,
  subtotal_before_discount NUMERIC(12, 2),
  subtotal_after_discount NUMERIC(12, 2),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  payment_method TEXT NOT NULL DEFAULT 'pending',
  status TEXT DEFAULT 'approved',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE sales
ADD COLUMN IF NOT EXISTS invoice_number TEXT,
ADD COLUMN IF NOT EXISTS customer_id UUID,
ADD COLUMN IF NOT EXISTS customer_name TEXT,
ADD COLUMN IF NOT EXISTS customer_state TEXT,
ADD COLUMN IF NOT EXISTS amount_paid NUMERIC(12, 2) NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS due_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
ADD COLUMN IF NOT EXISTS discount_type VARCHAR(20),
ADD COLUMN IF NOT EXISTS discount_value NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(12, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS subtotal_before_discount NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS subtotal_after_discount NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE sales
DROP CONSTRAINT IF EXISTS sales_payment_status_check;

ALTER TABLE sales
ADD CONSTRAINT sales_payment_status_check CHECK (
  payment_status IN ('PAID', 'PARTIAL', 'UNPAID')
);

ALTER TABLE sales
DROP CONSTRAINT IF EXISTS sales_discount_type_check;

ALTER TABLE sales
ADD CONSTRAINT sales_discount_type_check CHECK (
  discount_type IS NULL OR discount_type IN ('PERCENT', 'AMOUNT')
);

ALTER TABLE sales
DROP CONSTRAINT IF EXISTS sales_amount_paid_check;

ALTER TABLE sales
ADD CONSTRAINT sales_amount_paid_check CHECK (amount_paid >= 0);

ALTER TABLE sales
DROP CONSTRAINT IF EXISTS sales_due_amount_check;

ALTER TABLE sales
ADD CONSTRAINT sales_due_amount_check CHECK (due_amount >= 0);

ALTER TABLE sales
DROP CONSTRAINT IF EXISTS sales_discount_value_check;

ALTER TABLE sales
ADD CONSTRAINT sales_discount_value_check CHECK (discount_value IS NULL OR discount_value >= 0);

ALTER TABLE sales
DROP CONSTRAINT IF EXISTS sales_discount_amount_check;

ALTER TABLE sales
ADD CONSTRAINT sales_discount_amount_check CHECK (discount_amount >= 0);

ALTER TABLE sales
DROP CONSTRAINT IF EXISTS sales_amount_paid_max_check;

ALTER TABLE sales
ADD CONSTRAINT sales_amount_paid_max_check CHECK (amount_paid <= amount);

ALTER TABLE sales
DROP CONSTRAINT IF EXISTS sales_due_amount_max_check;

ALTER TABLE sales
ADD CONSTRAINT sales_due_amount_max_check CHECK (due_amount <= amount);

CREATE INDEX IF NOT EXISTS idx_sales_shop_id ON sales(shop_id);
CREATE INDEX IF NOT EXISTS idx_sales_timestamp ON sales(timestamp);
CREATE INDEX IF NOT EXISTS idx_sales_payment_status ON sales(payment_status);

ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Shop owners can see their own sales" ON sales;
DROP POLICY IF EXISTS "Shop owners can insert their own sales" ON sales;
DROP POLICY IF EXISTS "Shop owners can update their own sales" ON sales;

CREATE POLICY "Shop owners can see their own sales"
  ON sales
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can insert their own sales"
  ON sales
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );

CREATE POLICY "Shop owners can update their own sales"
  ON sales
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM shops
      WHERE owner_id = auth.uid()
        AND id::text = shop_id::text
    )
  );