-- =============================================
-- DIAGNOSTIC: Check if chat tables exist
-- =============================================
-- Run this in Supabase SQL Editor to verify your chat setup

-- 1. Check if chat_messages table exists
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'chat_messages'
ORDER BY ordinal_position;

-- 2. Check RLS policies on chat_messages
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'chat_messages';

-- 3. Check if you have group membership (replace YOUR_USER_ID with your actual auth.uid())
-- First, get your user ID:
SELECT auth.uid() as your_user_id;

-- Then check your group memberships:
SELECT
    gm.id,
    gm.group_id,
    gm.user_id,
    gm.role,
    gm.status,
    vg.name as group_name
FROM group_members gm
JOIN village_groups vg ON vg.id = gm.group_id
WHERE gm.user_id = auth.uid();

-- 4. Try to insert a test message (this will show the actual error if there is one)
-- NOTE: Replace these values with your actual IDs:
-- INSERT INTO chat_messages (group_id, sender_id, sender_name, message, type)
-- VALUES (
--   'YOUR_GROUP_ID',
--   auth.uid(),
--   'Test User',
--   'Test message',
--   'text'
-- );

-- 5. Count existing messages
SELECT COUNT(*) as message_count FROM chat_messages;

-- 6. Check if other chat tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE '%message%' OR table_name LIKE '%poll%' OR table_name LIKE '%chat%'
ORDER BY table_name;
