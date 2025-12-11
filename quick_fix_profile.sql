-- =============================================
-- QUICK FIX: Create Your Profile (WITH EMAIL)
-- =============================================
-- Your user ID from the error log: 9cb4992a-8a3c-4b87-95fb-118a907df931

-- Step 1: Get your email from auth.users
SELECT
    id,
    email,
    '👆 This is your user info' as info
FROM auth.users
WHERE id = '9cb4992a-8a3c-4b87-95fb-118a907df931';

-- Step 2: Create profile with email from auth.users
INSERT INTO user_profiles (
    id,
    email,
    full_name,
    phone_number,
    created_at,
    updated_at
)
SELECT
    '9cb4992a-8a3c-4b87-95fb-118a907df931',
    email,  -- Get email from auth.users
    'Chileshe Chileshe',
    NULL,
    NOW(),
    NOW()
FROM auth.users
WHERE id = '9cb4992a-8a3c-4b87-95fb-118a907df931'
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    updated_at = NOW();

-- Step 3: Verify it worked
SELECT
    id,
    email,
    full_name,
    created_at,
    '✅ Profile created successfully!' as status
FROM user_profiles
WHERE id = '9cb4992a-8a3c-4b87-95fb-118a907df931';

-- Step 4: Check your groups
SELECT
    vg.name as group_name,
    gm.role,
    gm.status,
    '✅ You can chat in this group' as info
FROM group_members gm
JOIN village_groups vg ON vg.id = gm.group_id
WHERE gm.user_id = '9cb4992a-8a3c-4b87-95fb-118a907df931';
