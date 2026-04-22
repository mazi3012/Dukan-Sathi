-- Fix phone number and UPI columns in shops and onboarding_drafts
-- Migration created on 2026-04-22

-- 1. Fix onboarding_drafts: phone_number should be TEXT to allow any format (we normalize in code, but text is safer)
ALTER TABLE onboarding_drafts ALTER COLUMN phone_number TYPE TEXT;

-- 2. Add phone_number and upi_id to shops table
ALTER TABLE shops ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS upi_id TEXT;
