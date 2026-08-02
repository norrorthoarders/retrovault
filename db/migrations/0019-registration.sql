-- Letting somebody in.
--
-- Four modes, because "can anyone sign up" has four honest answers and a
-- checkbox has two:
--
--   closed  only an administrator creates accounts (the behaviour until now)
--   public  a link on the sign-in page, anybody may use it
--   secret  no link anywhere; you need the address, which contains a token
--   invite  an administrator sends an invitation to an address
--
-- The invite table is here rather than in `settings` because an invitation is a
-- thing with a lifetime, a recipient and a single use, and none of those fit in
-- a key and a string.
CREATE TABLE IF NOT EXISTS invites (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email       VARCHAR(190) NOT NULL,
  -- Hashed, like a password and like an API token. An invitation is a
  -- credential: whoever holds it becomes a user of this instance.
  token_hash  CHAR(64)     NOT NULL,
  -- Enough of it to tell two invitations apart in a list without holding the
  -- thing itself.
  prefix      VARCHAR(12)  NOT NULL,
  created_by  INT UNSIGNED     NULL,
  expires_at  DATETIME     NOT NULL,
  used_at     DATETIME         NULL,
  user_id     INT UNSIGNED     NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_invites_token (token_hash),
  KEY idx_invites_email (email),
  CONSTRAINT fk_invites_creator FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT fk_invites_user    FOREIGN KEY (user_id)    REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Closed is the behaviour every existing install already has, so an upgrade
-- changes nothing until somebody chooses otherwise.
INSERT INTO settings (name, value) VALUES ('registration_mode', 'closed')
  ON DUPLICATE KEY UPDATE name = name;

-- The token in the secret address. Generated on first use rather than here:
-- a value shipped in a migration is a value every install shares.
INSERT INTO settings (name, value) VALUES ('registration_secret', '')
  ON DUPLICATE KEY UPDATE name = name;

-- Search engines. 'discourage' by default, because this catalogues what is in
-- somebody's flat: the addresses of the machines they own, what they paid, and
-- when the house was empty enough to photograph it all. An instance that wants
-- to be found can say so.
INSERT INTO settings (name, value) VALUES ('search_indexing', 'discourage')
  ON DUPLICATE KEY UPDATE name = name;
