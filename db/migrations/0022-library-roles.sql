-- Two more levels between contributor and owner.
--
--   viewer       read
--   contributor  add, and edit or delete their own
--   editor       add, and edit or delete anyone's        (new)
--   curator      the above, plus the data structures
--   admin        the above, plus members and maintenance (new)
--   owner        the above, plus the library itself
--
-- Three columns hold these values, not one: a membership, a directory group's
-- default, and a directory group's per-library grant. All three are widened
-- together, because a level accepted in one place and truncated in another is
-- how somebody ends up with an access they were never given.

ALTER TABLE library_members
  MODIFY COLUMN access ENUM('viewer','contributor','editor','curator','admin','owner')
    NOT NULL DEFAULT 'viewer';

ALTER TABLE auth_group_map
  MODIFY COLUMN default_access ENUM('none','viewer','contributor','editor','curator','admin')
    NOT NULL DEFAULT 'none';

ALTER TABLE auth_group_library_access
  MODIFY COLUMN access ENUM('viewer','contributor','editor','curator','admin')
    NOT NULL DEFAULT 'viewer';

-- Existing curators become admins.
--
-- That reads like a promotion and is the opposite. A curator today can already
-- manage members and the data structures, so "curator" in the new list is a
-- narrower job than the one they hold. Mapping them to the level with the same
-- powers keeps every existing membership doing exactly what it did yesterday,
-- which matters more than the word staying the same.
UPDATE library_members SET access = 'admin' WHERE access = 'curator';
UPDATE auth_group_map SET default_access = 'admin' WHERE default_access = 'curator';
UPDATE auth_group_library_access SET access = 'admin' WHERE access = 'curator';
