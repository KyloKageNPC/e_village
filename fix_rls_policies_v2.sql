-- Migration to fix infinite recursion in RLS policies
-- Run this in your Supabase SQL Editor
-- This version drops ALL existing policies before recreating them

-- =============================================
-- DROP ALL EXISTING POLICIES
-- =============================================

-- Village Groups
DROP POLICY IF EXISTS "Anyone can view active village groups" ON village_groups;
DROP POLICY IF EXISTS "Authenticated users can create village groups" ON village_groups;
DROP POLICY IF EXISTS "Creators can update their village groups" ON village_groups;

-- Group Members
DROP POLICY IF EXISTS "Group members can view their group membership" ON group_members;
DROP POLICY IF EXISTS "Members can view their own membership" ON group_members;
DROP POLICY IF EXISTS "Members can insert themselves into groups" ON group_members;
DROP POLICY IF EXISTS "Group admins can manage members" ON group_members;

-- Savings Accounts
DROP POLICY IF EXISTS "Users can view their own savings accounts" ON savings_accounts;
DROP POLICY IF EXISTS "Users can create their own savings accounts" ON savings_accounts;
DROP POLICY IF EXISTS "System can update savings accounts" ON savings_accounts;

-- Transactions
DROP POLICY IF EXISTS "Users can view their own transactions" ON transactions;
DROP POLICY IF EXISTS "Treasurers can view group transactions" ON transactions;
DROP POLICY IF EXISTS "Users can create their own transactions" ON transactions;

-- Loans
DROP POLICY IF EXISTS "Users can view their own loans" ON loans;
DROP POLICY IF EXISTS "Group members can view group loans" ON loans;
DROP POLICY IF EXISTS "Users can create loan requests" ON loans;

-- Loan Guarantors
DROP POLICY IF EXISTS "Guarantors can view their guarantor requests" ON loan_guarantors;
DROP POLICY IF EXISTS "Guarantors can update their status" ON loan_guarantors;

-- Loan Repayments
DROP POLICY IF EXISTS "Users can view repayments for their loans" ON loan_repayments;

-- Meetings
DROP POLICY IF EXISTS "Group members can view meetings" ON meetings;
DROP POLICY IF EXISTS "Group admins can create meetings" ON meetings;

-- Profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- =============================================
-- CREATE FIXED POLICIES
-- =============================================

-- PROFILES
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- VILLAGE_GROUPS
CREATE POLICY "Anyone can view active village groups"
  ON village_groups FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can create village groups"
  ON village_groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Creators can update their village groups"
  ON village_groups FOR UPDATE
  USING (auth.uid() = created_by);

-- GROUP_MEMBERS (Fixed infinite recursion)
CREATE POLICY "Members can view their own membership"
  ON group_members FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Members can insert themselves into groups"
  ON group_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Group admins can manage members"
  ON group_members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM village_groups
      WHERE id = group_members.group_id
      AND created_by = auth.uid()
    )
  );

-- SAVINGS_ACCOUNTS
CREATE POLICY "Users can view their own savings accounts"
  ON savings_accounts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own savings accounts"
  ON savings_accounts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "System can update savings accounts"
  ON savings_accounts FOR UPDATE
  USING (auth.uid() = user_id);

-- TRANSACTIONS
CREATE POLICY "Users can view their own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Treasurers can view group transactions"
  ON transactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_id = transactions.group_id
      AND user_id = auth.uid()
      AND role IN ('treasurer', 'chairperson')
    )
  );

CREATE POLICY "Users can create their own transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- LOANS
CREATE POLICY "Users can view their own loans"
  ON loans FOR SELECT
  USING (auth.uid() = borrower_id);

CREATE POLICY "Group members can view group loans"
  ON loans FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_id = loans.group_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create loan requests"
  ON loans FOR INSERT
  WITH CHECK (auth.uid() = borrower_id);

-- LOAN_GUARANTORS
CREATE POLICY "Guarantors can view their guarantor requests"
  ON loan_guarantors FOR SELECT
  USING (auth.uid() = guarantor_id);

CREATE POLICY "Guarantors can update their status"
  ON loan_guarantors FOR UPDATE
  USING (auth.uid() = guarantor_id);

-- LOAN_REPAYMENTS
CREATE POLICY "Users can view repayments for their loans"
  ON loan_repayments FOR SELECT
  USING (
    auth.uid() IN (
      SELECT borrower_id FROM loans WHERE id = loan_repayments.loan_id
    )
  );

-- MEETINGS
CREATE POLICY "Group members can view meetings"
  ON meetings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_id = meetings.group_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can create meetings"
  ON meetings FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_id = meetings.group_id
      AND user_id = auth.uid()
      AND role IN ('treasurer', 'chairperson', 'secretary')
    )
  );

-- =============================================
-- VERIFICATION
-- =============================================
-- Run this to verify all policies were created:
-- SELECT schemaname, tablename, policyname
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;
