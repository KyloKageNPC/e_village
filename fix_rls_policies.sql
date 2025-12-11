-- Migration to fix infinite recursion in RLS policies
-- Run this in your Supabase SQL Editor

-- =============================================
-- DROP OLD POLICIES WITH ISSUES
-- =============================================

-- Drop old group_members policies
DROP POLICY IF EXISTS "Group members can view their group membership" ON group_members;

-- Drop old village_groups policies (to add INSERT)
-- Note: We'll recreate the existing SELECT/UPDATE policies

-- Drop old savings_accounts policies (to add INSERT/UPDATE)
-- Note: We'll recreate the existing SELECT policy

-- Drop old transactions policies (to add INSERT and split SELECT)
DROP POLICY IF EXISTS "Users can view their own transactions" ON transactions;

-- Drop old loans policies (to split SELECT)
DROP POLICY IF EXISTS "Users can view their own loans" ON loans;

-- Drop old meetings policies (to add INSERT)
DROP POLICY IF EXISTS "Group members can view meetings" ON meetings;

-- =============================================
-- CREATE FIXED POLICIES
-- =============================================

-- VILLAGE_GROUPS: Add INSERT policy
CREATE POLICY "Authenticated users can create village groups"
  ON village_groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- GROUP_MEMBERS: Fix infinite recursion and add INSERT
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

-- SAVINGS_ACCOUNTS: Add INSERT and UPDATE policies
CREATE POLICY "Users can create their own savings accounts"
  ON savings_accounts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "System can update savings accounts"
  ON savings_accounts FOR UPDATE
  USING (auth.uid() = user_id);

-- TRANSACTIONS: Split policies and add INSERT
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

-- LOANS: Split SELECT policies for clarity
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

-- MEETINGS: Add INSERT policy
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
