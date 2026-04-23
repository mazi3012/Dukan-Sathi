-- Create draft_product_deletions table for human-in-loop product removal

CREATE TABLE IF NOT EXISTS draft_product_deletions (
  id UUID PRIMARY KEY,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  requested_by TEXT,
  requested_at TIMESTAMP DEFAULT now(),
  products JSONB NOT NULL,
  reason TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  reviewed_by TEXT,
  reviewed_at TIMESTAMP,
  approval_notes TEXT,
  deleted_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE draft_product_deletions
ADD CONSTRAINT draft_product_deletions_status_check CHECK (
  status IN ('PENDING', 'APPROVED', 'REJECTED')
);

CREATE INDEX IF NOT EXISTS idx_draft_product_deletions_shop_id ON draft_product_deletions(shop_id);
CREATE INDEX IF NOT EXISTS idx_draft_product_deletions_status ON draft_product_deletions(status);
CREATE INDEX IF NOT EXISTS idx_draft_product_deletions_requested_at ON draft_product_deletions(requested_at);

ALTER TABLE draft_product_deletions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Shop owners can see their own product deletions"
  ON draft_product_deletions
  FOR SELECT
  USING (
    shop_id IN (
      SELECT id FROM shops WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Shop owners can update their own product deletions"
  ON draft_product_deletions
  FOR UPDATE
  USING (
    shop_id IN (
      SELECT id FROM shops WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Shop owners can insert product deletions for their shops"
  ON draft_product_deletions
  FOR INSERT
  WITH CHECK (
    shop_id IN (
      SELECT id FROM shops WHERE owner_id = auth.uid()
    )
  );