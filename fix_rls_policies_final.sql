-- FINAL FIX for infinite recursion in RLS policies
-- This version completely disables then re-enables RLS to ensure a clean slate

-- =============================================
-- STEP 1: DISABLE RLS (to bypass all policies during cleanup)
-- =============================================
ALTER TABLE group_members DISABLE ROW LEVEL SECURITY;

-- =============================================
-- STEP 2: DROP ALL POLICIES ON group_members
-- =============================================
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'group_members') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON group_members';
    END LOOP;
END $$;

-- =============================================
-- STEP 3: RE-ENABLE RLS
-- =============================================
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- =============================================
-- STEP 4: CREATE SIMPLE, NON-RECURSIVE POLICIES
-- =============================================

-- Policy 1: Members can view their own membership records
CREATE POLICY "Members can view own membership"
  ON group_members FOR SELECT
  USING (auth.uid() = user_id);

-- Policy 2: Members can add themselves to groups
CREATE POLICY "Members can add themselves"
  ON group_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy 3: Group creators can view all members in their groups
CREATE POLICY "Creators can view group members"
  ON group_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM village_groups vg
      WHERE vg.id = group_members.group_id
      AND vg.created_by = auth.uid()
    )
  );

-- Policy 4: Group creators can add members to their groups
CREATE POLICY "Creators can add members"
  ON group_members FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM village_groups vg
      WHERE vg.id = group_members.group_id
      AND vg.created_by = auth.uid()
    )
  );

-- Policy 5: Group creators can update members in their groups
CREATE POLICY "Creators can update members"
  ON group_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM village_groups vg
      WHERE vg.id = group_members.group_id
      AND vg.created_by = auth.uid()
    )
  );

-- Policy 6: Group creators can delete members from their groups
CREATE POLICY "Creators can delete members"
  ON group_members FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM village_groups vg
      WHERE vg.id = group_members.group_id
      AND vg.created_by = auth.uid()
    )
  );

-- =============================================
-- STEP 5: FIX village_groups POLICIES
-- =============================================

-- Drop all village_groups policies
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'village_groups') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON village_groups';
    END LOOP;
END $$;

-- Create village_groups policies
CREATE POLICY "Anyone can view active groups"
  ON village_groups FOR SELECT
  USING (is_active = true);

CREATE POLICY "Users can create groups"
  ON village_groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Creators can update their groups"
  ON village_groups FOR UPDATE
  USING (auth.uid() = created_by);

-- =============================================
-- VERIFICATION
-- =============================================
-- Run this to verify the policies:
SELECT 'group_members policies:' as info;
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'group_members';

SELECT 'village_groups policies:' as info;
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'village_groups';
