-- Add tax_breakdown column to draft_invoices for storing GST calculation details
-- Links draft_invoices to their approval records

ALTER TABLE draft_invoices ADD COLUMN IF NOT EXISTS tax_breakdown JSONB;
ALTER TABLE draft_invoices ADD COLUMN IF NOT EXISTS draft_approval_id UUID;

-- Add foreign key to link to draft_approvals
-- Add foreign key to link to draft_approvals (create only if table and constraint exist)
DO $$
BEGIN
	IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'draft_approvals' AND relkind = 'r') THEN
		IF NOT EXISTS (
			SELECT 1 FROM information_schema.table_constraints
			WHERE constraint_name = 'fk_draft_invoices_approval' AND table_name = 'draft_invoices'
		) THEN
			ALTER TABLE draft_invoices
			ADD CONSTRAINT fk_draft_invoices_approval FOREIGN KEY (draft_approval_id)
			REFERENCES draft_approvals(approval_id) ON DELETE SET NULL;
		END IF;
	END IF;
END$$;

-- Create index for approval lookups
CREATE INDEX IF NOT EXISTS idx_draft_invoices_approval_id ON draft_invoices(draft_approval_id);

-- Add gst_summary column for quick calculations
ALTER TABLE draft_invoices ADD COLUMN IF NOT EXISTS gst_mode VARCHAR(20);

-- Update existing draft_invoices to link to approvals if they exist
-- (This is a data migration step; new invoices will be linked via approval_tools)
