-- What kind of thing a branch holds, said rather than guessed.
--
-- `role` already distinguished machines from peripherals. Software had nothing:
-- a game was decided by whether any branch above it happened to be named
-- "Games", which works on the shipped tree and on nothing anybody builds
-- themselves. Somebody starting a library from scratch had no way to declare
-- that a branch holds games, and the browsers had no way to know.
ALTER TABLE categories
  MODIFY COLUMN role ENUM('machine','peripheral','game','application','other')
    NOT NULL DEFAULT 'other';

-- The shipped tree already says it, in the only way it could until now: mark the
-- branches under a node called "Games" as holding games, and the rest of the
-- software tree as applications. Nothing is guessed after this - it is written
-- down, and editable.
UPDATE categories c
   JOIN categories anc
     ON LOCATE(CONCAT('/', anc.id, '/'), c.path) > 0
    AND LOWER(anc.name) = 'games'
    SET c.role = 'game'
  WHERE c.domain = 'software' AND c.role = 'other';

UPDATE categories
   SET role = 'application'
 WHERE domain = 'software' AND role = 'other' AND parent_id IS NOT NULL;
