# Quick Start Guide - E-Village Banking App

## 🚀 Get Running in 30 Minutes

### Step 1: Set Up Supabase (20 minutes)

#### 1.1 Create Project
1. Go to https://supabase.com
2. Sign up / Log in
3. Click "New Project"
4. Fill in:
   - **Name**: e-village-banking
   - **Database Password**: (create strong password - SAVE IT!)
   - **Region**: Choose closest to you
5. Click "Create Project"
6. Wait ~2 minutes for setup

#### 1.2 Create Database Tables
1. In Supabase dashboard, click **SQL Editor** (left sidebar)
2. Click "New Query"
3. Open `supabase_schema.sql` file in your project
4. Copy **ALL** contents (Ctrl+A, Ctrl+C)
5. Paste into Supabase SQL Editor
6. Click "Run" (or F5)
7. Wait for "Success. No rows returned"

✅ You now have 10 tables, triggers, policies, and views!

#### 1.3 Get Your API Credentials
1. Go to **Settings** (gear icon, bottom left)
2. Click **API**
3. Copy these two values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public** key: `eyJhbGc...` (long key under "Project API keys")

#### 1.4 (Optional) Create Storage Buckets
1. Go to **Storage** (left sidebar)
2. Click "Create bucket"
3. Create 3 buckets:

**Bucket 1:**
- Name: `profile_images`
- Public: ✓ (checked)

**Bucket 2:**
- Name: `documents`
- Public: ✗ (unchecked)

**Bucket 3:**
- Name: `kyc_documents`
- Public: ✗ (unchecked)

---

### Step 2: Configure Your App (5 minutes)

#### 2.1 Add Supabase Credentials
1. Open your project in VS Code or Android Studio
2. Open `lib/config/supabase_config.dart`
3. Replace placeholders:

```dart
class SupabaseConfig {
  // Replace with YOUR values from Step 1.3
  static const String supabaseUrl = 'https://xxxxx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUz...';

  // Keep these as-is
  static const String profileImagesBucket = 'profile_images';
  static const String documentsBoucket = 'documents';
  static const String kycDocumentsBucket = 'kyc_documents';
}
```

4. Save the file (Ctrl+S)

---

### Step 3: Run the App (5 minutes)

#### 3.1 Install Dependencies (if not done)
```bash
flutter pub get
```

#### 3.2 Start the App
```bash
flutter run
```

Or in VS Code: Press F5

#### 3.3 Test Authentication
1. You should see the **Login Screen**
2. Click "Sign Up"
3. Fill in the form:
   - Full Name: Your Name
   - Email: test@example.com
   - Phone: (optional)
   - Password: password123
   - Confirm: password123
4. Click "Sign Up"
5. You should see success message
6. You'll be redirected to the **Homepage**

#### 3.4 Verify in Supabase
1. Go back to Supabase dashboard
2. Click **Authentication** → **Users**
3. You should see your new user!
4. Click **Table Editor** → **profiles**
5. You should see your profile row!

---

## 🎉 Congratulations!

You now have a working village banking app with:
- ✅ Authentication
- ✅ User profiles
- ✅ Database setup
- ✅ Backend connection

---

## What's Next?

### Option A: Connect Homepage to Real Data (1 hour)

The homepage still shows mock data. To connect it:

1. Open `lib/hompage.dart`
2. Follow instructions in `NEXT_STEPS.md` under "To Connect Homepage to Real Data"
3. Replace hardcoded values with Provider data

### Option B: Create Your First Transaction

Manually add a transaction in Supabase to test:

1. Go to Supabase **Table Editor**
2. Click **transactions** table
3. Click "Insert row"
4. Fill in:
   - `group_id`: Create a test group first (see below)
   - `user_id`: Your user ID (copy from profiles table)
   - `type`: `contribution`
   - `amount`: `1000`
   - `description`: `Initial contribution`
   - `status`: `completed`
5. Click "Save"

To create a test group:
1. Go to **village_groups** table
2. Click "Insert row"
3. Fill in:
   - `name`: `Test Village Group`
   - `created_by`: Your user ID
4. Click "Save"
5. Copy the generated group ID
6. Now create the transaction (steps above)

### Option C: Continue Development

See `NEXT_STEPS.md` for:
- Full implementation roadmap
- Code examples
- Feature priorities

---

## Troubleshooting

### Error: "Invalid API key"
- Check `supabase_config.dart` has correct credentials
- Make sure you copied the **anon** key, not service_role key
- No spaces or extra characters in the keys

### Error: "relation does not exist"
- You didn't run the SQL schema
- Go back to Step 1.2 and run `supabase_schema.sql`

### Error: "Row Level Security policy violation"
- RLS policies are working correctly!
- You need to be logged in to see data
- Make sure you created account in Step 3.3

### Can't sign up / Login fails
- Check Supabase **Authentication** settings
- Go to **Authentication** → **Providers**
- Make sure Email provider is enabled
- Check "Confirm email" is disabled (for testing)

### App crashes on startup
- Make sure you added credentials to `supabase_config.dart`
- Run `flutter clean` then `flutter pub get`
- Restart your IDE

### No data shows on homepage
- Expected! Homepage not connected yet
- See "Option A" above or `NEXT_STEPS.md`

---

## Quick Reference

### Supabase Dashboard Shortcuts
- **SQL Editor**: Run queries, create tables
- **Table Editor**: View/edit data visually
- **Authentication**: Manage users
- **Storage**: Upload/manage files
- **API Docs**: Auto-generated API documentation

### Useful SQL Queries

**See all users:**
```sql
SELECT * FROM profiles;
```

**See all transactions:**
```sql
SELECT * FROM transactions;
```

**See all groups:**
```sql
SELECT * FROM village_groups;
```

**Delete test data:**
```sql
DELETE FROM transactions WHERE description LIKE '%test%';
```

---

## Support

- 📖 Full guide: `SUPABASE_SETUP.md`
- 🗺️ Roadmap: `NEXT_STEPS.md`
- 📊 Architecture: `PROJECT_SUMMARY.md`
- 🐛 Issues: Check console logs first

---

## Checklist

Before you start developing:
- [ ] Supabase project created
- [ ] SQL schema run successfully
- [ ] Credentials added to `supabase_config.dart`
- [ ] `flutter pub get` completed
- [ ] App runs without errors
- [ ] Test account created
- [ ] User shows in Supabase dashboard

You're ready to build! 🚀
