-- Add GST configuration to shops table
-- Supports: state, GST registration number, GST mode (REGISTERED/UNREGISTERED/COMPOSITE), business type

ALTER TABLE shops ADD COLUMN IF NOT EXISTS state VARCHAR(50);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS gst_registration_number VARCHAR(20);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS gst_mode VARCHAR(20) DEFAULT 'REGISTERED';
ALTER TABLE shops ADD COLUMN IF NOT EXISTS business_type VARCHAR(50) DEFAULT 'Retail';

-- Add constraints
ALTER TABLE shops
ADD CONSTRAINT shops_state_check CHECK (
  state IN (
    'AP', 'AR', 'AS', 'BR', 'CG', 'GA', 'GJ', 'HR', 'HP', 'JK', 'JH', 'KA',
    'KL', 'MP', 'MH', 'MN', 'ML', 'MZ', 'OD', 'PB', 'RJ', 'SK', 'TN', 'TS',
    'TR', 'UP', 'UK', 'WB', 'AN', 'CH', 'DL', 'DD', 'DH', 'JL', 'LA', 'LD', 'PY'
  )
);

ALTER TABLE shops
ADD CONSTRAINT shops_gst_mode_check CHECK (
  gst_mode IN ('REGISTERED', 'UNREGISTERED', 'COMPOSITE')
);

-- Create index for state lookups
CREATE INDEX IF NOT EXISTS idx_shops_state ON shops(state);
CREATE INDEX IF NOT EXISTS idx_shops_gst_mode ON shops(gst_mode);
