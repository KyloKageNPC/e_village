# Village Banking Logic Flow Documentation

## Table of Contents
1. [User Onboarding Flow](#1-user-onboarding-flow)
2. [Group Formation & Management](#2-group-formation--management)
3. [Savings & Contribution System](#3-savings--contribution-system)
4. [Loan Request & Approval Process](#4-loan-request--approval-process)
5. [Guarantor System](#5-guarantor-system)
6. [Loan Repayment System](#6-loan-repayment-system)
7. [Meeting Management](#7-meeting-management)
8. [Financial Cycle & Profit Distribution](#8-financial-cycle--profit-distribution)
9. [Default Management](#9-default-management)
10. [Withdrawal Process](#10-withdrawal-process)
11. [Group Communication](#11-group-communication)
12. [Transaction Types](#12-transaction-types)
13. [Business Rules](#13-business-rules)
14. [State Machines](#14-state-machines)
15. [Role-Based Permissions](#15-role-based-permissions)

---

## 1. User Onboarding Flow

### Flow Diagram
```
┌─────────────────┐
│   New User      │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Sign Up Screen                      │
│ - Full Name                         │
│ - Email                             │
│ - Phone Number                      │
│ - Password                          │
│ - Confirm Password                  │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Email Verification (optional)       │
│ - Send verification link            │
│ - Wait for user to verify           │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Complete Profile Screen             │
│ - ID Number (National ID)           │
│ - Date of Birth                     │
│ - Physical Address                  │
│ - Upload Profile Photo (optional)   │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Group Selection Screen              │
│ Options:                            │
│ 1. Join Existing Group              │
│ 2. Create New Group                 │
│ 3. Browse Groups Near Me            │
└────────┬────────────────────────────┘
         │
         ├───────(Option 1: Join)──────────┐
         │                                  │
         │                                  ▼
         │                   ┌──────────────────────────┐
         │                   │ Browse Groups            │
         │                   │ - Search by name         │
         │                   │ - Filter by location     │
         │                   │ - View group details     │
         │                   └──────────┬───────────────┘
         │                              │
         │                              ▼
         │                   ┌──────────────────────────┐
         │                   │ Request to Join          │
         │                   │ - Select group           │
         │                   │ - Write intro message    │
         │                   │ - Submit request         │
         │                   └──────────┬───────────────┘
         │                              │
         │                              ▼
         │                   ┌──────────────────────────┐
         │                   │ Wait for Approval        │
         │                   │ - Notification sent      │
         │                   │ - Admin reviews          │
         │                   │ - Group votes (optional) │
         │                   └──────────┬───────────────┘
         │                              │
         │                              ▼
         │                   ┌──────────────────────────┐
         │                   │ Approved?                │
         │                   │ - Yes → Active Member    │
         │                   │ - No → Can reapply       │
         │                   └──────────────────────────┘
         │
         └───────(Option 2: Create)─────────┐
                                            │
                                            ▼
                             ┌──────────────────────────┐
                             │ Create Group Screen      │
                             │ - Group Name             │
                             │ - Description            │
                             │ - Location               │
                             │ - Meeting Schedule       │
                             │ - Initial Rules          │
                             │   • Contribution amount  │
                             │   • Meeting frequency    │
                             │   • Loan limits          │
                             └──────────┬───────────────┘
                                        │
                                        ▼
                             ┌──────────────────────────┐
                             │ User becomes Chairperson │
                             │ - Auto-assigned role     │
                             │ - Full admin permissions │
                             │ - Can invite members     │
                             └──────────┬───────────────┘
                                        │
                                        ▼
                             ┌──────────────────────────┐
                             │ Active Member & Admin    │
                             └──────────────────────────┘
```

### Database Operations
```sql
-- On signup
INSERT INTO profiles (id, full_name, phone_number, email)
VALUES (auth_user_id, 'John Doe', '+254712345678', 'john@example.com');

-- On group join
INSERT INTO group_members (group_id, user_id, role, status)
VALUES (group_uuid, user_uuid, 'member', 'pending');

-- On approval
UPDATE group_members
SET status = 'active', joined_at = NOW()
WHERE id = member_id;

-- Create savings account
INSERT INTO savings_accounts (group_id, user_id, balance)
VALUES (group_uuid, user_uuid, 0);
```

### UI Screens Required
1. **SignupScreen** ✅ (Already exists)
2. **CompleteProfileScreen** (New)
3. **GroupSelectionScreen** (New)
4. **BrowseGroupsScreen** (New)
5. **CreateGroupScreen** (New)
6. **JoinRequestScreen** (New)

---

## 2. Group Formation & Management

### Group Creation Flow
```
Chairperson Creates Group
         │
         ▼
┌─────────────────────────────────────┐
│ Set Group Configuration             │
│ - Mandatory Settings:               │
│   • Group name                      │
│   • Location/Village                │
│   • Meeting schedule                │
│   • Minimum members (10-30)         │
│   • Maximum members (20-50)         │
│                                     │
│ - Financial Settings:               │
│   • Minimum contribution            │
│   • Maximum loan amount             │
│   • Interest rate (%)               │
│   • Interest type (flat/declining)  │
│   • Loan duration limits            │
│                                     │
│ - Meeting Rules:                    │
│   • Late arrival fine               │
│   • Absence fine                    │
│   • Attendance requirement (%)      │
│                                     │
│ - Membership Rules:                 │
│   • Joining fee (share capital)     │
│   • Probation period                │
│   • Notice period for withdrawal    │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Invite Members                      │
│ Options:                            │
│ 1. Share group code (e.g., "VBG123")│
│ 2. Send SMS invitations             │
│ 3. Share QR code                    │
│ 4. Email invitations                │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Review Join Requests                │
│ - View applicant profile            │
│ - Check background (optional)       │
│ - Group discussion in chat          │
│ - Vote or admin decision            │
│ - Approve/Reject with reason        │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Elect Officers (When ≥10 members)   │
│ Process:                            │
│ 1. Nominations open                 │
│ 2. Members nominate candidates      │
│ 3. Voting period (e.g., 7 days)     │
│ 4. Each member votes                │
│ 5. Announce results                 │
│                                     │
│ Positions:                          │
│ - Chairperson (1)                   │
│ - Vice Chairperson (1)              │
│ - Treasurer (1)                     │
│ - Secretary (1)                     │
│ - Committee members (2-3)           │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Group is Fully Active               │
│ - Can hold meetings                 │
│ - Can issue loans                   │
│ - Can collect contributions         │
└─────────────────────────────────────┘
```

### Member Management Flow
```
View Members List
         │
         ├────(Actions on Member)────┐
         │                            │
         ▼                            ▼
Change Role                    Change Status
- Member → Treasurer           - Active → Inactive
- Member → Secretary           - Active → Suspended
- Treasurer → Member           - Suspended → Active
  (Requires vote)                (Requires approval)
         │                            │
         ▼                            ▼
View Member Details            Remove Member
- Total savings                - Check no active loans
- Active loans                 - Check no guarantees
- Contribution history         - Settle finances
- Meeting attendance           - Vote to remove
- Performance score            - Disburse final amount
```

### UI Screens Required
1. **GroupSettingsScreen** (New)
2. **InviteMembersScreen** (New)
3. **JoinRequestsListScreen** (New)
4. **ElectionScreen** (New)
5. **MemberManagementScreen** (New)
6. **MemberDetailScreen** (New)

---

## 3. Savings & Contribution System

### Contribution Flow
```
Member Joins Group
         │
         ▼
┌─────────────────────────────────────┐
│ Auto-Create Savings Account         │
│ INSERT INTO savings_accounts        │
│ - group_id                          │
│ - user_id                           │
│ - balance: 0                        │
│ - total_contributions: 0            │
│ - total_withdrawals: 0              │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Contribution Types Set by Group     │
│                                     │
│ 1. Regular Savings                  │
│    - Amount: $10/week               │
│    - Mandatory: Yes                 │
│    - Can be withdrawn: Yes          │
│                                     │
│ 2. Share Capital                    │
│    - Amount: $50 (one-time)         │
│    - Mandatory: Yes                 │
│    - Can be withdrawn: No (locked)  │
│                                     │
│ 3. Social Fund                      │
│    - Amount: $5/month               │
│    - Mandatory: Optional            │
│    - Purpose: Emergencies/welfare   │
│                                     │
│ 4. Voluntary Savings                │
│    - Amount: Any                    │
│    - Mandatory: No                  │
│    - Can be withdrawn: Yes          │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Member Makes Contribution           │
│                                     │
│ At Meeting:                         │
│ - Physical cash to treasurer        │
│ - Treasurer records in app          │
│ - Receipt generated                 │
│                                     │
│ Via Mobile Money:                   │
│ - Member initiates payment          │
│ - Payment confirmed                 │
│ - Auto-recorded in system           │
│                                     │
│ Via Bank Transfer:                  │
│ - Transfer to group account         │
│ - Treasurer verifies                │
│ - Manual recording                  │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Record Transaction                  │
│ INSERT INTO transactions            │
│ - type: 'contribution'              │
│ - amount: $10                       │
│ - user_id                           │
│ - group_id                          │
│ - description: 'Weekly savings'     │
│ - status: 'completed'               │
│ - transaction_date: NOW()           │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Update Balances                     │
│                                     │
│ UPDATE savings_accounts             │
│ SET balance = balance + $10,        │
│     total_contributions += $10      │
│ WHERE user_id = member              │
│                                     │
│ UPDATE group_summary                │
│ SET total_fund = total_fund + $10   │
│ WHERE group_id = group              │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Generate Receipt                    │
│ - Transaction ID                    │
│ - Date & Time                       │
│ - Amount                            │
│ - New balance                       │
│ - Treasurer signature (digital)     │
│ - Can download/share PDF            │
└─────────────────────────────────────┘
```

### Contribution Schedule & Reminders
```
Group Sets Schedule:
- Frequency: Weekly/Monthly
- Due Date: Every Monday
- Reminder: 2 days before
         │
         ▼
System Sends Reminders:
Day -2: "Contribution due in 2 days"
Day -1: "Contribution due tomorrow"
Day 0: "Contribution due today"
Day +1: "Contribution overdue! Late fine applies"
         │
         ▼
If Not Paid After Grace Period:
- Apply late fine
- Mark as missed contribution
- Affect member's credit score
- Notify group leaders
```

### UI Screens Required
1. **ContributionScreen** (New)
2. **MakeContributionScreen** (New)
3. **ContributionHistoryScreen** (New)
4. **SavingsAccountScreen** (New)
5. **ReceiptScreen** (New)
6. **ContributionScheduleScreen** (New)

---

## 4. Loan Request & Approval Process

### Complete Loan Lifecycle
```
┌─────────────────────────────────────┐
│ STEP 1: Eligibility Check           │
│                                     │
│ Member Clicks "Request Loan"        │
│         ↓                           │
│ System Validates:                   │
│ ✓ Active member ≥ 3 months          │
│ ✓ No current active loan            │
│ ✓ Savings ≥ $100 (minimum)          │
│ ✓ Attendance ≥ 80%                  │
│ ✓ No defaults in history            │
│ ✓ Not a guarantor with risk         │
│         ↓                           │
│ IF ALL PASS → Show loan form        │
│ IF ANY FAIL → Show reason & advice  │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ STEP 2: Loan Application Form       │
│                                     │
│ Loan Details:                       │
│ - Amount Requested: $______         │
│   (Max: 3x savings = $300)          │
│                                     │
│ - Purpose: [Dropdown]               │
│   • Business expansion              │
│   • School fees                     │
│   • Medical emergency               │
│   • Agriculture/farming             │
│   • Home improvement                │
│   • Other (specify)                 │
│                                     │
│ - Business Description: ______      │
│   (If purpose is business)          │
│                                     │
│ - Repayment Period: [1-12 months]   │
│                                     │
│ - Select Guarantors:                │
│   [Search members]                  │
│   Guarantor 1: _____ (required)     │
│   Guarantor 2: _____ (required)     │
│   Guarantor 3: _____ (optional)     │
│                                     │
│ - Supporting Documents:             │
│   [Upload] Business plan (optional) │
│   [Upload] Invoice/quotation        │
│                                     │
│ Auto-Calculated Display:            │
│ - Interest Rate: 10% flat           │
│ - Total Interest: $30               │
│ - Total Repayable: $330             │
│ - Monthly Payment: $33              │
│                                     │
│ [Preview] [Submit Application]      │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ STEP 3: Guarantor Approval          │
│                                     │
│ INSERT INTO loans                   │
│ - status: 'pending'                 │
│                                     │
│ INSERT INTO loan_guarantors         │
│ - status: 'pending' (for each)      │
│                                     │
│ Send Notifications:                 │
│ → Guarantor 1: "John requested you  │
│    as guarantor for $300 loan"      │
│ → Guarantor 2: (same)               │
│         ↓                           │
│ Guarantor Opens App:                │
│ - View loan details                 │
│ - View borrower's history           │
│ - Current savings: $100             │
│ - Previous loans: 2 (all repaid)    │
│ - Attendance: 95%                   │
│                                     │
│ Guarantor Decision:                 │
│ [Approve] [Reject] [Request Info]   │
│         ↓                           │
│ If Approve:                         │
│ - UPDATE loan_guarantors            │
│   SET status = 'approved'           │
│                                     │
│ If Reject:                          │
│ - Loan status → 'rejected'          │
│ - Notify borrower                   │
│ - Can reapply with different        │
│   guarantors                        │
│         ↓                           │
│ Check All Guarantors:               │
│ IF all approved → Next step         │
│ IF timeout (3 days) → Auto-reject   │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ STEP 4: Group Discussion            │
│                                     │
│ Post to Group Chat:                 │
│ "🔔 New Loan Request"               │
│ Borrower: John Doe                  │
│ Amount: $300                        │
│ Purpose: School fees                │
│ Duration: 10 months                 │
│ Guarantors: ✓ Jane, ✓ Peter         │
│                                     │
│ [View Full Details] [Discuss]       │
│         ↓                           │
│ Members Can:                        │
│ - Ask questions in chat             │
│ - Voice concerns                    │
│ - Share opinions                    │
│ - Send voice notes                  │
│         ↓                           │
│ Discussion Period: 2-7 days         │
│ (Or until next meeting)             │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ STEP 5: Group Meeting Vote          │
│                                     │
│ At Physical/Virtual Meeting:        │
│ 1. Treasurer presents loan request  │
│ 2. Borrower explains (if present)   │
│ 3. Guarantors confirm commitment    │
│ 4. Members discuss                  │
│ 5. Vote taken                       │
│         ↓                           │
│ Voting Methods:                     │
│ Option A: In-app voting             │
│ - Each member votes via app         │
│ - Real-time results                 │
│ - Requires quorum (e.g., 60%)       │
│                                     │
│ Option B: Physical show of hands    │
│ - Secretary records in app          │
│ - Manual entry of votes             │
│                                     │
│ Voting Results:                     │
│ - Yes: 15 members                   │
│ - No: 2 members                     │
│ - Abstain: 1 member                 │
│         ↓                           │
│ Decision Logic:                     │
│ IF (Yes votes > 50%) → APPROVED     │
│ ELSE → REJECTED                     │
│         ↓                           │
│ UPDATE loans                        │
│ SET status = 'approved',            │
│     approved_by = chairperson_id,   │
│     approved_at = NOW()             │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ STEP 6: Loan Disbursement           │
│                                     │
│ Treasurer Action Required:          │
│ - Verify group fund has $300        │
│ - Check cash flow                   │
│ - Confirm borrower account          │
│         ↓                           │
│ Disbursement Methods:               │
│ Option 1: Cash at meeting           │
│ - Count cash                        │
│ - Borrower signs receipt            │
│ - Witnesses sign                    │
│                                     │
│ Option 2: Mobile money transfer     │
│ - Transfer to borrower's phone      │
│ - Confirmation screenshot           │
│ - Transaction ID recorded           │
│                                     │
│ Option 3: Bank transfer             │
│ - Transfer to bank account          │
│ - Share bank receipt                │
│         ↓                           │
│ Record in System:                   │
│ INSERT INTO transactions            │
│ - type: 'loan_disbursement'         │
│ - amount: $300                      │
│ - reference_id: loan.id             │
│                                     │
│ UPDATE loans                        │
│ SET status = 'active',              │
│     disbursed_at = NOW(),           │
│     due_date = NOW() + 10 months    │
│                                     │
│ Generate Repayment Schedule:        │
│ INSERT INTO loan_repayments (10x)   │
│ Month 1: $33 due Jan 1              │
│ Month 2: $33 due Feb 1              │
│ ... Month 10: $33 due Oct 1         │
│         ↓                           │
│ Send to Borrower:                   │
│ - Loan agreement (PDF)              │
│ - Repayment schedule                │
│ - SMS/Email confirmation            │
│         ↓                           │
│ Setup Auto-Reminders:               │
│ - 7 days before due date            │
│ - 3 days before due date            │
│ - On due date                       │
│ - 1 day after (if unpaid)           │
└─────────────────────────────────────┘
```

### Loan Calculation Logic
```dart
// Flat Interest Calculation
class LoanCalculator {
  static LoanDetails calculateFlat({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    // Interest = Principal × Rate × (Months/12)
    final interest = principal * (annualRate / 100) * (months / 12);
    final totalRepayable = principal + interest;
    final monthlyPayment = totalRepayable / months;

    return LoanDetails(
      principal: principal,
      interest: interest,
      totalRepayable: totalRepayable,
      monthlyPayment: monthlyPayment,
    );
  }

  // Declining Balance Calculation
  static LoanDetails calculateDeclining({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    final monthlyRate = annualRate / 100 / 12;
    double totalInterest = 0;
    double remainingBalance = principal;

    List<Installment> schedule = [];

    for (int i = 1; i <= months; i++) {
      final interestPayment = remainingBalance * monthlyRate;
      final principalPayment = (principal / months);
      final totalPayment = principalPayment + interestPayment;

      totalInterest += interestPayment;
      remainingBalance -= principalPayment;

      schedule.add(Installment(
        month: i,
        principal: principalPayment,
        interest: interestPayment,
        total: totalPayment,
        balance: remainingBalance,
      ));
    }

    return LoanDetails(
      principal: principal,
      interest: totalInterest,
      totalRepayable: principal + totalInterest,
      monthlyPayment: (principal + totalInterest) / months,
      schedule: schedule,
    );
  }
}

// Example Usage:
// Loan: $1000, 10% annual, 10 months
// Flat: Total = $1000 + ($1000 × 10% × 10/12) = $1083.33
// Monthly = $1083.33 / 10 = $108.33

// Declining: Interest decreases each month
// Month 1: Interest = $1000 × (10%/12) = $8.33
// Month 2: Interest = $900 × (10%/12) = $7.50
// Month 3: Interest = $800 × (10%/12) = $6.67
// ... and so on
```

### UI Screens Required
1. **LoanEligibilityScreen** (New)
2. **LoanApplicationScreen** (New)
3. **LoanCalculatorScreen** (New)
4. **GuarantorSelectionScreen** (New)
5. **GuarantorApprovalScreen** (New)
6. **LoanDiscussionScreen** (Part of group chat)
7. **LoanVotingScreen** (New)
8. **LoanDisbursementScreen** (New - Treasurer only)
9. **MyLoansScreen** (New)
10. **LoanDetailsScreen** (New)
11. **RepaymentScheduleScreen** (New)

---

## 5. Guarantor System

### Guarantor Selection Logic
```
Member Requesting Loan Selects Guarantors
         │
         ▼
┌─────────────────────────────────────┐
│ Guarantor Eligibility Check         │
│                                     │
│ Valid Guarantor Must:               │
│ ✓ Be active member                  │
│ ✓ Have savings ≥ $50                │
│ ✓ Not have active loan              │
│ ✓ Not be guarantor for >3 loans     │
│ ✓ Good standing (no defaults)       │
│ ✓ Not related to borrower (optional)│
│                                     │
│ System Shows:                       │
│ - Eligible members (green)          │
│ - Ineligible members (gray + reason)│
│                                     │
│ Guarantor's Current Load:           │
│ "Jane is guarantor for 2 loans      │
│  Total liability: $500"             │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Guarantor Notification              │
│                                     │
│ Push Notification:                  │
│ "🔔 Guarantee Request"              │
│ "John Doe requested you as guarantor│
│  for a $300 loan"                   │
│ [View Details]                      │
│         ↓                           │
│ In-App Notification:                │
│ Red badge on notifications icon     │
│         ↓                           │
│ SMS (Optional):                     │
│ "Guarantee request from John. Check │
│  E-Village app for details."        │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Guarantor Review Screen             │
│                                     │
│ Loan Information:                   │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Borrower: John Doe                  │
│ Amount: $300                        │
│ Purpose: School fees                │
│ Duration: 10 months                 │
│ Monthly Payment: $33                │
│ Total Repayable: $330               │
│                                     │
│ Your Liability:                     │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ If borrower defaults, you'll pay:   │
│ • Up to $110 (⅓ of remaining)       │
│ • Deducted from your savings        │
│                                     │
│ Borrower's Track Record:            │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ 📊 Previous Loans: 2                │
│    ✓ $200 - Repaid on time          │
│    ✓ $150 - Repaid on time          │
│ 💰 Current Savings: $120             │
│ 📅 Member Since: Jan 2023            │
│ ✓ Attendance: 95% (19/20 meetings)  │
│ ⭐ Rating: 4.8/5.0                   │
│                                     │
│ Other Guarantors:                   │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ ✓ Jane Smith (Approved)             │
│ ⏳ Peter Brown (Pending)             │
│                                     │
│ [Ask Question in Chat]              │
│ [Request More Info]                 │
│                                     │
│ Your Decision:                      │
│ [✓ Approve] [✗ Reject]              │
│                                     │
│ If Rejecting, Reason (optional):    │
│ [ ] Too risky                       │
│ [ ] Already guaranteed too many     │
│ [ ] Don't know borrower well        │
│ [ ] Other: _______________          │
└─────────────────────────────────────┘
```

### Guarantor Liability Management
```
Borrower Defaults (3+ months overdue)
         │
         ▼
┌─────────────────────────────────────┐
│ System Triggers Default Process     │
│                                     │
│ Loan Details:                       │
│ - Original: $300                    │
│ - Repaid: $100                      │
│ - Outstanding: $200                 │
│ - Guarantors: 3 people              │
│         ↓                           │
│ Calculate Liability Per Guarantor:  │
│ $200 ÷ 3 = $66.67 each              │
│         ↓                           │
│ Check Each Guarantor's Savings:     │
│ Guarantor 1 (Jane): $150 ✓          │
│ Guarantor 2 (Peter): $80 ✓          │
│ Guarantor 3 (Mary): $40 ✗ (short)   │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Notification to Guarantors          │
│                                     │
│ "⚠️ Loan Default Alert"             │
│ "John Doe's loan is in default.     │
│  You are required to pay $66.67"    │
│                                     │
│ Options:                            │
│ 1. Pay Now (from savings)           │
│ 2. Request Payment Plan             │
│ 3. Contest (provide evidence)       │
│                                     │
│ Deadline: 7 days                    │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Deduction Process                   │
│                                     │
│ For Each Guarantor:                 │
│                                     │
│ UPDATE savings_accounts             │
│ SET balance = balance - $66.67      │
│ WHERE user_id = guarantor           │
│                                     │
│ INSERT INTO transactions            │
│ - type: 'guarantor_payment'         │
│ - amount: $66.67                    │
│ - description: 'Paid for John's     │
│   defaulted loan'                   │
│ - reference_id: loan.id             │
│         ↓                           │
│ Group Fund Restored:                │
│ UPDATE group total_fund             │
│ SET balance = balance + $200        │
│         ↓                           │
│ Update Guarantor Status:            │
│ - Cannot borrow until recovered     │
│ - Can recover from defaulter        │
│ - Affects credit score              │
└─────────────────────────────────────┘
```

### Guarantor Recovery Process
```
Guarantor Paid for Defaulter
         │
         ▼
┌─────────────────────────────────────┐
│ Recovery Options                    │
│                                     │
│ 1. Direct Recovery:                 │
│    - Guarantors can collect from    │
│      defaulter personally           │
│    - Group supports recovery        │
│                                     │
│ 2. Installment Plan:                │
│    - Defaulter agrees to repay      │
│      guarantors                     │
│    - System tracks recovery         │
│                                     │
│ 3. Asset Seizure (if agreed):       │
│    - Group can seize collateral     │
│    - Sell to recover funds          │
│                                     │
│ 4. Legal Action:                    │
│    - Last resort                    │
│    - Small claims court             │
└─────────────────────────────────────┘
```

### UI Screens Required
1. **GuarantorDashboardScreen** (New)
2. **MyGuaranteesScreen** (New)
3. **GuaranteeRequestDetailScreen** (New)
4. **GuarantorLiabilityScreen** (New)
5. **DefaultNotificationScreen** (New)

---

## 6. Loan Repayment System

### Repayment Flow
```
┌─────────────────────────────────────┐
│ Automatic Repayment Reminders       │
│                                     │
│ Schedule for Each Installment:      │
│                                     │
│ Day -7: "💰 Reminder"               │
│ "Your loan payment of $33 is due    │
│  in 7 days (Jan 1)"                 │
│                                     │
│ Day -3: "⏰ Reminder"               │
│ "Loan payment due in 3 days"        │
│                                     │
│ Day 0: "📅 Due Today"               │
│ "Your $33 payment is due today"     │
│ [Pay Now]                           │
│                                     │
│ Day +1: "⚠️ Overdue"                │
│ "Payment overdue! Late fee: $2"     │
│ Total due: $35                      │
│ [Pay Now]                           │
│                                     │
│ Day +7: "🚨 Serious Default"        │
│ "Payment 7 days overdue"            │
│ "Guarantors will be notified"       │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Member Makes Payment                │
│                                     │
│ Payment Methods:                    │
│                                     │
│ 1. At Meeting (Cash):               │
│    - Give cash to treasurer         │
│    - Treasurer records in app       │
│    - Receipt generated              │
│                                     │
│ 2. Mobile Money:                    │
│    - Member initiates transfer      │
│    - To group's mobile money        │
│    - Screenshot confirmation        │
│    - Treasurer verifies             │
│    - Records in app                 │
│                                     │
│ 3. Bank Transfer:                   │
│    - Transfer to group account      │
│    - Reference: Loan ID             │
│    - Upload bank receipt            │
│    - Treasurer confirms             │
│                                     │
│ 4. Auto-Debit (Future):             │
│    - Pre-authorized deduction       │
│    - From member's savings          │
│    - On due date                    │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Record Payment in System            │
│                                     │
│ Step 1: Create Transaction          │
│ INSERT INTO transactions            │
│ {                                   │
│   type: 'loan_repayment',           │
│   amount: $33,                      │
│   user_id: borrower,                │
│   group_id: group,                  │
│   reference_id: loan.id,            │
│   description: 'Loan repayment      │
│     Month 1 of 10',                 │
│   status: 'completed'               │
│ }                                   │
│         ↓                           │
│ Step 2: Update Loan Record          │
│ UPDATE loans                        │
│ SET amount_repaid = amount_repaid + │
│     $33,                            │
│     balance = balance - $33         │
│ WHERE id = loan.id                  │
│         ↓                           │
│ Step 3: Update Installment          │
│ UPDATE loan_repayments              │
│ SET status = 'paid',                │
│     amount_paid = $33,              │
│     paid_at = NOW()                 │
│ WHERE loan_id = loan.id             │
│   AND installment_number = 1        │
│         ↓                           │
│ Step 4: Update Group Fund           │
│ Principal ($30) → Back to fund      │
│ Interest ($3) → Group profit        │
│         ↓                           │
│ Step 5: Check Loan Status           │
│ IF balance = 0:                     │
│   UPDATE loans                      │
│   SET status = 'completed',         │
│       completed_at = NOW()          │
│         ↓                           │
│ Step 6: Generate Receipt            │
│ - Payment amount: $33               │
│ - Remaining balance: $297           │
│ - Next payment due: Feb 1           │
│ - Download PDF                      │
│         ↓                           │
│ Step 7: Send Confirmation           │
│ "✅ Payment Received"               │
│ "Thank you! $33 recorded"           │
│ "Remaining: $297"                   │
│ "Next due: Feb 1"                   │
└─────────────────────────────────────┘
```

### Partial Payment Handling
```
Member Pays $20 (Less than $33 due)
         │
         ▼
┌─────────────────────────────────────┐
│ Partial Payment Logic               │
│                                     │
│ Option A: Apply to Current          │
│ - Current installment: $33          │
│ - Payment: $20                      │
│ - Remaining for this month: $13     │
│ - Status: 'partial'                 │
│ - Next month still due: $33         │
│                                     │
│ Option B: Cascade Forward           │
│ - Current installment: $33          │
│ - Payment: $20                      │
│ - Applied: $20 to month 1           │
│ - Month 1 remaining: $13            │
│ - Month 1 status: 'partial'         │
│                                     │
│ Group Policy Determines Method      │
└─────────────────────────────────────┘
```

### Overpayment Handling
```
Member Pays $50 (More than $33 due)
         │
         ▼
┌─────────────────────────────────────┐
│ Overpayment Logic                   │
│                                     │
│ - Current due: $33                  │
│ - Payment: $50                      │
│ - Excess: $17                       │
│         ↓                           │
│ Options:                            │
│ 1. Apply to next installment        │
│    Month 2 now needs: $33-$17=$16   │
│                                     │
│ 2. Reduce loan balance              │
│    Principal reduced faster         │
│    Interest recalculated            │
│                                     │
│ 3. Credit to savings                │
│    Excess goes to savings account   │
│                                     │
│ Default: Option 1 (apply forward)   │
└─────────────────────────────────────┘
```

### Early Loan Closure
```
Member Wants to Pay Full Balance Early
         │
         ▼
┌─────────────────────────────────────┐
│ Early Closure Calculation           │
│                                     │
│ Original Loan:                      │
│ - Principal: $300                   │
│ - Duration: 10 months               │
│ - Total repayable: $330             │
│                                     │
│ Current Status (Month 3):           │
│ - Paid so far: $99 (3 × $33)        │
│ - Remaining: $231                   │
│         ↓                           │
│ Early Closure Options:              │
│                                     │
│ Option A: Pay Remaining Interest    │
│ - Pay full $231                     │
│ - No discount                       │
│ - Common in flat interest           │
│                                     │
│ Option B: Interest Rebate           │
│ - Recalculate interest for 3 months │
│ - Refund unused interest            │
│ - Common in declining balance       │
│ - Pay: $225 (saves $6)              │
│                                     │
│ Group Policy Determines Method      │
│         ↓                           │
│ If Approved:                        │
│ - Process full payment              │
│ - Close loan                        │
│ - Member can borrow again           │
└─────────────────────────────────────┘
```

### UI Screens Required
1. **LoanRepaymentScreen** (New)
2. **MakePaymentScreen** (New)
3. **PaymentMethodScreen** (New)
4. **RepaymentHistoryScreen** (New)
5. **EarlyClosureScreen** (New)
6. **PaymentReceiptScreen** (New)

---

## 7. Meeting Management

### Meeting Lifecycle
```
┌─────────────────────────────────────┐
│ PHASE 1: Meeting Scheduling         │
│                                     │
│ Chairperson/Secretary Creates:      │
│ - Date & Time: "Mon Jan 15, 3pm"    │
│ - Location: "Community Hall"        │
│   OR Virtual: "Zoom Link"           │
│ - Agenda Items:                     │
│   1. Opening & prayer               │
│   2. Roll call                      │
│   3. Previous minutes               │
│   4. Contributions collection       │
│   5. Loan requests review           │
│   6. Loan repayments                │
│   7. New business                   │
│   8. AOB (Any Other Business)       │
│   9. Closing                        │
│         ↓                           │
│ System Actions:                     │
│ - Save meeting to database          │
│ - Send notifications to all members │
│ - Add to calendar                   │
│ - Create meeting chat thread        │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ PHASE 2: Pre-Meeting Notifications  │
│                                     │
│ Day -7: "📅 Upcoming Meeting"       │
│ "Group meeting in 7 days"           │
│ "Mon Jan 15, 3pm at Community Hall" │
│                                     │
│ Day -3: "⏰ Reminder"               │
│ "Meeting in 3 days. Prepare your   │
│  contributions."                    │
│                                     │
│ Day -1: "📢 Tomorrow"               │
│ "Meeting tomorrow at 3pm"           │
│ "Agenda: [View]"                    │
│                                     │
│ 1 Hour Before: "🔔 Starting Soon"   │
│ "Meeting starts in 1 hour"          │
│ "Location: [Get Directions]"        │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ PHASE 3: During Meeting             │
│                                     │
│ Step 1: Check-In / Attendance       │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Method A: QR Code                   │
│ - Secretary shows QR code           │
│ - Members scan to check in          │
│ - Auto-records attendance           │
│                                     │
│ Method B: Manual Roll Call          │
│ - Secretary calls names             │
│ - Mark present/absent in app        │
│                                     │
│ Method C: GPS-based (if virtual)    │
│ - Verify location                   │
│ - Auto check-in                     │
│         ↓                           │
│ Late Arrival Tracking:              │
│ - Start time: 3:00 PM               │
│ - Member arrives: 3:15 PM           │
│ - Late by: 15 minutes               │
│ - Fine applied: $1                  │
│         ↓                           │
│ Attendance Summary (Real-time):     │
│ Present: 18 members                 │
│ Absent: 2 members                   │
│ Late: 3 members                     │
│ Quorum: ✓ (Need 15, have 18)        │
│                                     │
│ Step 2: Previous Minutes Review     │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ - Secretary reads last meeting      │
│ - Members can comment               │
│ - Vote to approve minutes           │
│ - Record approval in system         │
│                                     │
│ Step 3: Contributions Collection    │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ For Each Present Member:            │
│ - Expected: $10                     │
│ - Paid: $10 ✓                       │
│ - Treasurer records in app          │
│ - Running total displayed           │
│         ↓                           │
│ Live Collection Counter:            │
│ ┌────────────────────┐              │
│ │ Total Collected    │              │
│ │    $180            │              │
│ │ ──────────────────│              │
│ │ Expected: $200     │              │
│ │ Progress: 90%      │              │
│ └────────────────────┘              │
│         ↓                           │
│ Missed Contributions:               │
│ - Mary (absent): $10 pending        │
│ - John (forgot): $10 + $2 fine      │
│                                     │
│ Step 4: Loan Requests Discussion   │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ For Each Pending Loan:              │
│ 1. Display loan details on screen   │
│ 2. Borrower presents (2 min)        │
│ 3. Guarantors confirm                │
│ 4. Questions from members            │
│ 5. Discussion (5 min)               │
│ 6. Vote                             │
│         ↓                           │
│ In-App Voting:                      │
│ ┌─────────────────────────┐         │
│ │ Loan Request #1         │         │
│ │ Peter: $500 for farm    │         │
│ │                         │         │
│ │ Your Vote:              │         │
│ │ ○ Approve               │         │
│ │ ○ Reject                │         │
│ │ ○ Abstain               │         │
│ │                         │         │
│ │ [Submit Vote]           │         │
│ └─────────────────────────┘         │
│         ↓                           │
│ Live Vote Tally:                    │
│ Approve: ████████ 15                │
│ Reject:  ██ 2                       │
│ Abstain: █ 1                        │
│         ↓                           │
│ Decision: APPROVED ✓                │
│ - Record in minutes                 │
│ - Update loan status                │
│ - Notify borrower                   │
│                                     │
│ Step 5: Loan Repayments             │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Members with Active Loans:          │
│ - Display who owes what             │
│ - Collect payments                  │
│ - Treasurer records each            │
│ - Generate receipts                 │
│         ↓                           │
│ Repayment Tracker:                  │
│ Jane: $33 ✓ Paid                    │
│ Tom: $50 ✓ Paid (overpayment)       │
│ Sarah: $20 ⚠️ Partial                │
│ Mike: $0 ❌ Missed                   │
│                                     │
│ Step 6: New Business                │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ - Members raise issues              │
│ - Discussions                       │
│ - Decisions recorded                │
│ - Action items assigned             │
│         ↓                           │
│ Step 7: Recording Minutes           │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Secretary Uses App to Record:       │
│ - Key discussions                   │
│ - Decisions made                    │
│ - Action items                      │
│ - Voice notes of important parts    │
│ - Photos if needed                  │
│         ↓                           │
│ Auto-Generated Summary:             │
│ - Attendance list                   │
│ - Contributions: $180               │
│ - Loans approved: 1 ($500)          │
│ - Loans rejected: 0                 │
│ - Repayments: $103                  │
│ - Fines collected: $5               │
│ - Action items: 3                   │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ PHASE 4: Post-Meeting               │
│                                     │
│ Secretary Finalizes Minutes:        │
│ - Review auto-generated content     │
│ - Add manual notes                  │
│ - Attach photos/documents           │
│ - Submit for approval               │
│         ↓                           │
│ Chairperson Reviews & Approves:     │
│ - Read minutes                      │
│ - Request edits if needed           │
│ - Approve and publish               │
│         ↓                           │
│ System Shares with All Members:     │
│ "📄 Meeting Minutes Available"      │
│ "Jan 15, 2024 Meeting"              │
│ [View] [Download PDF]               │
│         ↓                           │
│ Financial Updates:                  │
│ - All transactions processed        │
│ - Balances updated                  │
│ - Statements available              │
│         ↓                           │
│ Action Items Tracked:               │
│ "⚠️ Action Required"                │
│ "You have 2 action items from       │
│  last meeting"                      │
│ - [ ] Task 1 (Due: Jan 20)          │
│ - [ ] Task 2 (Due: Jan 25)          │
└─────────────────────────────────────┘
```

### Virtual Meeting Support
```
┌─────────────────────────────────────┐
│ Virtual/Hybrid Meeting Features     │
│                                     │
│ 1. Video Conferencing Integration   │
│    - Generate Zoom/Meet link        │
│    - Share with members             │
│    - Join from app                  │
│                                     │
│ 2. Screen Sharing                   │
│    - Share financial reports        │
│    - Show loan applications         │
│    - Display vote results           │
│                                     │
│ 3. Live Chat                        │
│    - Text messages during meeting   │
│    - Raise hand feature             │
│    - Reactions (👍❤️😊)             │
│                                     │
│ 4. Recording                        │
│    - Record entire meeting          │
│    - Auto-transcription             │
│    - Archive for future reference   │
│                                     │
│ 5. Breakout Rooms                   │
│    - Small group discussions        │
│    - Committee meetings             │
│    - Loan deliberations             │
└─────────────────────────────────────┘
```

### UI Screens Required
1. **MeetingListScreen** (New)
2. **CreateMeetingScreen** (New)
3. **MeetingDetailsScreen** (New)
4. **MeetingAgendaScreen** (New)
5. **AttendanceScreen** (New)
6. **LiveMeetingScreen** (New - Main screen during meeting)
7. **VotingScreen** (New)
8. **MeetingMinutesScreen** (New)
9. **MinutesEditorScreen** (New - Secretary)
10. **MeetingSummaryScreen** (New)

---

## 8. Financial Cycle & Profit Distribution

### Cycle Management
```
┌─────────────────────────────────────┐
│ Cycle Setup (At Group Creation)     │
│                                     │
│ Configuration:                      │
│ - Cycle Duration: 12 months         │
│ - Start Date: Jan 1, 2024           │
│ - End Date: Dec 31, 2024            │
│ - Auto-Renew: Yes/No                │
│                                     │
│ Options at Cycle End:               │
│ □ Share out (distribute all)        │
│ □ Rollover (continue next cycle)    │
│ □ Member choice (individual)        │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ During Cycle (Ongoing Operations)   │
│                                     │
│ Track All Financial Activity:       │
│                                     │
│ INCOME:                             │
│ + Member contributions: $10,000     │
│ + Loan interest earned: $1,200      │
│ + Fines & penalties: $300           │
│ + Registration fees: $500           │
│ ────────────────────────            │
│ Total Income: $12,000               │
│                                     │
│ EXPENSES:                           │
│ - Loans disbursed: $8,000           │
│ - Withdrawals: $500                 │
│ - Operating costs: $200             │
│ - Social fund expenses: $300        │
│ ────────────────────────            │
│ Total Expenses: $9,000              │
│                                     │
│ CURRENT ASSETS:                     │
│ + Cash on hand: $3,000              │
│ + Active loans (owed): $6,000       │
│ ────────────────────────            │
│ Total Assets: $9,000                │
│                                     │
│ Cycle Progress: ████░░░░ 67%        │
│ (Month 8 of 12)                     │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Pre-Cycle End (30 days before)      │
│                                     │
│ System Actions:                     │
│ 1. Stop issuing new loans           │
│ 2. Accelerate loan collections      │
│ 3. Send reminders to borrowers      │
│ 4. Notify members of upcoming end   │
│         ↓                           │
│ "🔔 Cycle Ending Soon"              │
│ "Our 12-month cycle ends on Dec 31" │
│ "Please ensure all loans are repaid"│
│ "Share-out meeting on Jan 5"        │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Cycle End Process                   │
│                                     │
│ Step 1: Close All Transactions      │
│ - No new contributions              │
│ - No new loans                      │
│ - No withdrawals                    │
│ - Only loan repayments accepted     │
│         ↓                           │
│ Step 2: Final Reconciliation        │
│ System Calculates:                  │
│                                     │
│ ┌────────────────────────────┐      │
│ │ FINAL BALANCE SHEET        │      │
│ ├────────────────────────────┤      │
│ │ ASSETS                     │      │
│ │ Cash in bank:    $3,000    │      │
│ │ Cash on hand:    $500      │      │
│ │ Active loans:    $2,000    │      │
│ │ (John: $1,000, Mary: $1,000│      │
│ │  both approved for rollover│      │
│ │  to next cycle)            │      │
│ ├────────────────────────────┤      │
│ │ LIABILITIES                │      │
│ │ Member savings:  $4,500    │      │
│ │ Social fund:     $300      │      │
│ │ Reserve fund:    $500      │      │
│ ├────────────────────────────┤      │
│ │ EQUITY (Profit)            │      │
│ │ Total Assets:    $5,500    │      │
│ │ Less Liabilities: $5,300   │      │
│ │ PROFIT:          $200      │      │
│ └────────────────────────────┘      │
│         ↓                           │
│ Step 3: Allocate Profit             │
│                                     │
│ Distribution Formula (Group Choice):│
│                                     │
│ Option A: Proportional to Savings   │
│ ┌────────────────────────────┐      │
│ │ Member    Savings  %   Div │      │
│ ├────────────────────────────┤      │
│ │ Jane      $500    11%  $22 │      │
│ │ John      $450    10%  $20 │      │
│ │ Mary      $600    13%  $26 │      │
│ │ Peter     $300     7%  $14 │      │
│ │ ...                        │      │
│ │ Total    $4,500  100% $200 │      │
│ └────────────────────────────┘      │
│                                     │
│ Option B: Equal Distribution        │
│ $200 ÷ 20 members = $10 each        │
│                                     │
│ Option C: Weighted (Savings +       │
│            Attendance)              │
│ Savings: 70% weight                 │
│ Attendance: 30% weight              │
│         ↓                           │
│ Step 4: Member Decisions            │
│                                     │
│ Each Member Chooses:                │
│ ┌────────────────────────────┐      │
│ │ Your Share-Out Summary     │      │
│ ├────────────────────────────┤      │
│ │ Your Savings:    $500      │      │
│ │ Your Dividend:   $22       │      │
│ │ Total Available: $522      │      │
│ ├────────────────────────────┤      │
│ │ What would you like to do? │      │
│ │                            │      │
│ │ ○ Withdraw All ($522)      │      │
│ │   Get cash/transfer        │      │
│ │                            │      │
│ │ ○ Rollover All ($522)      │      │
│ │   Continue in new cycle    │      │
│ │                            │      │
│ │ ● Partial                  │      │
│ │   Withdraw: $200           │      │
│ │   Rollover: $322           │      │
│ │                            │      │
│ │ [Confirm Decision]         │      │
│ └────────────────────────────┘      │
│         ↓                           │
│ Step 5: Execute Share-Out           │
│                                     │
│ At Share-Out Meeting:               │
│ - Cash prepared for withdrawals     │
│ - Each member called                │
│ - Cash counted and verified         │
│ - Sign receipt                      │
│ - Update system                     │
│         ↓                           │
│ For Rollovers:                      │
│ - Amount carried to new cycle       │
│ - New savings account created       │
│ - Statement generated               │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ New Cycle or Dissolution            │
│                                     │
│ Option 1: Start New Cycle           │
│ - Members who rolled over: 15       │
│ - Total fund: $5,000                │
│ - Start date: Jan 1, 2025           │
│ - Can accept new members            │
│         ↓                           │
│ Option 2: Dissolve Group            │
│ - All funds distributed             │
│ - Final statements sent             │
│ - Group marked inactive             │
│ - Data archived                     │
│         ↓                           │
│ Option 3: Pause & Restart           │
│ - Take break for 1-3 months         │
│ - Funds held in bank                │
│ - Restart when ready                │
└─────────────────────────────────────┘
```

### Profit Calculation Examples
```sql
-- Calculate total profit for cycle
SELECT
  -- Total income
  (SELECT COALESCE(SUM(amount), 0)
   FROM transactions
   WHERE group_id = $group_id
   AND type IN ('contribution', 'fee', 'penalty')
   AND transaction_date BETWEEN $start AND $end
  ) AS total_income,

  -- Interest earned
  (SELECT COALESCE(SUM(amount_repaid - amount), 0)
   FROM loans
   WHERE group_id = $group_id
   AND created_at BETWEEN $start AND $end
  ) AS interest_earned,

  -- Operating expenses
  (SELECT COALESCE(SUM(amount), 0)
   FROM transactions
   WHERE group_id = $group_id
   AND type IN ('expense', 'operating_cost')
   AND transaction_date BETWEEN $start AND $end
  ) AS expenses,

  -- Net profit
  (total_income + interest_earned - expenses) AS net_profit;
```

### UI Screens Required
1. **CycleDashboardScreen** (New)
2. **CycleProgressScreen** (New)
3. **BalanceSheetScreen** (New)
4. **ProfitCalculationScreen** (New)
5. **ShareOutScreen** (New)
6. **MemberDecisionScreen** (New)
7. **DistributionSummaryScreen** (New)

---

## 9. Default Management

### Default Detection & Handling
```
┌─────────────────────────────────────┐
│ Automatic Default Monitoring        │
│                                     │
│ System Runs Daily:                  │
│ SELECT * FROM loan_repayments       │
│ WHERE status != 'paid'              │
│   AND due_date < NOW()              │
│         ↓                           │
│ Classify by Severity:               │
│                                     │
│ 🟡 LATE (1-7 days)                  │
│    - Friendly reminder              │
│    - No penalties yet               │
│    - Grace period                   │
│                                     │
│ 🟠 OVERDUE (8-30 days)              │
│    - Apply late fee (5%)            │
│    - Send warning                   │
│    - Notify guarantors              │
│    - Call borrower                  │
│                                     │
│ 🔴 DEFAULT (31-90 days)             │
│    - Serious action                 │
│    - Group discussion               │
│    - Restructure option             │
│    - Guarantor activation pending   │
│                                     │
│ ⚫ BAD DEBT (90+ days)               │
│    - Activate guarantors            │
│    - Legal action possible          │
│    - Member suspension              │
│    - Asset recovery                 │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Progressive Reminder System         │
│                                     │
│ Day 1 Overdue:                      │
│ "💬 Friendly Reminder"              │
│ "Hi John, your $33 payment was due  │
│  yesterday. When can you pay?"      │
│ [Pay Now] [Request Extension]       │
│         ↓                           │
│ Day 3 Overdue:                      │
│ "⚠️ Payment Still Pending"          │
│ "Your payment is 3 days overdue.    │
│  Please pay $33 + $2 late fee"      │
│ Total due: $35                      │
│ [Pay Now] [Contact Treasurer]       │
│         ↓                           │
│ Day 7 Overdue:                      │
│ "🚨 Urgent: Serious Default"        │
│ "Payment 7 days overdue. This       │
│  affects your credit and guarantors │
│  will be notified."                 │
│ Total due: $35 + $3 penalty = $38   │
│ [Pay Now] [Request Meeting]         │
│         ↓                           │
│ Day 14 Overdue:                     │
│ "📞 Call Scheduled"                 │
│ "Treasurer will call you today.     │
│  Please discuss repayment plan."    │
│         ↓                           │
│ Day 30 Overdue:                     │
│ "⚠️ Default Declaration"            │
│ "Your loan is officially in default.│
│  Guarantors have been notified.     │
│  Emergency meeting scheduled."      │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Guarantor Notification Escalation   │
│                                     │
│ Day 8 (Informational):              │
│ To Guarantors:                      │
│ "ℹ️ Loan Status Update"             │
│ "John's loan payment is overdue.    │
│  No action needed yet, just FYI."   │
│         ↓                           │
│ Day 21 (Warning):                   │
│ To Guarantors:                      │
│ "⚠️ Guarantee Alert"                │
│ "John is 21 days overdue. You may   │
│  be asked to pay if this continues."│
│ Amount at risk: $66 (your share)    │
│         ↓                           │
│ Day 45 (Action Required):           │
│ To Guarantors:                      │
│ "🚨 Guarantee Activation Pending"   │
│ "John is in serious default. Group  │
│  meeting on Jan 20 to decide next   │
│  steps. You may need to pay $66."   │
│ [View Loan] [Contact Borrower]      │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Group Intervention Process          │
│                                     │
│ Emergency Meeting Called:           │
│         ↓                           │
│ Step 1: Hear from Borrower          │
│ - Why can't you pay?                │
│ - What happened?                    │
│ - When can you pay?                 │
│ - Do you need help?                 │
│         ↓                           │
│ Common Reasons:                     │
│ • Business failed                   │
│ • Medical emergency                 │
│ • Lost job                          │
│ • Family crisis                     │
│ • Fraud/theft                       │
│         ↓                           │
│ Step 2: Group Discusses Options     │
│                                     │
│ Option A: Loan Restructuring        │
│ ┌────────────────────────────┐      │
│ │ Original Loan:             │      │
│ │ - $300 over 10 months      │      │
│ │ - Payment: $33/month       │      │
│ │ - Paid: 3 months ($99)     │      │
│ │ - Remaining: $231          │      │
│ │                            │      │
│ │ Restructured:              │      │
│ │ - Extend to 15 months      │      │
│ │ - New payment: $15/month   │      │
│ │ - Extra interest: $20      │      │
│ │ - New total: $251          │      │
│ └────────────────────────────┘      │
│         ↓                           │
│ Option B: Grace Period              │
│ - Pause payments for 2 months       │
│ - Resume in month 3                 │
│ - Extend due date                   │
│ - No extra penalty                  │
│         ↓                           │
│ Option C: Partial Forgiveness       │
│ - Forgive interest portion          │
│ - Pay only principal                │
│ - One-time mercy                    │
│ - Must complete payment plan        │
│         ↓                           │
│ Option D: Guarantor Activation      │
│ - No restructure offered            │
│ - Guarantors must pay               │
│ - Borrower owes guarantors          │
│ - Strict collection                 │
│         ↓                           │
│ Option E: Asset Seizure             │
│ - Take collateral (if any)          │
│ - Sell to recover funds             │
│ - Surplus returned                  │
│         ↓                           │
│ Step 3: Vote on Decision            │
│ - Each option presented             │
│ - Members vote                      │
│ - Majority wins                     │
│ - Record decision                   │
│         ↓                           │
│ Step 4: Implement Decision          │
│ - Update loan in system             │
│ - Notify all parties                │
│ - Create new schedule               │
│ - Monitor compliance                │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ If Guarantor Payment Needed         │
│                                     │
│ Activate Guarantors:                │
│         ↓                           │
│ Notification:                       │
│ "⚠️ Guarantee Called"               │
│ "John's loan is in default. You are │
│  required to pay your portion."     │
│                                     │
│ Breakdown:                          │
│ ┌────────────────────────────┐      │
│ │ Loan Default Details       │      │
│ ├────────────────────────────┤      │
│ │ Original: $300             │      │
│ │ Paid: $99                  │      │
│ │ Outstanding: $201          │      │
│ │ Guarantors: 3              │      │
│ │                            │      │
│ │ YOUR SHARE:                │      │
│ │ $201 ÷ 3 = $67             │      │
│ │                            │      │
│ │ Your Savings: $150 ✓       │      │
│ │ (Sufficient to cover)      │      │
│ ├────────────────────────────┤      │
│ │ Payment Options:           │      │
│ │ ○ Deduct from savings      │      │
│ │ ○ Pay cash                 │      │
│ │ ○ Mobile money             │      │
│ │                            │      │
│ │ ⚠️ If you don't pay:       │      │
│ │ - Your savings frozen      │      │
│ │ - Can't borrow             │      │
│ │ - Can't withdraw           │      │
│ │                            │      │
│ │ Deadline: 7 days           │      │
│ │                            │      │
│ │ [Pay Now] [Dispute]        │      │
│ └────────────────────────────┘      │
│         ↓                           │
│ Process Payment:                    │
│ UPDATE savings_accounts             │
│ SET balance = balance - $67         │
│ WHERE user_id = guarantor_id        │
│         ↓                           │
│ INSERT INTO transactions            │
│ - type: 'guarantor_payment'         │
│ - amount: $67                       │
│ - description: 'Paid for John loan' │
│         ↓                           │
│ Update Group Fund:                  │
│ - Restore $201 to fund              │
│ - Close defaulted loan              │
│         ↓                           │
│ Create Recovery Loan:               │
│ - Guarantors can recover from John  │
│ - Track in system                   │
│ - Group supports recovery           │
└─────────────────────────────────────┘
```

### Member Consequences
```
After Default:
         │
         ▼
┌─────────────────────────────────────┐
│ Borrower Consequences               │
│                                     │
│ Immediate:                          │
│ ✗ Cannot request new loans          │
│ ✗ Voting rights suspended           │
│ ✗ Cannot be elected to office       │
│ ✗ Cannot be guarantor               │
│ ✗ Withdrawal restricted             │
│                                     │
│ Credit Score Impact:                │
│ Before: ⭐⭐⭐⭐⭐ (5.0)              │
│ After:  ⭐⭐ (2.0)                   │
│                                     │
│ Financial Impact:                   │
│ - Penalties accumulated             │
│ - Interest still accruing           │
│ - Owe to guarantors                 │
│ - Reputation damaged                │
│                                     │
│ Recovery Path:                      │
│ 1. Repay all owed amounts           │
│ 2. Wait probation period (6 months) │
│ 3. Rebuild trust                    │
│ 4. Restrictions lifted gradually    │
└─────────────────────────────────────┘
```

### UI Screens Required
1. **DefaultDashboardScreen** (New - Treasurer/Admin)
2. **LatePaymentScreen** (New)
3. **DefaultDetailsScreen** (New)
4. **RestructureRequestScreen** (New)
5. **GuarantorActivationScreen** (New)
6. **RecoveryTrackingScreen** (New)
7. **CreditScoreScreen** (New)

---

## 10. Withdrawal Process

### Member Withdrawal Flow
```
┌─────────────────────────────────────┐
│ Member Initiates Withdrawal         │
│                                     │
│ Withdrawal Types:                   │
│                                     │
│ Type 1: Partial Withdrawal          │
│ - Take some savings                 │
│ - Remain member                     │
│ - Continue participation            │
│                                     │
│ Type 2: Full Withdrawal (Leave)     │
│ - Take all savings                  │
│ - Leave group                       │
│ - Terminate membership              │
│                                     │
│ Type 3: Emergency Withdrawal        │
│ - Urgent need                       │
│ - Faster processing                 │
│ - May waive notice period           │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Eligibility Verification            │
│                                     │
│ System Checks:                      │
│                                     │
│ ✓ No active loans                   │
│   Current loans: 0                  │
│                                     │
│ ✓ No guarantor obligations          │
│   Active guarantees: 0              │
│                                     │
│ ✓ Notice period met                 │
│   Required: 30 days                 │
│   Given: 35 days ✓                  │
│                                     │
│ ✓ Not mid-cycle (if policy)         │
│   Next cycle end: Dec 31            │
│   Current: Nov 15                   │
│   OK to withdraw ✓                  │
│                                     │
│ ✓ All fines paid                    │
│   Outstanding fines: $0 ✓           │
│                                     │
│ IF ANY FAIL:                        │
│ ┌────────────────────────────┐      │
│ │ ❌ Cannot Withdraw Yet     │      │
│ ├────────────────────────────┤      │
│ │ Issues:                    │      │
│ │ • Active loan: $500        │      │
│ │   Finish paying first      │      │
│ │                            │      │
│ │ • Guarantee for Mary: $200 │      │
│ │   Wait for loan to clear   │      │
│ │                            │      │
│ │ Options:                   │      │
│ │ 1. Pay off loan now        │      │
│ │ 2. Find replacement        │      │
│ │    guarantor (Mary's loan) │      │
│ │ 3. Wait until cleared      │      │
│ └────────────────────────────┘      │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Withdrawal Request Form             │
│                                     │
│ Amount Details:                     │
│ ┌────────────────────────────┐      │
│ │ Your Savings Breakdown     │      │
│ ├────────────────────────────┤      │
│ │ Regular Savings:    $500   │      │
│ │ Share Capital:      $50    │      │
│ │ Social Fund:        $30    │      │
│ │ Dividends (unpaid): $25    │      │
│ │ ──────────────────────     │      │
│ │ Total:             $605    │      │
│ │                            │      │
│ │ Deductions:                │      │
│ │ - Pending fines:    -$5    │      │
│ │ - Admin fee:        -$10   │      │
│ │ ──────────────────────     │      │
│ │ Net Withdrawable:  $590    │      │
│ └────────────────────────────┘      │
│                                     │
│ Withdrawal Type:                    │
│ ○ Partial: $______                  │
│   (Min: $50, Max: $590)             │
│ ● Full: $590 (Leave group)          │
│                                     │
│ Reason (Optional):                  │
│ ┌────────────────────────────┐      │
│ │ Moving to another city     │      │
│ │                            │      │
│ └────────────────────────────┘      │
│                                     │
│ Payment Method:                     │
│ ○ Cash at meeting                   │
│ ○ Mobile money: +254712...          │
│ ● Bank transfer: Acc 123...         │
│                                     │
│ [Submit Request]                    │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Approval Process                    │
│                                     │
│ Small Amount (<$100):               │
│ - Treasurer approves                │
│ - Immediate processing              │
│         ↓                           │
│ Large Amount (≥$100):               │
│ - Treasurer reviews                 │
│ - Chairperson approves              │
│ - Or group vote (if policy)         │
│         ↓                           │
│ Emergency Withdrawal:               │
│ - Requires proof of emergency       │
│ - Committee decision                │
│ - Expedited processing              │
│         ↓                           │
│ Full Withdrawal (Leave):            │
│ - Always requires vote              │
│ - Group decides                     │
│ - Exit interview                    │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Processing & Disbursement           │
│                                     │
│ Step 1: Verify Funds Available      │
│ Group Cash Balance: $2,000          │
│ Withdrawal Request: $590            │
│ After Withdrawal: $1,410 ✓          │
│ (Above minimum $1,000) ✓            │
│         ↓                           │
│ Step 2: Prepare Payment             │
│ If Cash:                            │
│ - Count cash                        │
│ - Prepare envelope                  │
│ - Schedule meeting                  │
│                                     │
│ If Transfer:                        │
│ - Initiate transfer                 │
│ - Get confirmation                  │
│ - Share receipt                     │
│         ↓                           │
│ Step 3: Record Transaction          │
│ INSERT INTO transactions            │
│ - type: 'withdrawal'                │
│ - amount: $590                      │
│ - status: 'completed'               │
│         ↓                           │
│ UPDATE savings_accounts             │
│ SET balance = balance - $590        │
│ WHERE user_id = member              │
│         ↓                           │
│ Step 4: Update Member Status        │
│ If Partial:                         │
│ - Status remains 'active'           │
│ - Can continue participating        │
│                                     │
│ If Full (Leaving):                  │
│ UPDATE group_members                │
│ SET status = 'inactive',            │
│     left_at = NOW(),                │
│     leave_reason = 'voluntary'      │
│         ↓                           │
│ Step 5: Generate Documents          │
│ - Withdrawal receipt                │
│ - Final statement                   │
│ - Clearance certificate             │
│ - Thank you letter                  │
│         ↓                           │
│ Step 6: Exit Process (if leaving)   │
│ - Return member card                │
│ - Remove from WhatsApp group        │
│ - Archive records                   │
│ - Can rejoin later                  │
└─────────────────────────────────────┘
```

### Special Cases
```
┌─────────────────────────────────────┐
│ Death of Member                     │
│                                     │
│ Next of Kin Process:                │
│ 1. Death certificate submitted      │
│ 2. Identify next of kin             │
│ 3. Verify documentation             │
│ 4. Calculate final amount:          │
│    - Total savings                  │
│    - Plus insurance (if any)        │
│    - Plus social fund contribution  │
│    - Less any debts                 │
│ 5. Group condolence contribution    │
│ 6. Disburse to family               │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Member Expelled                     │
│                                     │
│ Expulsion Process:                  │
│ 1. Serious misconduct proven        │
│ 2. Group votes to expel             │
│ 3. Calculate final dues:            │
│    - Savings returned               │
│    - Less penalties                 │
│    - Less outstanding debts         │
│ 4. Banned from rejoining            │
│ 5. Record kept for reference        │
└─────────────────────────────────────┘
```

### UI Screens Required
1. **WithdrawalRequestScreen** (New)
2. **WithdrawalCalculatorScreen** (New)
3. **WithdrawalHistoryScreen** (New)
4. **WithdrawalApprovalScreen** (New - Admin)
5. **ExitInterviewScreen** (New)
6. **FinalStatementScreen** (New)

---

## 11. Group Communication

### Communication Channels
```
┌─────────────────────────────────────┐
│ Multi-Channel Communication System  │
│                                     │
│ 1. Group Chat (Main)                │
│    - Real-time messaging            │
│    - All members can post           │
│    - Announcements from leaders     │
│    - Thread replies                 │
│    - Reactions (👍❤️😊)             │
│                                     │
│ 2. Voice Notes                      │
│    - Record up to 5 minutes         │
│    - Playback with transcription    │
│    - Useful for illiterate members  │
│    - Meeting recordings             │
│                                     │
│ 3. Document Sharing                 │
│    - PDFs, images, spreadsheets     │
│    - Meeting minutes                │
│    - Financial reports              │
│    - Loan agreements                │
│                                     │
│ 4. Polls & Voting                   │
│    - Quick decisions                │
│    - Meeting date selection         │
│    - Officer elections              │
│    - Loan approvals                 │
│                                     │
│ 5. Announcements                    │
│    - Broadcast messages             │
│    - Pin important info             │
│    - Read receipts                  │
│                                     │
│ 6. Direct Messages (1-on-1)         │
│    - Private conversations          │
│    - Treasurer ↔ Member             │
│    - Borrower ↔ Guarantor           │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Group Chat Features                 │
│                                     │
│ Message Types:                      │
│                                     │
│ 📝 Text Messages                    │
│ ┌────────────────────────────┐      │
│ │ Jane Smith         2:30 PM │      │
│ │ Good afternoon everyone!   │      │
│ │ Meeting confirmed for      │      │
│ │ Saturday 3pm               │      │
│ │ 👍 12  ❤️ 5                │      │
│ └────────────────────────────┘      │
│                                     │
│ 🎤 Voice Notes                      │
│ ┌────────────────────────────┐      │
│ │ Peter Brown       3:15 PM  │      │
│ │ 🎤 ▶️ ━━━━━━━●─ 0:45/2:30 │      │
│ │ "Regarding the loan..."    │      │
│ │ [Transcription available]  │      │
│ └────────────────────────────┘      │
│                                     │
│ 📎 Documents                        │
│ ┌────────────────────────────┐      │
│ │ Treasurer         4:00 PM  │      │
│ │ 📄 Monthly_Report.pdf      │      │
│ │ 📊 150 KB                  │      │
│ │ [Download] [Preview]       │      │
│ └────────────────────────────┘      │
│                                     │
│ 📸 Images                           │
│ ┌────────────────────────────┐      │
│ │ Mary Johnson      5:20 PM  │      │
│ │ [Photo of receipt]         │      │
│ │ "Today's contribution"     │      │
│ │ 💰📝                       │      │
│ └────────────────────────────┘      │
│                                     │
│ 📊 Polls                            │
│ ┌────────────────────────────┐      │
│ │ Chairperson       6:00 PM  │      │
│ │ 📊 Which day for meeting?  │      │
│ │ ○ Saturday (12 votes)      │      │
│ │ ○ Sunday (5 votes)         │      │
│ │ ● Monday (2 votes)         │      │
│ │ Ends in 2 hours            │      │
│ └────────────────────────────┘      │
│                                     │
│ 🔔 System Notifications             │
│ ┌────────────────────────────┐      │
│ │ System               Now   │      │
│ │ 🔔 New loan request        │      │
│ │ Sarah requested $400 loan  │      │
│ │ [View Details]             │      │
│ └────────────────────────────┘      │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Specialized Chat Features           │
│                                     │
│ 1. Loan Discussion Threads          │
│    ┌────────────────────────────┐   │
│    │ 💬 Loan Request #45        │   │
│    │ Sarah: $400 for farm       │   │
│    ├────────────────────────────┤   │
│    │ └─ John: "Good idea!"      │   │
│    │ └─ Mary: "Can you repay?"  │   │
│    │    └─ Sarah: "Yes, crop    │   │
│    │       season soon"         │   │
│    │ └─ Peter: "I support"      │   │
│    │                            │   │
│    │ 15 replies • 8 reactions   │   │
│    └────────────────────────────┘   │
│                                     │
│ 2. Meeting Notes (Live)             │
│    - Secretary posts real-time      │
│    - Members can see progress       │
│    - Add comments                   │
│    - Voice notes of key moments     │
│                                     │
│ 3. Financial Updates                │
│    - Auto-posted by system          │
│    - Monthly summaries              │
│    - Contribution reminders         │
│    - Balance updates                │
│                                     │
│ 4. Emergency Alerts                 │
│    - High priority notifications    │
│    - Member emergencies             │
│    - Urgent votes needed            │
│    - Security issues                │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Voice Note Features                 │
│                                     │
│ Recording:                          │
│ ┌────────────────────────────┐      │
│ │ 🎤 Recording...            │      │
│ │ ●━━━━━━━━━━━━━ 00:45      │      │
│ │                            │      │
│ │ [❌ Cancel] [✓ Send]       │      │
│ └────────────────────────────┘      │
│                                     │
│ Playback:                           │
│ ┌────────────────────────────┐      │
│ │ 🎤 Voice Note from Jane    │      │
│ │ ▶️ ━━━━●━━━━━━━━ 1:23/3:45│      │
│ │                            │      │
│ │ 🔊 ━━━━●━━━ Volume         │      │
│ │ 1.0x [Speed] 📝[Transcript]│      │
│ └────────────────────────────┘      │
│                                     │
│ Transcription (Auto):               │
│ ┌────────────────────────────┐      │
│ │ 📝 Transcript              │      │
│ │ "Hello everyone, I wanted  │      │
│ │  to discuss the loan       │      │
│ │  request from Sarah. I     │      │
│ │  think it's a good idea    │      │
│ │  because..."               │      │
│ │                            │      │
│ │ [Original language]        │      │
│ │ [Translate to English]     │      │
│ └────────────────────────────┘      │
│                                     │
│ Accessibility:                      │
│ - Helps illiterate members          │
│ - Better than typing                │
│ - Captures emotion/tone             │
│ - Quick and easy                    │
└─────────────────────────────────────┘
```

### Communication Rules & Moderation
```
┌─────────────────────────────────────┐
│ Group Chat Rules                    │
│                                     │
│ ✓ DO:                               │
│ - Be respectful                     │
│ - Stay on topic                     │
│ - Use voice notes for clarity       │
│ - Share relevant documents          │
│ - React to important messages       │
│                                     │
│ ✗ DON'T:                            │
│ - Share personal attacks            │
│ - Spam messages                     │
│ - Share fake news                   │
│ - Discuss outside group business    │
│                                     │
│ Moderation Powers:                  │
│ Chairperson & Admins can:           │
│ - Delete messages                   │
│ - Mute members (temporary)          │
│ - Pin important announcements       │
│ - Create polls                      │
│ - Archive old threads               │
└─────────────────────────────────────┘
```

### Notification Settings
```
┌─────────────────────────────────────┐
│ User Can Customize:                 │
│                                     │
│ General Messages:                   │
│ ● All messages                      │
│ ○ Mentions only                     │
│ ○ Mute (no notifications)           │
│                                     │
│ Announcements:                      │
│ ● Always notify                     │
│ ○ In-app only                       │
│                                     │
│ Financial Alerts:                   │
│ ✓ Contribution reminders            │
│ ✓ Loan approvals                    │
│ ✓ Payment due dates                 │
│ ✓ Meeting notifications             │
│                                     │
│ Personal Messages:                  │
│ ✓ Direct messages                   │
│ ✓ Guarantor requests                │
│ ✓ Loan discussions                  │
│                                     │
│ Quiet Hours:                        │
│ 🌙 Mute from 10 PM to 6 AM          │
└─────────────────────────────────────┘
```

### UI Screens Required
1. **GroupChatScreen** (New)
2. **ChatThreadScreen** (New)
3. **VoiceRecorderScreen** (New)
4. **DocumentViewerScreen** (New)
5. **PollCreatorScreen** (New)
6. **DirectMessageScreen** (New)
7. **NotificationSettingsScreen** (New)
8. **ChatSearchScreen** (New)

---

## 12. Transaction Types

### Complete Transaction Matrix

| Type | Category | Direction | From | To | Affects | Examples |
|------|----------|-----------|------|-----|---------|----------|
| **contribution** | Income | In | Member | Group Fund | +Group, +Savings | Weekly $10 deposit |
| **share_capital** | Income | In | Member | Group Fund | +Group (locked) | One-time $50 joining fee |
| **social_fund** | Income | In | Member | Social Fund | +Social Fund | Monthly $5 welfare |
| **loan_disbursement** | Expense | Out | Group Fund | Member | -Group, +Loan Asset | $1000 loan given |
| **loan_repayment** | Income | In | Member | Group Fund | +Group, -Loan Asset | $110 monthly payment |
| **interest_payment** | Income | In | Member | Group Profit | +Profit | Interest portion of repayment |
| **principal_payment** | Asset Return | In | Member | Group Fund | +Group Cash | Principal portion |
| **withdrawal** | Expense | Out | Group Fund | Member | -Group, -Savings | Member withdraws $200 |
| **dividend** | Expense | Out | Group Profit | Member | -Profit, +Member | Year-end $50 profit share |
| **late_fee** | Income | In | Member | Group Fund | +Profit | $5 late arrival fine |
| **penalty** | Income | In | Member | Group Fund | +Profit | $20 missed payment fee |
| **social_expense** | Expense | Out | Social Fund | External | -Social Fund | $100 funeral contribution |
| **operating_expense** | Expense | Out | Group Fund | External | -Group | $50 bank charges |
| **guarantor_payment** | Liability Transfer | Internal | Guarantor Savings | Group Fund | -Guarantor, +Group | $67 default coverage |
| **emergency_withdrawal** | Expense | Out | Group Fund | Member | -Group, -Savings | Urgent $300 medical |
| **cycle_distribution** | Expense | Out | Group Fund | Member | -Group, Final Settlement | Share-out $522 |

### Transaction Recording Template
```dart
class TransactionTemplate {
  // Member makes weekly contribution
  static Transaction contribution({
    required String memberId,
    required String groupId,
    required double amount,
  }) {
    return Transaction(
      type: TransactionType.contribution,
      userId: memberId,
      groupId: groupId,
      amount: amount,
      description: 'Weekly contribution',
      effects: [
        Effect(target: 'group_fund', delta: +amount),
        Effect(target: 'member_savings:$memberId', delta: +amount),
      ],
    );
  }

  // Loan disbursement
  static Transaction loanDisbursement({
    required String loanId,
    required String borrowerId,
    required String groupId,
    required double amount,
  }) {
    return Transaction(
      type: TransactionType.loanDisbursement,
      userId: borrowerId,
      groupId: groupId,
      amount: amount,
      referenceId: loanId,
      description: 'Loan disbursement',
      effects: [
        Effect(target: 'group_fund', delta: -amount),
        Effect(target: 'active_loans', delta: +amount),
        Effect(target: 'member_balance:$borrowerId', delta: +amount),
      ],
    );
  }

  // Loan repayment (split principal and interest)
  static List<Transaction> loanRepayment({
    required String loanId,
    required String borrowerId,
    required String groupId,
    required double totalAmount,
    required double principalPortion,
    required double interestPortion,
  }) {
    return [
      // Principal return
      Transaction(
        type: TransactionType.principalPayment,
        userId: borrowerId,
        groupId: groupId,
        amount: principalPortion,
        referenceId: loanId,
        effects: [
          Effect(target: 'group_fund', delta: +principalPortion),
          Effect(target: 'active_loans', delta: -principalPortion),
        ],
      ),
      // Interest income
      Transaction(
        type: TransactionType.interestPayment,
        userId: borrowerId,
        groupId: groupId,
        amount: interestPortion,
        referenceId: loanId,
        effects: [
          Effect(target: 'group_profit', delta: +interestPortion),
        ],
      ),
    ];
  }
}
```

---

## 13. Business Rules

### Configurable Group Rules
```
┌─────────────────────────────────────┐
│ Group Configuration                 │
│                                     │
│ MEMBERSHIP RULES                    │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Min members: [10]                   │
│ Max members: [50]                   │
│ Probation period: [3] months        │
│ Joining fee (share): $[50]          │
│ Notice period to leave: [30] days   │
│ Attendance required: [80]%          │
│                                     │
│ CONTRIBUTION RULES                  │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Frequency: [Weekly]                 │
│ Regular amount: $[10]               │
│ Social fund: $[5] per month         │
│ Grace period: [3] days              │
│ Late fine: $[2]                     │
│                                     │
│ LOAN RULES                          │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Max loan: [3x] savings OR $[2000]   │
│ Min savings to borrow: $[100]       │
│ Interest rate: [10]%                │
│ Interest type: [Flat/Declining]     │
│ Duration range: [1-12] months       │
│ Guarantors required: [2-3]          │
│ Processing fee: [2]% of loan        │
│ Late payment penalty: [5]% per month│
│ Grace period: [7] days              │
│ Default threshold: [90] days        │
│                                     │
│ MEETING RULES                       │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Frequency: [Monthly]                │
│ Quorum: [60]% of members            │
│ Late arrival fine: $[1]             │
│ Absence fine: $[5] (unexcused)      │
│ Voting method: [Majority/Consensus] │
│                                     │
│ FINANCIAL CYCLE                     │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Cycle duration: [12] months         │
│ Profit distribution: [Proportional] │
│ Reserve fund: [10]% of profits      │
│ Operating fund: [5]% of collections │
│                                     │
│ WITHDRAWAL RULES                    │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│ Min balance after: $[50]            │
│ Processing fee: $[10]               │
│ Approval for >$[100]: [Vote]        │
│ Emergency withdrawal: [Committee]   │
└─────────────────────────────────────┘
```

### Validation Rules
```dart
class BusinessRules {
  // Loan eligibility
  static bool canRequestLoan(Member member, Group group) {
    return member.isActive &&
           member.monthsInGroup >= 3 &&
           member.activeLoans == 0 &&
           member.savings >= group.minSavingsToBorrow &&
           member.attendanceRate >= group.minAttendance &&
           !member.hasDefaultHistory &&
           member.activeGuarantees < 3;
  }

  // Loan amount limit
  static double maxLoanAmount(Member member, Group group) {
    final timesRule = member.savings * group.loanMultiplier;
    final absoluteRule = group.maxLoanAmount;
    return min(timesRule, absoluteRule);
  }

  // Guarantor eligibility
  static bool canBeGuarantor(Member member, double loanAmount) {
    return member.isActive &&
           member.savings >= (loanAmount * 0.5) && // 50% of loan
           member.activeLoans == 0 &&
           member.activeGuarantees < 3 &&
           !member.isInDefault;
  }

  // Withdrawal eligibility
  static bool canWithdraw(Member member, double amount) {
    final remainingBalance = member.savings - amount;
    return member.activeLoans == 0 &&
           member.activeGuarantees == 0 &&
           member.noticePeriodMet &&
           member.allFinesPaid &&
           remainingBalance >= member.group.minBalance;
  }

  // Meeting quorum
  static bool hasQuorum(Meeting meeting, Group group) {
    final attendanceRate = meeting.attendees / group.activeMembers;
    return attendanceRate >= group.quorumPercentage;
  }

  // Vote passing
  static bool votePassed(Vote vote, Group group) {
    if (group.votingMethod == VotingMethod.majority) {
      return vote.yesVotes > vote.noVotes;
    } else if (group.votingMethod == VotingMethod.supermajority) {
      return vote.yesVotes >= (vote.totalVotes * 0.66);
    } else { // consensus
      return vote.noVotes == 0;
    }
  }
}
```

---

## 14. State Machines

### Loan State Machine
```
     ┌──────────┐
     │ PENDING  │ ← Initial state when request submitted
     └────┬─────┘
          │
          ├──→ (All guarantors approve) ──→ ┌──────────┐
          │                                  │ APPROVED │
          │                                  └────┬─────┘
          │                                       │
          │                    (Treasurer disburses) ──→ ┌────────┐
          │                                               │ ACTIVE │
          │                                               └───┬────┘
          │                                                   │
          │                      (All payments made) ──→ ┌───────────┐
          │                                               │ COMPLETED │
          │                                               └───────────┘
          │                                                   │
          │                      (90+ days overdue) ──→  ┌───────────┐
          │                                               │ DEFAULTED │
          │                                               └───────────┘
          │
          └──→ (Any guarantor rejects OR vote fails) ──→ ┌──────────┐
                                                          │ REJECTED │
                                                          └──────────┘

Allowed Transitions:
- PENDING → APPROVED (guarantors approve + vote passes)
- PENDING → REJECTED (guarantor rejects OR vote fails)
- APPROVED → ACTIVE (treasurer disburses)
- ACTIVE → COMPLETED (fully repaid)
- ACTIVE → DEFAULTED (90+ days overdue)
- ACTIVE → RESTRUCTURED (group approves restructure)
- DEFAULTED → WRITTEN_OFF (group votes to write off)

Invalid Transitions:
- Cannot go from REJECTED back to PENDING (must create new request)
- Cannot go from COMPLETED back to ACTIVE
- Cannot skip APPROVED and go straight to ACTIVE
```

### Member State Machine
```
     ┌────────────┐
     │ APPLICANT  │ ← User signs up
     └──────┬─────┘
            │
            ├──→ (Join request submitted) ──→ ┌─────────┐
            │                                  │ PENDING │
            │                                  └────┬────┘
            │                                       │
            │                   (Admin approves) ──→ ┌────────┐
            │                                        │ ACTIVE │
            │                                        └───┬────┘
            │                                            │
            │              (Completes probation) ──→ ┌──────────┐
            │                                        │ FULL_MEMBER│
            │                                        └──────┬────┘
            │                                               │
            │        (Elected to office) ──→ ┌─────────────┐
            │                                │ OFFICER     │
            │                                └──────┬──────┘
            │                                       │
            │            (Term ends) ──→ back to FULL_MEMBER
            │                                       │
            │      (Requests leave) ──→ ┌──────────┐
            │                           │ INACTIVE │
            │                           └──────────┘
            │                                       │
            │      (Can rejoin) ──→ back to PENDING
            │
            └──→ (Join rejected) ──→ ┌──────────┐
                                     │ REJECTED │
                                     └──────────┘

Special States:
- SUSPENDED (temporary for violations)
- DEFAULTED (after loan default)
- EXPELLED (permanent removal)
- DECEASED (for inheritance process)
```

### Meeting State Machine
```
┌───────────┐
│ SCHEDULED │ ← Created by admin
└─────┬─────┘
      │
      ├──→ (Time arrives) ──→ ┌────────┐
      │                       │ ONGOING│
      │                       └───┬────┘
      │                           │
      │     (Secretary closes) ──→ ┌─────────────┐
      │                            │ PENDING_MINUTES│
      │                            └──────┬────────┘
      │                                   │
      │      (Minutes submitted) ──→ ┌──────────┐
      │                              │ COMPLETED│
      │                              └──────────┘
      │
      └──→ (Cancelled) ──→ ┌───────────┐
                           │ CANCELLED │
                           └───────────┘
```

---

## 15. Role-Based Permissions

### Permission Matrix

| Feature | Member | Treasurer | Secretary | Chairperson | Admin |
|---------|--------|-----------|-----------|-------------|-------|
| **Viewing** |
| Own transactions | ✓ | ✓ | ✓ | ✓ | ✓ |
| All transactions | ✗ | ✓ | ✓ | ✓ | ✓ |
| Group financials | Summary | ✓ | ✓ | ✓ | ✓ |
| Member details | Basic | Full | Full | Full | Full |
| Meeting minutes | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Contributing** |
| Make contribution | ✓ | ✓ | ✓ | ✓ | ✓ |
| Record contributions | ✗ | ✓ | ✗ | ✗ | ✓ |
| **Loans** |
| Request loan | ✓ | ✓ | ✓ | ✓ | ✓ |
| View all loans | ✗ | ✓ | ✓ | ✓ | ✓ |
| Approve loans | Vote | ✓ | Vote | ✓ | ✓ |
| Disburse loans | ✗ | ✓ | ✗ | ✓ | ✓ |
| Record payments | ✗ | ✓ | ✗ | ✗ | ✓ |
| **Guarantor** |
| Be guarantor | ✓ | ✓ | ✓ | ✓ | ✓ |
| Approve guarantee | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Meetings** |
| Attend meetings | ✓ | ✓ | ✓ | ✓ | ✓ |
| Create meeting | ✗ | ✗ | ✓ | ✓ | ✓ |
| Record attendance | ✗ | ✗ | ✓ | ✓ | ✓ |
| Record minutes | ✗ | ✗ | ✓ | ✓ | ✓ |
| Close meeting | ✗ | ✗ | ✓ | ✓ | ✓ |
| **Members** |
| Invite members | ✗ | ✗ | ✗ | ✓ | ✓ |
| Approve members | ✗ | ✗ | ✗ | ✓ | ✓ |
| Change roles | ✗ | ✗ | ✗ | ✓ | ✓ |
| Suspend member | ✗ | ✗ | ✗ | ✓ | ✓ |
| Expel member | ✗ | ✗ | ✗ | Vote + Chair | ✓ |
| **Settings** |
| View settings | ✓ | ✓ | ✓ | ✓ | ✓ |
| Edit group rules | ✗ | ✗ | ✗ | ✓ | ✓ |
| Change fees | ✗ | ✗ | ✗ | Vote + Chair | ✓ |
| **Financial** |
| View own balance | ✓ | ✓ | ✓ | ✓ | ✓ |
| View group balance | Summary | ✓ | ✓ | ✓ | ✓ |
| Withdraw funds | Request | ✓ | Request | ✓ | ✓ |
| Approve withdrawal | ✗ | <$100 | ✗ | ✓ | ✓ |
| Generate reports | ✗ | ✓ | ✓ | ✓ | ✓ |
| **Communication** |
| Send messages | ✓ | ✓ | ✓ | ✓ | ✓ |
| Pin messages | ✗ | ✗ | ✓ | ✓ | ✓ |
| Delete messages | Own | Own | Own + Others | Own + Others | All |
| Send announcements | ✗ | ✓ | ✓ | ✓ | ✓ |
| Create polls | ✗ | ✓ | ✓ | ✓ | ✓ |

---

## Implementation Priority

### Phase 1: MVP (Minimum Viable Product)
1. ✅ User authentication
2. ✅ Profile management
3. Group creation & joining
4. Contributions
5. Basic loan request
6. Simple approvals
7. Meeting scheduling
8. Group chat

### Phase 2: Core Village Banking
9. Guarantor system
10. Loan disbursement
11. Repayment tracking
12. Meeting minutes
13. Voting system
14. Financial reports

### Phase 3: Advanced Features
15. Voice notes
16. Default management
17. Cycle management
18. Profit distribution
19. Advanced analytics
20. Mobile money integration

---

## Database Design Summary

### Core Tables
- profiles (users)
- village_groups
- group_members (with roles)
- savings_accounts
- transactions (all types)
- loans
- loan_guarantors
- loan_repayments
- meetings
- meeting_attendance
- messages (chat)
- notifications
- votes
- documents

### Key Relationships
```
User (1) ──→ (Many) GroupMember
GroupMember (Many) ──→ (1) Group
User (1) ──→ (Many) SavingsAccount
Group (1) ──→ (Many) SavingsAccount
User (1) ──→ (Many) Loan (as borrower)
Loan (1) ──→ (Many) LoanGuarantor
Loan (1) ──→ (Many) LoanRepayment
Group (1) ──→ (Many) Meeting
Meeting (1) ──→ (Many) MeetingAttendance
Group (1) ──→ (Many) Transaction
User (1) ──→ (Many) Transaction
```

---

## Security Considerations

1. **Row Level Security (RLS)**
   - Users see only their group's data
   - Role-based data access
   - Treasurer sees more than members

2. **Transaction Atomicity**
   - All money movements must be logged
   - No balance update without transaction record
   - Use database transactions for consistency

3. **Audit Trail**
   - Who did what, when
   - Immutable transaction history
   - Change logs for important actions

4. **Data Validation**
   - Server-side validation mandatory
   - Business rule enforcement
   - Prevent negative balances

5. **Authentication**
   - Secure password requirements
   - Session management
   - Optional 2FA for treasurers

---

This comprehensive logic flow document will serve as the blueprint for implementing all village banking features in your app.
