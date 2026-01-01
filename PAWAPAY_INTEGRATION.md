# PawaPay Mobile Money Integration Guide

**Created:** January 1, 2026  
**Status:** 🟡 In Progress (Phase 1 Complete)

---

## 📋 Overview

This document tracks the integration of PawaPay mobile money payments into the E-Village Banking App. PawaPay enables mobile money transactions for Zambia via MTN, Airtel, and Zamtel.

---

## ✅ Phase 1: Foundation (COMPLETED)

### Files Created

| File | Purpose | Status |
|------|---------|--------|
| `lib/config/pawapay_config.dart` | API configuration, provider definitions, phone validation | ✅ Done |
| `lib/services/pawapay_service.dart` | Core API client (deposits, payouts, polling) | ✅ Done |
| `lib/models/pawapay_models.dart` | Data models for transactions and responses | ✅ Done |
| `lib/providers/payment_provider.dart` | State management for payment flows | ✅ Done |
| `lib/widgets/mmo_selector.dart` | UI widgets (provider selector, phone input) | ✅ Done |
| `pawapay_migration.sql` | Database schema for Supabase | ✅ Done |

### Files Modified

| File | Changes | Status |
|------|---------|--------|
| `lib/main.dart` | Added PaymentProvider to MultiProvider | ✅ Done |
| `lib/screens/make_contribution_screen.dart` | Added mobile money payment flow | ✅ Done |

---

## 🔜 Phase 2: Loan Integration (PENDING)

### Files to Modify

| File | Changes Required |
|------|------------------|
| `lib/screens/loan_details_screen.dart` | Add mobile money repayment option |
| `lib/services/loan_service.dart` | Add disbursement payout flow |
| `lib/screens/loan_approvals_screen.dart` | Add disbursement action for approved loans |

---

## 🔜 Phase 3: Withdrawals (PENDING)

### Files to Create

| File | Purpose |
|------|---------|
| `lib/screens/withdrawal_screen.dart` | New screen for member withdrawals |

### Files to Modify

| File | Changes Required |
|------|------------------|
| `lib/widgets/app_drawer.dart` | Add withdrawal menu item |
| `lib/services/savings_service.dart` | Add withdrawal with mobile money |

---

## 🛠️ PawaPay Sandbox Setup

### Step 1: Create Sandbox Account

1. Go to **https://dashboard.sandbox.pawapay.io/#/merchant-signup**
2. Fill in your business details
3. Verify your email
4. Log in to the sandbox dashboard

### Step 2: Generate API Token

1. In the sandbox dashboard, go to **Settings** → **API Tokens**
2. Click **Generate New Token**
3. Copy the token (you won't see it again!)
4. Save it securely

### Step 3: Add Token to App

Open `lib/config/pawapay_config.dart` and update:

```dart
// Line 24 - Replace with your actual sandbox token
static const String sandboxApiToken = 'YOUR_SANDBOX_API_TOKEN_HERE';
```

### Step 4: Run Database Migration

1. Open your **Supabase Dashboard**
2. Go to **SQL Editor**
3. Copy entire contents of `pawapay_migration.sql`
4. Paste and click **Run**
5. Verify tables created:
   - `mobile_money_transactions` ✓
   - `profiles` has new columns (`mobile_money_phone`, `default_mmo_provider`) ✓
   - `transactions` has new columns (`pawapay_id`, `mmo_provider`) ✓

---

## 🧪 Testing with Sandbox

### Test Phone Numbers

PawaPay provides special phone numbers for testing different scenarios:

#### MTN Mobile Money (MTN_MOMO_ZMB)
| Phone Number | Scenario |
|--------------|----------|
| `260760000001` | ✅ Successful payment |
| `260760000002` | ❌ Insufficient funds |
| `260760000003` | ❌ General failure |

#### Airtel Money (AIRTEL_ZMB)
| Phone Number | Scenario |
|--------------|----------|
| `260970000001` | ✅ Successful payment |
| `260970000002` | ❌ Insufficient funds |
| `260970000003` | ❌ General failure |

#### Zamtel Kwacha (ZAMTEL_ZMB)
| Phone Number | Scenario |
|--------------|----------|
| `260950000001` | ✅ Successful payment |
| `260950000002` | ❌ Insufficient funds |
| `260950000003` | ❌ General failure |

### Test Flow: Making a Contribution

1. **Start the app** and log in
2. **Navigate to** Make Contribution screen
3. **Select amount** (e.g., K100)
4. **Select provider** (MTN, Airtel, or Zamtel)
5. **Enter test phone** (e.g., `0760000001` for MTN success)
6. **Click** "Pay with Mobile Money"
7. **Watch** the status dialog:
   - "Processing..." → "Check Your Phone" → "Payment Successful!"

### Sandbox Limitations

⚠️ **Important:** In sandbox mode:
- No real money is transferred
- No actual USSD prompt appears on phone
- Payments auto-complete based on test phone number
- You cannot test the actual PIN entry flow

---

## 📊 Supported Operations

### Deposits (Collect Money)
Used for:
- ✅ Contributions (implemented)
- 🔜 Loan repayments (pending)

### Payouts (Send Money)
Used for:
- 🔜 Loan disbursements (pending)
- 🔜 Savings withdrawals (pending)

---

## 🗄️ Database Schema

### New Table: `mobile_money_transactions`

```sql
CREATE TABLE mobile_money_transactions (
  id UUID PRIMARY KEY,
  pawapay_id UUID NOT NULL UNIQUE,      -- PawaPay transaction ID
  operation_type TEXT NOT NULL,          -- 'deposit' or 'payout'
  user_id UUID REFERENCES profiles(id),
  group_id UUID REFERENCES village_groups(id),
  amount DECIMAL(15, 2) NOT NULL,
  currency TEXT DEFAULT 'ZMW',
  phone_number TEXT NOT NULL,
  mmo_provider TEXT NOT NULL,            -- MTN_MOMO_ZMB, AIRTEL_ZMB, ZAMTEL_ZMB
  status TEXT DEFAULT 'pending',         -- pending, processing, completed, failed
  pawapay_status TEXT,                   -- Raw status from PawaPay
  failure_code TEXT,
  failure_message TEXT,
  reference_type TEXT,                   -- contribution, repayment, disbursement, withdrawal
  reference_id UUID,
  provider_transaction_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE
);
```

### Updated: `profiles` Table

```sql
ALTER TABLE profiles 
ADD COLUMN mobile_money_phone TEXT,
ADD COLUMN default_mmo_provider TEXT;
```

---

## 🔒 Security Notes

1. **API Token Storage**
   - Currently in code for development
   - For production: Use environment variables or secure vault
   - Never commit production tokens to git

2. **Phone Number Privacy**
   - Phone numbers are normalized and stored
   - Consider masking in logs: `260***456`

3. **Request Signing (Production)**
   - PawaPay supports RFC-9421 signatures
   - Recommended for production to prevent token leaks

---

## 🚀 Going to Production

### Checklist

- [ ] Complete sandbox testing for all flows
- [ ] Apply for production access through sandbox dashboard
- [ ] Submit required KYC documents
- [ ] Get production API token
- [ ] Update `pawapay_config.dart`:
  ```dart
  static const bool isSandbox = false;  // Change to false
  static const String productionApiToken = 'YOUR_PRODUCTION_TOKEN';
  ```
- [ ] Set up webhook endpoint (Supabase Edge Function)
- [ ] Test with real phone numbers (small amounts)
- [ ] Monitor transaction success rates

### Production URLs

| Environment | Dashboard | API |
|-------------|-----------|-----|
| Sandbox | dashboard.sandbox.pawapay.io | api.sandbox.pawapay.io |
| Production | dashboard.pawapay.io | api.pawapay.io |

---

## 📞 Zambian MMO Details

| Provider | Code | Phone Prefixes | Currency |
|----------|------|----------------|----------|
| MTN Mobile Money | `MTN_MOMO_ZMB` | 076, 096 | ZMW |
| Airtel Money | `AIRTEL_ZMB` | 097, 077 | ZMW |
| Zamtel Kwacha | `ZAMTEL_ZMB` | 095, 055 | ZMW |

---

## 🐛 Troubleshooting

### "Payment request rejected"
- Check API token is correct
- Verify phone number format (should be 260XXXXXXXXX)
- Ensure provider matches phone prefix

### "Network error"
- Check internet connection
- Verify sandbox URL is accessible
- Check for firewall blocking

### "Invalid phone number"
- Must be 12 digits starting with 260
- Or 10 digits starting with 0 (auto-converted)
- Must match a known provider prefix

### Transaction stuck on "Processing"
- Sandbox auto-completes in ~3 seconds
- If stuck, check PawaPay dashboard for status
- May need to increase polling timeout

---

## 📈 Progress Summary

| Phase | Description | Status | Completion |
|-------|-------------|--------|------------|
| 1 | Foundation & Contributions | ✅ Complete | 100% |
| 2 | Loan Repayments & Disbursements | 🔜 Pending | 0% |
| 3 | Withdrawals | 🔜 Pending | 0% |
| 4 | Webhooks & Production | 🔜 Pending | 0% |

**Overall Mobile Money Integration: ~35% Complete**

---

## 📝 Next Steps

1. **Immediate:** Set up PawaPay sandbox account
2. **Immediate:** Run database migration in Supabase
3. **Immediate:** Add API token to config
4. **Test:** Make a test contribution with sandbox phone
5. **Next Phase:** Integrate with loan repayments
6. **Next Phase:** Add loan disbursement flow
7. **Next Phase:** Create withdrawal screen

---

*Last updated: January 1, 2026*
