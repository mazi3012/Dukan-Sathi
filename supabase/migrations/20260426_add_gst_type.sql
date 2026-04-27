-- Add gst_type to draft_approvals
ALTER TABLE draft_approvals ADD COLUMN IF NOT EXISTS gst_type VARCHAR(20);
