-- ============================================
-- PHASE 2 DATABASE SCHEMA
-- Additional tables for Core Village Banking
-- ============================================

-- 1. Loan Guarantors Table
CREATE TABLE IF NOT EXISTS loan_guarantors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  guarantor_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
  guarantor_name TEXT NOT NULL,
  guaranteed_amount DECIMAL(12, 2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  responded_at TIMESTAMP WITH TIME ZONE,
  response_message TEXT,
  UNIQUE(loan_id, guarantor_id)
);

-- 2. Loan Repayments Table
CREATE TABLE IF NOT EXISTS loan_repayments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  principal_amount DECIMAL(12, 2) NOT NULL,
  interest_amount DECIMAL(12, 2) NOT NULL,
  payment_method TEXT DEFAULT 'cash' CHECK (payment_method IN ('cash', 'mobile_money', 'bank_transfer')),
  payment_reference TEXT,
  notes TEXT,
  created_by UUID REFERENCES user_profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Votes Table (for group decisions)
CREATE TABLE IF NOT EXISTS votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES village_groups(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  vote_type TEXT DEFAULT 'loan_approval' CHECK (vote_type IN ('loan_approval', 'rule_change', 'member_admission', 'expense_approval', 'other')),
  reference_id UUID, -- ID of related entity (loan, member request, etc.)
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_by UUID REFERENCES user_profiles(id) NOT NULL,
  deadline TIMESTAMP WITH TIME ZONE,
  required_approval_percentage DECIMAL(5, 2) DEFAULT 50.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- 4. Vote Responses Table
CREATE TABLE IF NOT EXISTS vote_responses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vote_id UUID REFERENCES votes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
  response TEXT NOT NULL CHECK (response IN ('yes', 'no', 'abstain')),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vote_id, user_id)
);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE loan_guarantors ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_repayments ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE vote_responses ENABLE ROW LEVEL SECURITY;

-- Loan Guarantors Policies
CREATE POLICY "Users can view guarantor requests for their loans" ON loan_guarantors
  FOR SELECT USING (
    guarantor_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM loans
      WHERE loans.id = loan_guarantors.loan_id
      AND (
        loans.borrower_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM group_members
          WHERE group_members.group_id = loans.group_id
          AND group_members.user_id = auth.uid()
          AND group_members.role IN ('treasurer', 'chairperson')
        )
      )
    )
  );

CREATE POLICY "System can create guarantor requests" ON loan_guarantors
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Guarantors can update their own responses" ON loan_guarantors
  FOR UPDATE USING (guarantor_id = auth.uid());

-- Loan Repayments Policies
CREATE POLICY "Users can view repayments for relevant loans" ON loan_repayments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM loans
      WHERE loans.id = loan_repayments.loan_id
      AND (
        loans.borrower_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM group_members
          WHERE group_members.group_id = loans.group_id
          AND group_members.user_id = auth.uid()
          AND group_members.role IN ('treasurer', 'chairperson')
        )
      )
    )
  );

CREATE POLICY "Borrowers and officers can create repayments" ON loan_repayments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM loans
      WHERE loans.id = loan_repayments.loan_id
      AND (
        loans.borrower_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM group_members
          WHERE group_members.group_id = loans.group_id
          AND group_members.user_id = auth.uid()
          AND group_members.role IN ('treasurer', 'chairperson')
        )
      )
    )
    AND created_by = auth.uid()
  );

-- Votes Policies
CREATE POLICY "Group members can view group votes" ON votes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = votes.group_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Officers can create votes" ON votes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = votes.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role IN ('chairperson', 'secretary')
    )
    AND created_by = auth.uid()
  );

CREATE POLICY "Officers can update votes" ON votes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = votes.group_id
      AND group_members.user_id = auth.uid()
      AND group_members.role IN ('chairperson', 'secretary')
    )
  );

-- Vote Responses Policies
CREATE POLICY "Group members can view vote responses" ON vote_responses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM votes
      JOIN group_members ON group_members.group_id = votes.group_id
      WHERE votes.id = vote_responses.vote_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own vote responses" ON vote_responses
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM votes
      JOIN group_members ON group_members.group_id = votes.group_id
      WHERE votes.id = vote_responses.vote_id
      AND group_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own vote responses" ON vote_responses
  FOR UPDATE USING (user_id = auth.uid());

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_loan_guarantors_loan_id ON loan_guarantors(loan_id);
CREATE INDEX IF NOT EXISTS idx_loan_guarantors_guarantor_id ON loan_guarantors(guarantor_id);
CREATE INDEX IF NOT EXISTS idx_loan_guarantors_status ON loan_guarantors(status);

CREATE INDEX IF NOT EXISTS idx_loan_repayments_loan_id ON loan_repayments(loan_id);
CREATE INDEX IF NOT EXISTS idx_loan_repayments_created_at ON loan_repayments(created_at);

CREATE INDEX IF NOT EXISTS idx_votes_group_id ON votes(group_id);
CREATE INDEX IF NOT EXISTS idx_votes_status ON votes(status);
CREATE INDEX IF NOT EXISTS idx_votes_deadline ON votes(deadline);

CREATE INDEX IF NOT EXISTS idx_vote_responses_vote_id ON vote_responses(vote_id);
CREATE INDEX IF NOT EXISTS idx_vote_responses_user_id ON vote_responses(user_id);

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to update loan status when all guarantors approve
CREATE OR REPLACE FUNCTION check_loan_guarantors()
RETURNS TRIGGER AS $$
BEGIN
  -- If all guarantors have approved, update loan status
  IF NOT EXISTS (
    SELECT 1 FROM loan_guarantors
    WHERE loan_id = NEW.loan_id
    AND status = 'pending'
  ) AND EXISTS (
    SELECT 1 FROM loan_guarantors
    WHERE loan_id = NEW.loan_id
    AND status = 'approved'
  ) THEN
    UPDATE loans
    SET status = 'approved',
        updated_at = NOW()
    WHERE id = NEW.loan_id
    AND status = 'pending';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for guarantor approval
CREATE TRIGGER trigger_check_loan_guarantors
AFTER UPDATE ON loan_guarantors
FOR EACH ROW
WHEN (NEW.status = 'approved' OR NEW.status = 'rejected')
EXECUTE FUNCTION check_loan_guarantors();

-- Function to calculate remaining loan balance
CREATE OR REPLACE FUNCTION get_loan_balance(p_loan_id UUID)
RETURNS DECIMAL(12, 2) AS $$
DECLARE
  v_loan_amount DECIMAL(12, 2);
  v_total_repaid DECIMAL(12, 2);
BEGIN
  SELECT amount INTO v_loan_amount
  FROM loans
  WHERE id = p_loan_id;

  SELECT COALESCE(SUM(principal_amount), 0) INTO v_total_repaid
  FROM loan_repayments
  WHERE loan_id = p_loan_id;

  RETURN v_loan_amount - v_total_repaid;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ENABLE REAL-TIME (optional)
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE loan_guarantors;
ALTER PUBLICATION supabase_realtime ADD TABLE loan_repayments;
ALTER PUBLICATION supabase_realtime ADD TABLE votes;
ALTER PUBLICATION supabase_realtime ADD TABLE vote_responses;
