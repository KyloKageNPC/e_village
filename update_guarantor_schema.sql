-- ============================================
-- UPDATE LOAN_GUARANTORS TABLE SCHEMA
-- Adds missing columns to match Phase 2 requirements
-- ============================================

-- Add missing columns if they don't exist
ALTER TABLE loan_guarantors 
ADD COLUMN IF NOT EXISTS guarantor_name TEXT,
ADD COLUMN IF NOT EXISTS guaranteed_amount DECIMAL(12, 2),
ADD COLUMN IF NOT EXISTS response_message TEXT,
ADD COLUMN IF NOT EXISTS requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Update existing rows to have requested_at from created_at
UPDATE loan_guarantors 
SET requested_at = created_at 
WHERE requested_at IS NULL;

-- Backfill guarantor_name from profiles table
UPDATE loan_guarantors lg
SET guarantor_name = COALESCE(p.full_name, 'Unknown')
FROM profiles p
WHERE lg.guarantor_id = p.id
AND lg.guarantor_name IS NULL;

-- Set guaranteed_amount to 0 if NULL (temporary, should be updated by application)
UPDATE loan_guarantors 
SET guaranteed_amount = 0.00 
WHERE guaranteed_amount IS NULL;

-- Make columns NOT NULL after backfilling
ALTER TABLE loan_guarantors 
ALTER COLUMN guarantor_name SET NOT NULL,
ALTER COLUMN guaranteed_amount SET NOT NULL;

-- Update status column to use TEXT type if it's using enum
DO $$ 
BEGIN
  -- Check if status is an enum type and convert to TEXT
  IF EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'guarantor_status'
  ) THEN
    ALTER TABLE loan_guarantors 
    ALTER COLUMN status TYPE TEXT USING status::TEXT;
    
    -- Add check constraint
    ALTER TABLE loan_guarantors 
    ADD CONSTRAINT loan_guarantors_status_check 
    CHECK (status IN ('pending', 'approved', 'rejected'));
  END IF;
END $$;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_loan_guarantors_requested_at ON loan_guarantors(requested_at DESC);
CREATE INDEX IF NOT EXISTS idx_loan_guarantors_status ON loan_guarantors(status);
CREATE INDEX IF NOT EXISTS idx_loan_guarantors_guarantor_id ON loan_guarantors(guarantor_id);

-- Display summary
SELECT 
  'Migration complete. Updated ' || COUNT(*) || ' rows in loan_guarantors table.' as summary
FROM loan_guarantors;
