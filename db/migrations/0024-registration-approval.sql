-- What happens after somebody signs up.
--
-- Registration said who *may* create an account and nothing about whether the
-- account works once created - so a public sign-up produced a user the account
-- list called "unconfirmed" who could sign in anyway. Three answers:
--
--   auto   signed in straight away
--   email  must confirm the address first (needs a working relay)
--   admin  must be let in by an administrator
--
-- 'auto' is what the instance does today, so an upgrade changes nothing.
INSERT INTO settings (name, value) VALUES ('registration_approval', 'auto')
  ON DUPLICATE KEY UPDATE name = name;
