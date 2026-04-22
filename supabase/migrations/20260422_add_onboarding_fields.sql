-- Add onboarding fields to shops table

ALTER TABLE shops ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS gst_mode TEXT DEFAULT 'UNREGISTERED';
ALTER TABLE shops ADD COLUMN IF NOT EXISTS gst_registration_number TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS business_type TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS onboarding_started_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS created_by TEXT;

-- Add constraint for GST
-- Add constraint for GST only if it does not already exist
DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_constraint WHERE conname = 'shops_gst_required_if_registered'
	) THEN
		EXECUTE E'ALTER TABLE shops ADD CONSTRAINT shops_gst_required_if_registered '
			|| 'CHECK ((gst_mode != ''REGISTERED'' AND gst_mode != ''COMPOSITE'') '
			|| 'OR (gst_registration_number IS NOT NULL))';
	END IF;
END$$;
