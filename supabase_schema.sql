-- Village Banking App - Supabase Database Schema
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- PROFILES TABLE (extends Supabase auth.users)
-- =============================================
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  full_name TEXT NOT NULL,
  phone_number TEXT UNIQUE,
  avatar_url TEXT,
  id_number TEXT,
  date_of_birth DATE,
  address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- =============================================
-- VILLAGE GROUPS TABLE
-- =============================================
CREATE TABLE village_groups (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  location TEXT,
  meeting_schedule TEXT,
  created_by UUID REFERENCES profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true
);

ALTER TABLE village_groups ENABLE ROW LEVEL SECURITY;

-- Village group policies
CREATE POLICY "Anyone can view active village groups"
  ON village_groups FOR SELECT
  USING (is_active = true);

CREATE POLICY "Creators can update their village groups"
  ON village_groups FOR UPDATE
  USING (auth.uid() = created_by);

-- =============================================
-- GROUP MEMBERS TABLE
-- =============================================
CREATE TYPE member_role AS ENUM ('member', 'treasurer', 'chairperson', 'secretary');
CREATE TYPE member_status AS ENUM ('active', 'inactive', 'suspended');

CREATE TABLE group_members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  group_id UUID REFERENCES village_groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  role member_role DEFAULT 'member',
  status member_status DEFAULT 'active',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Group members policies
CREATE POLICY "Group members can view their group membership"
  ON group_members FOR SELECT
  USING (
    auth.uid() = user_id OR
    auth.uid() IN (
      SELECT user_id FROM group_members WHERE group_id = group_members.group_id
    )
  );

-- =============================================
-- SAVINGS ACCOUNTS TABLE
-- =============================================
CREATE TABLE savings_accounts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  group_id UUID REFERENCES village_groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  balance DECIMAL(15, 2) DEFAULT 0.00 NOT NULL,
  total_contributions DECIMAL(15, 2) DEFAULT 0.00 NOT NULL,
  total_withdrawals DECIMAL(15, 2) DEFAULT 0.00 NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

ALTER TABLE savings_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own savings accounts"
  ON savings_accounts FOR SELECT
  USING (auth.uid() = user_id);

-- =============================================
-- TRANSACTIONS TABLE
-- =============================================
CREATE TYPE transaction_type AS ENUM ('contribution', 'withdrawal', 'loan_disbursement', 'loan_repayment', 'fee', 'dividend', 'penalty');
CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed', 'cancelled');

CREATE TABLE transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  group_id UUID REFERENCES village_groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  type transaction_type NOT NULL,
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  balance_before DECIMAL(15, 2),
  balance_after DECIMAL(15, 2),
  description TEXT,
  reference_id UUID, -- Links to loan_id if related to loan
  status transaction_status DEFAULT 'completed',
  transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own transactions"
  ON transactions FOR SELECT
  USING (
    auth.uid() = user_id OR
    auth.uid() IN (
      SELECT user_id FROM group_members
      WHERE group_id = transactions.group_id AND role IN ('treasurer', 'chairperson')
    )
  );

-- =============================================
-- LOANS TABLE
-- =============================================
CREATE TYPE loan_status AS ENUM ('pending', 'approved', 'rejected', 'disbursed', 'active', 'completed', 'defaulted');
CREATE TYPE interest_type AS ENUM ('flat', 'declining_balance');

CREATE TABLE loans (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  group_id UUID REFERENCES village_groups(id) ON DELETE CASCADE NOT NULL,
  borrower_id UUID REFERENCES profiles(id) NOT NULL,
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  interest_rate DECIMAL(5, 2) NOT NULL CHECK (interest_rate >= 0),
  interest_type interest_type DEFAULT 'flat',
  duration_months INTEGER NOT NULL CHECK (duration_months > 0),
  purpose TEXT NOT NULL,
  status loan_status DEFAULT 'pending',
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  disbursed_at TIMESTAMP WITH TIME ZONE,
  due_date DATE,
  total_repayable DECIMAL(15, 2),
  amount_repaid DECIMAL(15, 2) DEFAULT 0.00,
  balance DECIMAL(15, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE loans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own loans"
  ON loans FOR SELECT
  USING (
    auth.uid() = borrower_id OR
    auth.uid() IN (
      SELECT user_id FROM group_members
      WHERE group_id = loans.group_id
    )
  );

CREATE POLICY "Users can create loan requests"
  ON loans FOR INSERT
  WITH CHECK (auth.uid() = borrower_id);

-- =============================================
-- LOAN GUARANTORS TABLE
-- =============================================
CREATE TYPE guarantor_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TABLE loan_guarantors (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  guarantor_id UUID REFERENCES profiles(id) NOT NULL,
  status guarantor_status DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  responded_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(loan_id, guarantor_id)
);

ALTER TABLE loan_guarantors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Guarantors can view their guarantor requests"
  ON loan_guarantors FOR SELECT
  USING (auth.uid() = guarantor_id);

CREATE POLICY "Guarantors can update their status"
  ON loan_guarantors FOR UPDATE
  USING (auth.uid() = guarantor_id);

-- =============================================
-- LOAN REPAYMENT SCHEDULE TABLE
-- =============================================
CREATE TYPE repayment_status AS ENUM ('pending', 'paid', 'overdue', 'partial');

CREATE TABLE loan_repayments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  installment_number INTEGER NOT NULL,
  due_date DATE NOT NULL,
  amount_due DECIMAL(15, 2) NOT NULL CHECK (amount_due > 0),
  amount_paid DECIMAL(15, 2) DEFAULT 0.00,
  status repayment_status DEFAULT 'pending',
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(loan_id, installment_number)
);

ALTER TABLE loan_repayments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view repayments for their loans"
  ON loan_repayments FOR SELECT
  USING (
    auth.uid() IN (
      SELECT borrower_id FROM loans WHERE id = loan_repayments.loan_id
    )
  );

-- =============================================
-- MEETINGS TABLE
-- =============================================
CREATE TABLE meetings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  group_id UUID REFERENCES village_groups(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  meeting_date TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT,
  agenda TEXT,
  minutes TEXT,
  created_by UUID REFERENCES profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can view meetings"
  ON meetings FOR SELECT
  USING (
    auth.uid() IN (
      SELECT user_id FROM group_members WHERE group_id = meetings.group_id
    )
  );

-- =============================================
-- MEETING ATTENDANCE TABLE
-- =============================================
CREATE TABLE meeting_attendance (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  meeting_id UUID REFERENCES meetings(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  attended BOOLEAN DEFAULT false,
  marked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(meeting_id, user_id)
);

ALTER TABLE meeting_attendance ENABLE ROW LEVEL SECURITY;

-- =============================================
-- INDEXES for Performance
-- =============================================
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_group_id ON transactions(group_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date DESC);
CREATE INDEX idx_loans_borrower_id ON loans(borrower_id);
CREATE INDEX idx_loans_group_id ON loans(group_id);
CREATE INDEX idx_loans_status ON loans(status);
CREATE INDEX idx_savings_accounts_user_id ON savings_accounts(user_id);

-- =============================================
-- FUNCTIONS AND TRIGGERS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_village_groups_updated_at BEFORE UPDATE ON village_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_savings_accounts_updated_at BEFORE UPDATE ON savings_accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON loans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone_number)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone_number', NEW.phone)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- HELPER VIEWS
-- =============================================

-- View for group financial summary
CREATE VIEW group_financial_summary AS
SELECT
  g.id as group_id,
  g.name as group_name,
  COUNT(DISTINCT gm.user_id) as total_members,
  COALESCE(SUM(sa.balance), 0) as total_savings,
  COALESCE(SUM(CASE WHEN l.status IN ('active', 'disbursed') THEN l.balance ELSE 0 END), 0) as total_loans_outstanding,
  COALESCE(SUM(CASE WHEN l.status = 'completed' THEN l.amount_repaid ELSE 0 END), 0) as total_loans_repaid
FROM village_groups g
LEFT JOIN group_members gm ON g.id = gm.group_id AND gm.status = 'active'
LEFT JOIN savings_accounts sa ON g.id = sa.group_id
LEFT JOIN loans l ON g.id = l.group_id
WHERE g.is_active = true
GROUP BY g.id, g.name;
