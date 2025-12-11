-- =============================================
-- CREATE USER PROFILE - MANUAL VERSION
-- =============================================
-- STEP 1: First, find your user ID by running this query:
SELECT
    id,
    email,
    created_at,
    '👆 Copy this ID and use it in STEP 2' as instruction
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- STEP 2: Once you have your ID from above, replace 'YOUR_USER_ID_HERE' below
-- with your actual UUID (the one that matches your email)
-- Then uncomment and run the INSERT statement

-- INSERT INTO user_profiles (
--     id,
--     full_name,
--     phone_number,
--     created_at,
--     updated_at
-- )
-- VALUES (
--     'YOUR_USER_ID_HERE',  -- 👈 REPLACE THIS with your ID from STEP 1
--     'Chileshe Chileshe',
--     NULL,
--     NOW(),
--     NOW()
-- )
-- ON CONFLICT (id) DO UPDATE SET
--     full_name = EXCLUDED.full_name,
--     updated_at = NOW();

-- STEP 3: Verify your profile was created
-- Replace 'YOUR_USER_ID_HERE' with your actual UUID
-- SELECT
--     id,
--     full_name,
--     phone_number,
--     created_at,
--     '✅ Profile exists!' as status
-- FROM user_profiles
-- WHERE id = 'YOUR_USER_ID_HERE';

-- STEP 4: Check your group memberships
-- Replace 'YOUR_USER_ID_HERE' with your actual UUID
-- SELECT
--     vg.name as group_name,
--     gm.role,
--     gm.status
-- FROM group_members gm
-- JOIN village_groups vg ON vg.id = gm.group_id
-- WHERE gm.user_id = 'YOUR_USER_ID_HERE';
