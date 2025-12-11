-- Diagnostic script to check current policies
-- Run this in Supabase SQL Editor to see what policies exist

-- Show all policies for village_groups
SELECT 'village_groups' as table_name, policyname, cmd, qual::text as using_clause, with_check::text as with_check_clause
FROM pg_policies
WHERE tablename = 'village_groups'
ORDER BY policyname;

-- Show all policies for group_members
SELECT 'group_members' as table_name, policyname, cmd, qual::text as using_clause, with_check::text as with_check_clause
FROM pg_policies
WHERE tablename = 'group_members'
ORDER BY policyname;

-- Show all triggers on village_groups
SELECT tgname as trigger_name, tgtype, proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'village_groups';

-- Show all triggers on group_members
SELECT tgname as trigger_name, tgtype, proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'group_members';
