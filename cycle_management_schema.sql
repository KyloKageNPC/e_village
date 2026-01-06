-- Cycle Management Database Schema
-- Run this SQL in your Supabase SQL Editor

-- =============================================
-- CYCLES TABLE (Village Banking Lending Cycles)
-- =============================================
CREATE TABLE IF NOT EXISTS cycles (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  group_id UUID REFERENCES village_groups(id) ON DELETE CASCADE NOT NULL,
  cycle_number INTEGER NOT NULL,
  name TEXT NOT NULL, -- e.g., "Cycle 1 - 2024"
  start_date DATE NOT NULL,
  expected_end_date DATE NOT NULL,
  actual_end_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'closed', 'archived')),
  
  -- Financial summary (updated periodically)
  total_contributions DECIMAL(15, 2) DEFAULT 0,
  total_loans_disbursed DECIMAL(15, 2) DEFAULT 0,
  total_interest_earned DECIMAL(15, 2) DEFAULT 0,
  total_penalties_collected DECIMAL(15, 2) DEFAULT 0,
  total_expenses DECIMAL(15, 2) DEFAULT 0,
  net_profit DECIMAL(15, 2) DEFAULT 0,
  
  -- Opening balances (from previous cycle)
  opening_fund_balance DECIMAL(15, 2) DEFAULT 0,
  
  -- Closing balances
  closing_fund_balance DECIMAL(15, 2) DEFAULT 0,
  
  -- Settings for this cycle
  contribution_amount DECIMAL(15, 2), -- Recommended/required contribution per meeting
  max_loan_multiplier DECIMAL(5, 2) DEFAULT 3.0, -- Max loan = savings * multiplier
  default_interest_rate DECIMAL(5, 2) DEFAULT 10.0, -- Monthly interest rate
  late_payment_penalty DECIMAL(5, 2) DEFAULT 5.0, -- Penalty percentage
  
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint: one active cycle per group
CREATE UNIQUE INDEX unique_active_cycle_per_group 
ON cycles(group_id) 
WHERE status = 'active';

-- =============================================
-- CYCLE PROFIT DISTRIBUTIONS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS cycle_profit_distributions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  cycle_id UUID REFERENCES cycles(id) ON DELETE CASCADE NOT NULL,
  member_id UUID REFERENCES profiles(id) NOT NULL,
  
  -- Member's share calculation
  total_contributions DECIMAL(15, 2) NOT NULL, -- Member's total contributions in this cycle
  contribution_percentage DECIMAL(8, 4) NOT NULL, -- Percentage of total pool
  profit_share DECIMAL(15, 2) NOT NULL, -- Calculated profit share
  
  -- Distribution status
  amount_distributed DECIMAL(15, 2) DEFAULT 0,
  distribution_date TIMESTAMP WITH TIME ZONE,
  distribution_method TEXT, -- 'cash', 'mobile_money', 'carry_forward'
  transaction_reference TEXT,
  
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'distributed', 'carried_forward')),
  
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- CYCLE EXPENSES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS cycle_expenses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  cycle_id UUID REFERENCES cycles(id) ON DELETE CASCADE NOT NULL,
  group_id UUID REFERENCES village_groups(id) NOT NULL,
  
  expense_type TEXT NOT NULL, -- 'stationery', 'meeting_venue', 'refreshments', 'other'
  description TEXT NOT NULL,
  amount DECIMAL(15, 2) NOT NULL,
  expense_date DATE NOT NULL,
  receipt_url TEXT,
  
  recorded_by UUID REFERENCES profiles(id),
  approved_by UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- ENABLE RLS
-- =============================================
ALTER TABLE cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_profit_distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_expenses ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS POLICIES FOR CYCLES
-- =============================================
CREATE POLICY "Group members can view cycles"
  ON cycles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = cycles.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.status = 'active'
    )
  );

CREATE POLICY "Group leaders can create cycles"
  ON cycles FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = cycles.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role IN ('chairperson', 'treasurer', 'secretary')
      AND group_members.status = 'active'
    )
  );

CREATE POLICY "Group leaders can update cycles"
  ON cycles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = cycles.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role IN ('chairperson', 'treasurer')
      AND group_members.status = 'active'
    )
  );

-- =============================================
-- RLS POLICIES FOR PROFIT DISTRIBUTIONS
-- =============================================
CREATE POLICY "Members can view their own profit distributions"
  ON cycle_profit_distributions FOR SELECT
  USING (member_id = auth.uid());

CREATE POLICY "Group leaders can view all profit distributions"
  ON cycle_profit_distributions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM cycles
      JOIN group_members ON group_members.group_id = cycles.group_id
      WHERE cycles.id = cycle_profit_distributions.cycle_id
      AND group_members.user_id = auth.uid()
      AND group_members.role IN ('chairperson', 'treasurer')
      AND group_members.status = 'active'
    )
  );

CREATE POLICY "Group leaders can manage profit distributions"
  ON cycle_profit_distributions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM cycles
      JOIN group_members ON group_members.group_id = cycles.group_id
      WHERE cycles.id = cycle_profit_distributions.cycle_id
      AND group_members.user_id = auth.uid()
      AND group_members.role IN ('chairperson', 'treasurer')
      AND group_members.status = 'active'
    )
  );

-- =============================================
-- RLS POLICIES FOR EXPENSES
-- =============================================
CREATE POLICY "Group members can view expenses"
  ON cycle_expenses FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = cycle_expenses.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.status = 'active'
    )
  );

CREATE POLICY "Group leaders can manage expenses"
  ON cycle_expenses FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = cycle_expenses.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role IN ('chairperson', 'treasurer', 'secretary')
      AND group_members.status = 'active'
    )
  );

-- =============================================
-- FUNCTIONS
-- =============================================

-- Function to calculate cycle financial summary
CREATE OR REPLACE FUNCTION calculate_cycle_summary(p_cycle_id UUID)
RETURNS TABLE(
  total_contributions DECIMAL,
  total_loans_disbursed DECIMAL,
  total_interest_earned DECIMAL,
  total_penalties DECIMAL,
  total_expenses DECIMAL,
  net_profit DECIMAL
) AS $$
DECLARE
  v_group_id UUID;
  v_start_date DATE;
  v_end_date DATE;
BEGIN
  -- Get cycle details
  SELECT c.group_id, c.start_date, COALESCE(c.actual_end_date, c.expected_end_date)
  INTO v_group_id, v_start_date, v_end_date
  FROM cycles c
  WHERE c.id = p_cycle_id;

  -- Calculate totals
  SELECT 
    COALESCE(SUM(ca.amount), 0),
    COALESCE((SELECT SUM(l.amount) FROM loans l 
              WHERE l.group_id = v_group_id 
              AND l.status IN ('disbursed', 'active', 'completed')
              AND l.created_at::date >= v_start_date 
              AND l.created_at::date <= v_end_date), 0),
    COALESCE((SELECT SUM(lr.interest_amount) FROM loan_repayments lr
              JOIN loans l ON l.id = lr.loan_id
              WHERE l.group_id = v_group_id
              AND lr.created_at::date >= v_start_date 
              AND lr.created_at::date <= v_end_date), 0),
    0, -- Penalties (would need a penalties table)
    COALESCE((SELECT SUM(ce.amount) FROM cycle_expenses ce 
              WHERE ce.cycle_id = p_cycle_id 
              AND ce.status = 'approved'), 0)
  INTO 
    total_contributions,
    total_loans_disbursed,
    total_interest_earned,
    total_penalties,
    total_expenses
  FROM contribution_accounts ca
  WHERE ca.group_id = v_group_id
  AND ca.created_at::date >= v_start_date 
  AND ca.created_at::date <= v_end_date;

  net_profit := total_interest_earned + total_penalties - total_expenses;
  
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Function to get next cycle number for a group
CREATE OR REPLACE FUNCTION get_next_cycle_number(p_group_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_max_number INTEGER;
BEGIN
  SELECT COALESCE(MAX(cycle_number), 0) + 1
  INTO v_max_number
  FROM cycles
  WHERE group_id = p_group_id;
  
  RETURN v_max_number;
END;
$$ LANGUAGE plpgsql;
