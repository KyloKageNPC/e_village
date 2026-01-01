-- =====================================================
-- PawaPay Mobile Money Integration - Database Schema
-- =====================================================
-- Run this migration in Supabase SQL Editor
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. Mobile Money Transactions Table
-- =====================================================
-- Tracks all PawaPay transactions (deposits and payouts)

CREATE TABLE IF NOT EXISTS mobile_money_transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  
  -- PawaPay tracking
  pawapay_id UUID NOT NULL UNIQUE,  -- depositId/payoutId from PawaPay
  operation_type TEXT NOT NULL CHECK (operation_type IN ('deposit', 'payout')),
  
  -- User & Group context
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  group_id UUID REFERENCES village_groups(id) ON DELETE SET NULL,
  
  -- Payment details
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  currency TEXT DEFAULT 'ZMW' NOT NULL,
  phone_number TEXT NOT NULL,
  mmo_provider TEXT NOT NULL CHECK (mmo_provider IN ('MTN_MOMO_ZMB', 'AIRTEL_ZMB', 'ZAMTEL_ZMB')),
  
  -- Status tracking
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  pawapay_status TEXT,  -- Raw status from PawaPay: ACCEPTED, COMPLETED, FAILED, etc.
  failure_code TEXT,
  failure_message TEXT,
  
  -- Reference to related entity (what this payment is for)
  reference_type TEXT CHECK (reference_type IN ('contribution', 'repayment', 'disbursement', 'withdrawal')),
  reference_id UUID,    -- ID of contribution/repayment/loan transaction
  
  -- Provider response data
  provider_transaction_id TEXT,
  customer_message TEXT,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_mmt_user_id ON mobile_money_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_mmt_group_id ON mobile_money_transactions(group_id);
CREATE INDEX IF NOT EXISTS idx_mmt_pawapay_id ON mobile_money_transactions(pawapay_id);
CREATE INDEX IF NOT EXISTS idx_mmt_status ON mobile_money_transactions(status);
CREATE INDEX IF NOT EXISTS idx_mmt_reference ON mobile_money_transactions(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_mmt_created_at ON mobile_money_transactions(created_at DESC);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_mobile_money_transactions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_mmt_timestamp ON mobile_money_transactions;
CREATE TRIGGER trigger_update_mmt_timestamp
  BEFORE UPDATE ON mobile_money_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_mobile_money_transactions_updated_at();

-- =====================================================
-- 2. Row Level Security (RLS) Policies
-- =====================================================

ALTER TABLE mobile_money_transactions ENABLE ROW LEVEL SECURITY;

-- Users can view their own transactions
DROP POLICY IF EXISTS "Users can view their own mobile money transactions" ON mobile_money_transactions;
CREATE POLICY "Users can view their own mobile money transactions"
  ON mobile_money_transactions FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own transactions
DROP POLICY IF EXISTS "Users can create their own mobile money transactions" ON mobile_money_transactions;
CREATE POLICY "Users can create their own mobile money transactions"
  ON mobile_money_transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own pending transactions (for status updates)
DROP POLICY IF EXISTS "Users can update their own mobile money transactions" ON mobile_money_transactions;
CREATE POLICY "Users can update their own mobile money transactions"
  ON mobile_money_transactions FOR UPDATE
  USING (auth.uid() = user_id);

-- Group treasurers and chairpersons can view all group transactions
DROP POLICY IF EXISTS "Leaders can view group mobile money transactions" ON mobile_money_transactions;
CREATE POLICY "Leaders can view group mobile money transactions"
  ON mobile_money_transactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members 
      WHERE group_members.group_id = mobile_money_transactions.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role IN ('chairperson', 'treasurer')
    )
  );

-- =====================================================
-- 3. Update Profiles Table (Add mobile money fields)
-- =====================================================

-- Add mobile money phone and default provider to profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS mobile_money_phone TEXT,
ADD COLUMN IF NOT EXISTS default_mmo_provider TEXT CHECK (
  default_mmo_provider IS NULL OR 
  default_mmo_provider IN ('MTN_MOMO_ZMB', 'AIRTEL_ZMB', 'ZAMTEL_ZMB')
);

-- =====================================================
-- 4. Update Transactions Table (Link to mobile money)
-- =====================================================

-- Add PawaPay reference to existing transactions table
ALTER TABLE transactions 
ADD COLUMN IF NOT EXISTS pawapay_id UUID,
ADD COLUMN IF NOT EXISTS mmo_provider TEXT,
ADD COLUMN IF NOT EXISTS mobile_money_phone TEXT;

-- Add foreign key constraint (optional, for data integrity)
-- ALTER TABLE transactions 
-- ADD CONSTRAINT fk_transactions_pawapay 
-- FOREIGN KEY (pawapay_id) REFERENCES mobile_money_transactions(pawapay_id);

-- =====================================================
-- 5. Update Loans Table (For disbursement tracking)
-- =====================================================

ALTER TABLE loans 
ADD COLUMN IF NOT EXISTS disbursement_pawapay_id UUID,
ADD COLUMN IF NOT EXISTS disbursement_phone TEXT,
ADD COLUMN IF NOT EXISTS disbursement_provider TEXT;

-- =====================================================
-- 6. Useful Views
-- =====================================================

-- View for pending mobile money transactions (for reconciliation)
CREATE OR REPLACE VIEW pending_mobile_money_transactions AS
SELECT 
  mmt.*,
  p.full_name as user_name,
  p.email as user_email,
  vg.name as group_name
FROM mobile_money_transactions mmt
LEFT JOIN profiles p ON mmt.user_id = p.id
LEFT JOIN village_groups vg ON mmt.group_id = vg.id
WHERE mmt.status IN ('pending', 'processing')
ORDER BY mmt.created_at DESC;

-- View for transaction summary by group
CREATE OR REPLACE VIEW group_mobile_money_summary AS
SELECT 
  group_id,
  operation_type,
  status,
  COUNT(*) as transaction_count,
  SUM(amount) as total_amount,
  MIN(created_at) as first_transaction,
  MAX(created_at) as last_transaction
FROM mobile_money_transactions
WHERE group_id IS NOT NULL
GROUP BY group_id, operation_type, status;

-- =====================================================
-- 7. Helper Functions
-- =====================================================

-- Function to get user's mobile money transaction history
CREATE OR REPLACE FUNCTION get_user_mobile_money_history(
  p_user_id UUID,
  p_limit INT DEFAULT 50
)
RETURNS SETOF mobile_money_transactions AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM mobile_money_transactions
  WHERE user_id = p_user_id
  ORDER BY created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update transaction status (for webhook/polling updates)
CREATE OR REPLACE FUNCTION update_mobile_money_status(
  p_pawapay_id UUID,
  p_status TEXT,
  p_pawapay_status TEXT,
  p_failure_code TEXT DEFAULT NULL,
  p_failure_message TEXT DEFAULT NULL,
  p_provider_transaction_id TEXT DEFAULT NULL
)
RETURNS mobile_money_transactions AS $$
DECLARE
  v_transaction mobile_money_transactions;
BEGIN
  UPDATE mobile_money_transactions
  SET 
    status = p_status,
    pawapay_status = p_pawapay_status,
    failure_code = p_failure_code,
    failure_message = p_failure_message,
    provider_transaction_id = p_provider_transaction_id,
    completed_at = CASE WHEN p_status IN ('completed', 'failed') THEN NOW() ELSE NULL END
  WHERE pawapay_id = p_pawapay_id
  RETURNING * INTO v_transaction;
  
  RETURN v_transaction;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DONE! 
-- =====================================================
-- After running this migration:
-- 1. Verify tables exist in Supabase dashboard
-- 2. Test RLS policies work correctly
-- 3. Update your Flutter app to use the new tables
-- =====================================================
