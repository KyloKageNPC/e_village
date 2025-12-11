-- =============================================
-- CHAT TABLES - Add to Supabase Database
-- =============================================
-- Run this SQL in your Supabase SQL Editor to enable chat functionality

-- =============================================
-- 1. CHAT MESSAGES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  group_id UUID REFERENCES village_groups(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
  sender_name TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'text' CHECK (type IN ('text', 'voice', 'image', 'system')),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Chat messages policies
DROP POLICY IF EXISTS "Group members can view messages" ON chat_messages;
CREATE POLICY "Group members can view messages"
  ON chat_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = chat_messages.group_id
      AND group_members.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Group members can insert messages" ON chat_messages;
CREATE POLICY "Group members can insert messages"
  ON chat_messages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = chat_messages.group_id
      AND group_members.user_id = auth.uid()
    )
    AND sender_id = auth.uid()
  );

DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;
CREATE POLICY "Users can update their own messages"
  ON chat_messages FOR UPDATE
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete their own messages" ON chat_messages;
CREATE POLICY "Users can delete their own messages"
  ON chat_messages FOR DELETE
  USING (sender_id = auth.uid());

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_group_id ON chat_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- Updated_at trigger
DROP TRIGGER IF EXISTS update_chat_messages_updated_at ON chat_messages;
CREATE TRIGGER update_chat_messages_updated_at
  BEFORE UPDATE ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 2. MESSAGE REACTIONS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS message_reactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  message_id UUID REFERENCES chat_messages(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
  user_name TEXT NOT NULL,
  emoji TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji) -- One reaction per user per emoji
);

-- Enable RLS
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

-- Reaction policies
DROP POLICY IF EXISTS "Group members can view reactions" ON message_reactions;
CREATE POLICY "Group members can view reactions"
  ON message_reactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_messages cm
      JOIN group_members gm ON gm.group_id = cm.group_id
      WHERE cm.id = message_reactions.message_id
      AND gm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Group members can add reactions" ON message_reactions;
CREATE POLICY "Group members can add reactions"
  ON message_reactions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_messages cm
      JOIN group_members gm ON gm.group_id = cm.group_id
      WHERE cm.id = message_reactions.message_id
      AND gm.user_id = auth.uid()
    )
    AND user_id = auth.uid()
  );

DROP POLICY IF EXISTS "Users can delete their own reactions" ON message_reactions;
CREATE POLICY "Users can delete their own reactions"
  ON message_reactions FOR DELETE
  USING (user_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON message_reactions(user_id);

-- =============================================
-- 3. MESSAGE ATTACHMENTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS message_attachments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  message_id UUID REFERENCES chat_messages(id) ON DELETE CASCADE NOT NULL,
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size BIGINT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE message_attachments ENABLE ROW LEVEL SECURITY;

-- Attachment policies
DROP POLICY IF EXISTS "Group members can view attachments" ON message_attachments;
CREATE POLICY "Group members can view attachments"
  ON message_attachments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_messages cm
      JOIN group_members gm ON gm.group_id = cm.group_id
      WHERE cm.id = message_attachments.message_id
      AND gm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Message sender can add attachments" ON message_attachments;
CREATE POLICY "Message sender can add attachments"
  ON message_attachments FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_messages cm
      WHERE cm.id = message_attachments.message_id
      AND cm.sender_id = auth.uid()
    )
  );

-- Indexes
CREATE INDEX IF NOT EXISTS idx_message_attachments_message_id ON message_attachments(message_id);

-- =============================================
-- 4. MESSAGE THREADS TABLE (for replies)
-- =============================================
CREATE TABLE IF NOT EXISTS message_threads (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  parent_message_id UUID REFERENCES chat_messages(id) ON DELETE CASCADE NOT NULL,
  reply_message_id UUID REFERENCES chat_messages(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(parent_message_id, reply_message_id)
);

-- Enable RLS
ALTER TABLE message_threads ENABLE ROW LEVEL SECURITY;

-- Thread policies
DROP POLICY IF EXISTS "Group members can view threads" ON message_threads;
CREATE POLICY "Group members can view threads"
  ON message_threads FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_messages cm
      JOIN group_members gm ON gm.group_id = cm.group_id
      WHERE cm.id = message_threads.parent_message_id
      AND gm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Group members can create threads" ON message_threads;
CREATE POLICY "Group members can create threads"
  ON message_threads FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_messages cm
      JOIN group_members gm ON gm.group_id = cm.group_id
      WHERE cm.id = message_threads.parent_message_id
      AND gm.user_id = auth.uid()
    )
  );

-- Indexes
CREATE INDEX IF NOT EXISTS idx_message_threads_parent ON message_threads(parent_message_id);
CREATE INDEX IF NOT EXISTS idx_message_threads_reply ON message_threads(reply_message_id);

-- =============================================
-- 5. POLLS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS chat_polls (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  message_id UUID REFERENCES chat_messages(id) ON DELETE CASCADE NOT NULL,
  group_id UUID REFERENCES village_groups(id) ON DELETE CASCADE NOT NULL,
  question TEXT NOT NULL,
  options JSONB NOT NULL, -- Array of {id, text, votes: []}
  end_date TIMESTAMP WITH TIME ZONE,
  allow_multiple_votes BOOLEAN DEFAULT false,
  is_anonymous BOOLEAN DEFAULT false,
  created_by UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE chat_polls ENABLE ROW LEVEL SECURITY;

-- Poll policies
DROP POLICY IF EXISTS "Group members can view polls" ON chat_polls;
CREATE POLICY "Group members can view polls"
  ON chat_polls FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = chat_polls.group_id
      AND group_members.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Group members can create polls" ON chat_polls;
CREATE POLICY "Group members can create polls"
  ON chat_polls FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = chat_polls.group_id
      AND group_members.user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

DROP POLICY IF EXISTS "Poll creator can update polls" ON chat_polls;
CREATE POLICY "Poll creator can update polls"
  ON chat_polls FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_chat_polls_group_id ON chat_polls(group_id);
CREATE INDEX IF NOT EXISTS idx_chat_polls_message_id ON chat_polls(message_id);
CREATE INDEX IF NOT EXISTS idx_chat_polls_created_by ON chat_polls(created_by);

-- =============================================
-- 6. POLL VOTES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS poll_votes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  poll_id UUID REFERENCES chat_polls(id) ON DELETE CASCADE NOT NULL,
  option_id TEXT NOT NULL,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
  user_name TEXT NOT NULL,
  voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(poll_id, option_id, user_id) -- One vote per option per user (unless multiple votes allowed)
);

-- Enable RLS
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;

-- Vote policies
DROP POLICY IF EXISTS "Group members can view votes" ON poll_votes;
CREATE POLICY "Group members can view votes"
  ON poll_votes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_polls cp
      JOIN group_members gm ON gm.group_id = cp.group_id
      WHERE cp.id = poll_votes.poll_id
      AND gm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Group members can vote" ON poll_votes;
CREATE POLICY "Group members can vote"
  ON poll_votes FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_polls cp
      JOIN group_members gm ON gm.group_id = cp.group_id
      WHERE cp.id = poll_votes.poll_id
      AND gm.user_id = auth.uid()
    )
    AND user_id = auth.uid()
  );

DROP POLICY IF EXISTS "Users can delete their own votes" ON poll_votes;
CREATE POLICY "Users can delete their own votes"
  ON poll_votes FOR DELETE
  USING (user_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_poll_votes_poll_id ON poll_votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_user_id ON poll_votes(user_id);

-- =============================================
-- SUCCESS MESSAGE
-- =============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Chat tables created successfully!';
  RAISE NOTICE '📋 Tables created:';
  RAISE NOTICE '   1. chat_messages';
  RAISE NOTICE '   2. message_reactions';
  RAISE NOTICE '   3. message_attachments';
  RAISE NOTICE '   4. message_threads';
  RAISE NOTICE '   5. chat_polls';
  RAISE NOTICE '   6. poll_votes';
  RAISE NOTICE '';
  RAISE NOTICE '✅ All RLS policies configured';
  RAISE NOTICE '✅ All indexes created';
  RAISE NOTICE '✅ All triggers configured';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 Your chat system is now ready!';
END $$;
