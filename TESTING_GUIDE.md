# Testing Guide - E-Village Banking

This comprehensive guide will help you test all the new features: Offline Mode, Profile & Settings, and Push Notifications.

## Prerequisites

Before testing, ensure:
- [ ] App builds successfully: `flutter build apk --debug` (Android) or `flutter build ios --debug` (iOS)
- [ ] All dependencies installed: `flutter pub get`
- [ ] Supabase is configured and running
- [ ] At least one test user account exists
- [ ] At least one village group is created

---

## Test Environment Setup

### 1. Database Verification

Ensure your Supabase database has the required schema:

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'profiles',
  'village_groups',
  'group_members',
  'savings_accounts',
  'transactions',
  'loans',
  'group_chat_messages'
);

-- Verify RLS policies
SELECT tablename, policyname
FROM pg_policies
WHERE schemaname = 'public';
```

### 2. Test Data Setup

Create test data if needed:

```sql
-- Create test group
INSERT INTO village_groups (name, location, meeting_schedule)
VALUES ('Test Village Group', 'Test Location', 'First Monday of every month');

-- Add user to group (use actual user_id)
INSERT INTO group_members (group_id, user_id, role)
SELECT
  (SELECT id FROM village_groups WHERE name = 'Test Village Group' LIMIT 1),
  auth.uid(),
  'member';
```

---

## Feature Testing

## 1. Offline Mode Testing

### Test 1.1: Cache Viewing (Offline)

**Steps:**
1. Launch app while ONLINE
2. Navigate to home screen
3. Wait for transactions to load
4. Enable Airplane Mode
5. Pull to refresh
6. Navigate away and back to home

**Expected:**
- ✅ Cached transactions still visible
- ✅ Offline indicator shows red banner
- ✅ "Offline mode • Data will sync..." message displays
- ✅ No crash or blank screen

**Status:** [ ] Pass [ ] Fail

---

### Test 1.2: Queue Operations (Offline)

**Steps:**
1. Enable Airplane Mode
2. Try to make a contribution:
   - Tap the green savings button
   - Enter contribution amount
   - Submit
3. Observe offline indicator

**Expected:**
- ✅ Operation queued successfully
- ✅ Orange banner shows "1 operations pending sync"
- ✅ Success message shown to user
- ✅ Operation stored in SQLite database

**Status:** [ ] Pass [ ] Fail

---

### Test 1.3: Auto-Sync (Online)

**Steps:**
1. With pending operations queued (from Test 1.2)
2. Disable Airplane Mode
3. Wait 2-3 seconds
4. Observe offline indicator

**Expected:**
- ✅ Sync starts automatically
- ✅ Shows "Syncing X operations..."
- ✅ Pending count decreases
- ✅ Indicator disappears when sync complete
- ✅ Operations appear in Supabase database

**Status:** [ ] Pass [ ] Fail

---

### Test 1.4: Manual Sync

**Steps:**
1. Enable Airplane Mode
2. Queue 2-3 operations (contributions, messages)
3. Disable Airplane Mode
4. Before auto-sync starts, tap "Sync Now" button

**Expected:**
- ✅ Manual sync triggers immediately
- ✅ All operations sync successfully
- ✅ Progress indicator shown
- ✅ Completion feedback provided

**Status:** [ ] Pass [ ] Fail

---

### Test 1.5: Sync Failure Handling

**Steps:**
1. Queue an operation offline
2. Go online but disconnect Supabase (invalid URL temporarily)
3. Trigger sync
4. Observe behavior

**Expected:**
- ✅ Sync attempts operation
- ✅ Retry count increments on failure
- ✅ Operation remains in queue
- ✅ User notified of sync issue

**Status:** [ ] Pass [ ] Fail

---

### Test 1.6: Cache Management

**Steps:**
1. While online, navigate through app
2. View transactions, loans, messages
3. Go offline
4. Verify all recently viewed data is accessible

**Expected:**
- ✅ Transactions cached (last 50)
- ✅ Loans cached
- ✅ Messages cached (last 100)
- ✅ Savings balance cached
- ✅ Cache updated on each online data fetch

**Status:** [ ] Pass [ ] Fail

---

## 2. Profile & Settings Testing

### Test 2.1: View Profile

**Steps:**
1. Open app drawer (hamburger menu)
2. Tap "Profile & Settings"
3. Review all sections

**Expected:**
- ✅ Profile header shows user info correctly
- ✅ Account information displayed (ID, DOB, Address if set)
- ✅ Current group info shown
- ✅ Notification settings visible
- ✅ App settings section present
- ✅ About & Support section visible

**Status:** [ ] Pass [ ] Fail

---

### Test 2.2: Edit Profile - Valid Data

**Steps:**
1. In Profile & Settings, tap "Edit Profile"
2. Update fields:
   - Full Name: "Test User Updated"
   - Phone: "+1234567890"
   - ID Number: "ID12345"
   - Date of Birth: Select any date
   - Address: "123 Test Street"
3. Tap "Save Changes"

**Expected:**
- ✅ Loading indicator shown
- ✅ Success message appears
- ✅ Returns to Profile & Settings
- ✅ Updated data displayed
- ✅ Changes reflected in Supabase database
- ✅ Changes persist after app restart

**Status:** [ ] Pass [ ] Fail

---

### Test 2.3: Edit Profile - Validation

**Steps:**
1. Tap "Edit Profile"
2. Clear the Full Name field
3. Try to save

**Expected:**
- ✅ Validation error shown
- ✅ "Please enter your full name" message
- ✅ Form not submitted
- ✅ Red border on invalid field

**Status:** [ ] Pass [ ] Fail

---

### Test 2.4: Edit Profile - Error Handling

**Steps:**
1. Tap "Edit Profile"
2. Enable Airplane Mode
3. Update Full Name
4. Tap "Save Changes"

**Expected:**
- ✅ Error message shown
- ✅ "Failed to update profile" or similar
- ✅ Remains on edit screen
- ✅ Data not lost
- ✅ Can retry when online

**Status:** [ ] Pass [ ] Fail

---

### Test 2.5: Notification Settings - Toggle

**Steps:**
1. In Profile & Settings, find Notifications section
2. Toggle "Enable Notifications" OFF
3. Observe UI changes
4. Toggle "Enable Notifications" ON
5. Toggle individual settings (Loan Alerts, Meetings, etc.)

**Expected:**
- ✅ Master toggle hides/shows sub-toggles
- ✅ Each toggle works independently
- ✅ Changes save immediately
- ✅ Settings persist after app restart
- ✅ SharedPreferences updated

**Status:** [ ] Pass [ ] Fail

---

### Test 2.6: Group Information Display

**Steps:**
1. Switch to a different group (if available)
2. Return to Profile & Settings
3. Check "Current Group" section

**Expected:**
- ✅ Shows newly selected group
- ✅ Displays member count correctly
- ✅ Shows user's role
- ✅ Location displayed if set

**Status:** [ ] Pass [ ] Fail

---

### Test 2.7: Logout Functionality

**Steps:**
1. Tap "Logout" button at bottom
2. Confirm in dialog
3. Observe behavior

**Expected:**
- ✅ Confirmation dialog appears
- ✅ "Cancel" dismisses dialog
- ✅ "Logout" signs out user
- ✅ Returns to login screen
- ✅ Back button doesn't return to app
- ✅ User must login again to access

**Status:** [ ] Pass [ ] Fail

---

## 3. Push Notifications Testing

### Setup Check

Before testing, verify:
- [ ] Firebase configured (see FIREBASE_SETUP.md)
- [ ] `google-services.json` in `android/app/`
- [ ] `flutterfire configure` executed
- [ ] `firebase_options.dart` exists in `lib/`
- [ ] App rebuilt after Firebase setup

---

### Test 3.1: Notification Permissions

**Steps:**
1. Fresh install the app
2. Login with user account
3. Observe permission dialog

**Expected:**
- ✅ System asks for notification permission (Android 13+)
- ✅ Granting permission succeeds
- ✅ FCM token generated
- ✅ Token logged to console

**Status:** [ ] Pass [ ] Fail

---

### Test 3.2: Local Notifications - Loan Request

**Steps:**
1. Ensure notifications enabled in settings
2. Request a new loan through the app
3. Wait 1-2 seconds

**Expected:**
- ✅ Local notification appears
- ✅ Title: "New Loan Request"
- ✅ Body includes borrower name and amount
- ✅ Green color/icon for loan category
- ✅ Sound/vibration (if enabled)

**Status:** [ ] Pass [ ] Fail

---

### Test 3.3: Local Notifications - Chat Message

**Steps:**
1. Send a message in group chat
2. Observe notification (may need second device/user)

**Expected:**
- ✅ Notification appears
- ✅ Title: "New Message from [Name]"
- ✅ Body shows message preview
- ✅ Teal color for chat category

**Status:** [ ] Pass [ ] Fail

---

### Test 3.4: Firebase Push - Test Message

**Steps:**
1. Run app and copy FCM token from console:
   ```
   FCM Token: <copy-this-token>
   ```
2. Go to Firebase Console > Cloud Messaging
3. Click "Send your first message"
4. Enter:
   - Title: "Test Notification"
   - Text: "This is a test"
5. Click "Send test message"
6. Paste FCM token
7. Click "Test"

**Expected (App in Foreground):**
- ✅ Local notification shown
- ✅ Title and body match what you sent
- ✅ Notification appears in notification tray

**Expected (App in Background):**
- ✅ System notification shown
- ✅ Tapping notification opens app

**Expected (App Terminated):**
- ✅ System notification shown
- ✅ Tapping notification launches app

**Status:** [ ] Pass [ ] Fail

---

### Test 3.5: Notification Tap Navigation

**Steps:**
1. Generate a loan-related notification
2. Tap the notification

**Expected:**
- ✅ App opens (if closed)
- ✅ Navigates to relevant screen
- ✅ Payload data processed correctly

**Status:** [ ] Pass [ ] Fail

---

### Test 3.6: Notification Settings Effect

**Steps:**
1. In settings, disable "Loan Alerts"
2. Request a new loan
3. Check for notification

**Expected:**
- ✅ No notification appears
- ✅ Loan still created successfully
- ✅ Other notification types still work

**Steps:**
4. Re-enable "Loan Alerts"
5. Request another loan

**Expected:**
- ✅ Notification appears this time

**Status:** [ ] Pass [ ] Fail

---

### Test 3.7: Multiple Notifications

**Steps:**
1. Generate 5+ different notifications quickly:
   - Send messages
   - Request loans
   - Make contributions
2. Check notification tray

**Expected:**
- ✅ All notifications appear
- ✅ Each has correct icon/color
- ✅ Notifications grouped by app (Android)
- ✅ Can dismiss individually
- ✅ "Clear all" works

**Status:** [ ] Pass [ ] Fail

---

## 4. App Drawer Testing

### Test 4.1: Navigation

**Steps:**
1. Open app drawer
2. Tap each menu item
3. Verify navigation

**Expected:**
- ✅ Home navigates correctly
- ✅ Make Contribution opens screen
- ✅ My Loans shows loan list
- ✅ Group Chat opens chat
- ✅ Profile & Settings opens
- ✅ Drawer closes after selection
- ✅ Current screen highlighted

**Status:** [ ] Pass [ ] Fail

---

### Test 4.2: Role-based Menu Items

**Steps:**
1. Login as regular member
2. Open drawer
3. Check for "Loan Approvals"

**Expected:**
- ✅ "Loan Approvals" NOT visible for regular members

**Steps:**
4. Login as Chairperson/Secretary/Treasurer
5. Open drawer

**Expected:**
- ✅ "Loan Approvals" IS visible
- ✅ Tapping opens approval screen

**Status:** [ ] Pass [ ] Fail

---

## 5. Integration Testing

### Test 5.1: Offline to Online Flow

**Steps:**
1. Start app OFFLINE
2. View cached data
3. Queue 3 operations:
   - Make contribution
   - Send chat message
   - Request loan (if UI allows offline)
4. Go ONLINE
5. Wait for auto-sync
6. Verify all operations completed

**Expected:**
- ✅ All cached data visible offline
- ✅ All operations queued
- ✅ Auto-sync completes successfully
- ✅ No data loss
- ✅ Operations appear in database
- ✅ UI updates with fresh data

**Status:** [ ] Pass [ ] Fail

---

### Test 5.2: Profile + Notifications

**Steps:**
1. Update notification preferences in settings
2. Trigger notifications of different types
3. Verify only enabled types appear

**Expected:**
- ✅ Disabled notification types don't show
- ✅ Enabled types appear
- ✅ Preferences persist

**Status:** [ ] Pass [ ] Fail

---

### Test 5.3: Offline + Profile

**Steps:**
1. Go offline
2. Try to update profile
3. Observe behavior

**Expected:**
- ✅ Error message shown
- ✅ User informed of offline state
- ✅ Data not lost
- ✅ Can retry when online

**Status:** [ ] Pass [ ] Fail

---

## Performance Testing

### Test 6.1: App Launch Time

**Steps:**
1. Force close app
2. Time from tap to fully loaded home screen

**Expected:**
- ✅ Launch time < 5 seconds
- ✅ No ANR (Application Not Responding)
- ✅ Smooth initialization

**Status:** [ ] Pass [ ] Fail

---

### Test 6.2: Large Data Sets

**Steps:**
1. Create 100+ transactions
2. Navigate to home screen
3. Scroll through list

**Expected:**
- ✅ Loads within reasonable time (< 3 seconds)
- ✅ Smooth scrolling
- ✅ No lag or stutter
- ✅ Pagination or limit works

**Status:** [ ] Pass [ ] Fail

---

### Test 6.3: Memory Usage

**Steps:**
1. Monitor memory usage (Android Studio Profiler)
2. Navigate through all screens
3. Check for memory leaks

**Expected:**
- ✅ Memory usage stable
- ✅ No continuous growth
- ✅ Proper disposal of resources

**Status:** [ ] Pass [ ] Fail

---

## Error Handling Testing

### Test 7.1: Network Errors

**Steps:**
1. While online, simulate poor connection
2. Try various operations
3. Observe error messages

**Expected:**
- ✅ User-friendly error messages
- ✅ Retry options provided
- ✅ No crashes
- ✅ Graceful degradation

**Status:** [ ] Pass [ ] Fail

---

### Test 7.2: Database Errors

**Steps:**
1. Temporarily break Supabase connection
2. Try to load data
3. Check error handling

**Expected:**
- ✅ Clear error message
- ✅ Fallback to cached data (if available)
- ✅ Retry button works
- ✅ No app crash

**Status:** [ ] Pass [ ] Fail

---

## Regression Testing

### Test 8.1: Existing Features Still Work

Verify these previously implemented features:
- [ ] User authentication (login/signup)
- [ ] Group selection
- [ ] Group chat with voice notes
- [ ] Loan requests
- [ ] Guarantor system
- [ ] Contributions
- [ ] Transaction history
- [ ] Meetings

**Status:** [ ] Pass [ ] Fail

---

## Device Testing

Test on:
- [ ] Android (version 8.0+)
- [ ] iOS (version 12.0+)
- [ ] Different screen sizes
- [ ] Tablet (if supported)

---

## Final Checklist

Before marking as complete:
- [ ] All feature tests passed
- [ ] No critical bugs found
- [ ] Performance acceptable
- [ ] Documentation complete
- [ ] Firebase configured (or documented as optional)
- [ ] Code analyzed: `flutter analyze` shows no errors
- [ ] App builds successfully on all platforms

---

## Reporting Issues

When reporting bugs, include:
1. Device/OS version
2. Steps to reproduce
3. Expected vs actual behavior
4. Screenshots/logs
5. Whether offline/online when issue occurred

---

## Test Summary

**Date Tested:** _________________

**Tested By:** _________________

**Overall Result:** [ ] Pass [ ] Fail

**Notes:**
_____________________________________________
_____________________________________________
_____________________________________________

---

## Automated Testing (Future)

Consider adding:
- Widget tests for UI components
- Integration tests for user flows
- Unit tests for business logic
- Continuous integration setup

Example:
```dart
// test/offline_provider_test.dart
void main() {
  test('Offline provider queues operations', () async {
    final provider = OfflineProvider();
    await provider.addPendingContribution(
      groupId: 'test',
      userId: 'test',
      amount: 100,
    );
    expect(provider.pendingOperationsCount, 1);
  });
}
```

---

**Happy Testing! 🚀**
