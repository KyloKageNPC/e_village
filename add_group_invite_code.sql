-- ============================================
-- ADD GROUP INVITE CODE FUNCTIONALITY
-- Enables users to join groups via shareable codes
-- ============================================

-- Add invite_code column to village_groups
ALTER TABLE village_groups 
ADD COLUMN IF NOT EXISTS invite_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS invite_code_created_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS require_approval BOOLEAN DEFAULT false;

-- Create function to generate unique invite codes
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $BODY$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Removed confusing chars (0,O,1,I)
  result TEXT := '';
  i INTEGER;
BEGIN
  -- Generate 6-character code
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
  END LOOP;
  RETURN result;
END;
$BODY$ LANGUAGE plpgsql;

-- Generate invite codes for existing groups that don't have one
UPDATE village_groups 
SET 
  invite_code = generate_invite_code(),
  invite_code_created_at = NOW()
WHERE invite_code IS NULL;

-- Create trigger to auto-generate invite code on new group creation
CREATE OR REPLACE FUNCTION auto_generate_invite_code()
RETURNS TRIGGER AS $BODY$
BEGIN
  IF NEW.invite_code IS NULL THEN
    -- Keep trying until we get a unique code
    LOOP
      NEW.invite_code := generate_invite_code();
      -- Check if code already exists
      EXIT WHEN NOT EXISTS (
        SELECT 1 FROM village_groups WHERE invite_code = NEW.invite_code AND id != NEW.id
      );
    END LOOP;
    NEW.invite_code_created_at := NOW();
  END IF;
  RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_auto_invite_code ON village_groups;
CREATE TRIGGER trigger_auto_invite_code
  BEFORE INSERT ON village_groups
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_invite_code();

-- Create index for fast code lookup
CREATE INDEX IF NOT EXISTS idx_village_groups_invite_code ON village_groups(invite_code);

-- Function to get group by invite code (for joining)
CREATE OR REPLACE FUNCTION get_group_by_invite_code(code TEXT)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  location TEXT,
  member_count BIGINT,
  require_approval BOOLEAN
) AS $BODY$
BEGIN
  RETURN QUERY
  SELECT 
    vg.id,
    vg.name,
    vg.description,
    vg.location,
    COUNT(gm.id) as member_count,
    COALESCE(vg.require_approval, false)
  FROM village_groups vg
  LEFT JOIN group_members gm ON vg.id = gm.group_id AND gm.status = 'active'
  WHERE UPPER(vg.invite_code) = UPPER(code)
    AND vg.is_active = true
  GROUP BY vg.id, vg.name, vg.description, vg.location, vg.require_approval;
END;
$BODY$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to regenerate invite code (for admins)
CREATE OR REPLACE FUNCTION regenerate_group_invite_code(group_uuid UUID)
RETURNS TEXT AS $BODY$
DECLARE
  new_code TEXT;
BEGIN
  -- Generate new unique code
  LOOP
    new_code := generate_invite_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM village_groups WHERE invite_code = new_code AND id != group_uuid
    );
  END LOOP;
  
  -- Update the group
  UPDATE village_groups 
  SET 
    invite_code = new_code,
    invite_code_created_at = NOW()
  WHERE id = group_uuid;
  
  RETURN new_code;
END;
$BODY$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policy: Allow authenticated users to call get_group_by_invite_code
GRANT EXECUTE ON FUNCTION get_group_by_invite_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION regenerate_group_invite_code(UUID) TO authenticated;

-- Display summary
SELECT 
  'Migration complete. ' || COUNT(*) || ' groups now have invite codes.' as summary
FROM village_groups 
WHERE invite_code IS NOT NULL;
