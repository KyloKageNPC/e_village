# Supabase Setup Guide for E-Village Banking App

## Step 1: Create Supabase Project

1. Go to [Supabase](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in project details:
   - **Name**: e-village-banking (or your preferred name)
   - **Database Password**: Create a strong password (save it securely)
   - **Region**: Choose closest to your users
5. Wait for project to be created (~2 minutes)

## Step 2: Run Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy the entire contents of `supabase_schema.sql`
4. Paste into the SQL Editor
5. Click "Run" to execute
6. You should see: "Success. No rows returned"

This creates all tables, policies, triggers, and functions needed for the app.

## Step 3: Get API Credentials

1. In Supabase dashboard, go to **Settings** → **API**
2. Copy the following:
   - **Project URL** (e.g., https://xxxxx.supabase.co)
   - **anon/public key** (the long key under "Project API keys")

## Step 4: Configure App

1. Open `lib/config/supabase_config.dart`
2. Replace:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
   with your actual values from Step 3

## Step 5: Create Storage Buckets

1. In Supabase dashboard, go to **Storage**
2. Create three buckets:

### Bucket 1: profile_images
- Name: `profile_images`
- Public: ✓ (checked)
- File size limit: 2MB
- Allowed MIME types: image/jpeg, image/png, image/webp

### Bucket 2: documents
- Name: `documents`
- Public: ✗ (unchecked)
- File size limit: 5MB
- Allowed MIME types: application/pdf, image/jpeg, image/png

### Bucket 3: kyc_documents
- Name: `kyc_documents`
- Public: ✗ (unchecked)
- File size limit: 5MB
- Allowed MIME types: application/pdf, image/jpeg, image/png

## Step 6: Set Up Storage Policies

For each bucket, add RLS policies:

### profile_images policies:
```sql
-- Allow public read
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile_images');

-- Allow authenticated users to upload their own
CREATE POLICY "Users can upload own profile image"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile_images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to update their own
CREATE POLICY "Users can update own profile image"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile_images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### documents policies:
```sql
-- Users can read their own documents
CREATE POLICY "Users can read own documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can upload their own documents
CREATE POLICY "Users can upload own documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### kyc_documents policies:
```sql
-- Users can read their own KYC documents
CREATE POLICY "Users can read own KYC"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'kyc_documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can upload their own KYC documents
CREATE POLICY "Users can upload own KYC"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'kyc_documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

## Step 7: Configure Authentication

1. In Supabase dashboard, go to **Authentication** → **Providers**
2. Enable:
   - ✓ Email (enabled by default)
   - ✓ Phone (optional, for SMS-based auth)
3. Configure email templates:
   - Go to **Authentication** → **Email Templates**
   - Customize "Confirm signup" and "Magic Link" templates as needed

## Step 8: Install Flutter Dependencies

Run in your project directory:
```bash
flutter pub get
```

## Step 9: Initialize Supabase in App

The app will initialize Supabase in `main.dart` when you run it.

## Step 10: Test Connection

Run the app and try to sign up a test user. Check:
1. Supabase dashboard → **Authentication** → **Users** (should see new user)
2. **Table Editor** → **profiles** (should see profile created)

## Database Schema Overview

The schema includes these main tables:

- **profiles**: User profiles (extends auth.users)
- **village_groups**: Village banking groups
- **group_members**: Group membership with roles
- **savings_accounts**: Member savings accounts
- **transactions**: All financial transactions
- **loans**: Loan applications and status
- **loan_guarantors**: Loan guarantors
- **loan_repayments**: Repayment schedules
- **meetings**: Group meetings
- **meeting_attendance**: Meeting attendance tracking

## Security (Row Level Security)

All tables have RLS enabled with policies ensuring:
- Users can only see their own data
- Group members can see group data
- Treasurers/chairpersons have additional permissions
- Data isolation between village groups

## Troubleshooting

### Error: "relation does not exist"
- Run the SQL schema again in SQL Editor

### Error: "JWT expired" or auth errors
- Check your API keys are correct
- Ensure anon key is used (not service_role key)

### Error: "Row Level Security policy violation"
- Check you're logged in
- Verify RLS policies in table editor

### Storage upload fails
- Check bucket exists and is spelled correctly
- Verify storage policies are set up

## Next Steps

After setup:
1. Run `flutter pub get`
2. Update `lib/config/supabase_config.dart` with your credentials
3. Run the app: `flutter run`
4. Test authentication flow

## Useful Supabase Dashboard Links

- **SQL Editor**: Run queries and view data
- **Table Editor**: Browse tables visually
- **Authentication**: View users and settings
- **Storage**: Manage files
- **API Docs**: Auto-generated API documentation
