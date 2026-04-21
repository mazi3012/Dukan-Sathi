-- Create draft_approvals table for human-in-loop invoice approval workflow
-- Tracks pending approvals, who approved them, and audit trail

CREATE TABLE IF NOT EXISTS draft_approvals (
  approval_id UUID PRIMARY KEY,
  draft_invoice_id UUID,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_id UUID,
  created_at TIMESTAMP DEFAULT now(),
  proposed_items JSONB NOT NULL,
  proposed_tax_breakdown JSONB NOT NULL,
  proposed_total NUMERIC(12, 2) NOT NULL,
  approval_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  reviewed_by VARCHAR(255),
  reviewed_at TIMESTAMP,
  approval_notes TEXT,
  sale_id UUID UNIQUE,
  updated_at TIMESTAMP DEFAULT now()
);

-- Add constraints
ALTER TABLE draft_approvals
ADD CONSTRAINT draft_approvals_status_check CHECK (
  approval_status IN ('PENDING', 'APPROVED', 'REJECTED', 'MODIFIED')
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_draft_approvals_shop_id ON draft_approvals(shop_id);
CREATE INDEX IF NOT EXISTS idx_draft_approvals_approval_status ON draft_approvals(approval_status);
CREATE INDEX IF NOT EXISTS idx_draft_approvals_created_at ON draft_approvals(created_at);
CREATE INDEX IF NOT EXISTS idx_draft_approvals_reviewed_by ON draft_approvals(reviewed_by);

-- RLS Policy: Only shop owner can view/approve their own drafts
ALTER TABLE draft_approvals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Shop owners can see their own draft approvals"
  ON draft_approvals
  FOR SELECT
  USING (
    shop_id IN (
      SELECT id FROM shops WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Shop owners can update their own draft approvals"
  ON draft_approvals
  FOR UPDATE
  USING (
    shop_id IN (
      SELECT id FROM shops WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Shop owners can insert draft approvals for their shops"
  ON draft_approvals
  FOR INSERT
  WITH CHECK (
    shop_id IN (
      SELECT id FROM shops WHERE owner_id = auth.uid()
    )
  );
