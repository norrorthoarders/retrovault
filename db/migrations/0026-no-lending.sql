-- Lending, removed.
--
-- It was half-removed already: status_options() dropped 'lent' with a note
-- saying three date columns for something that goes stale the moment an item
-- comes back was the wrong shape, and that lending wants a log of loans rather
-- than a flag on the object. The columns and the enum value stayed behind, so
-- the API still accepted lent_to and lent_on and a client could set a status the
-- web would not offer. Half-removed is worse than either: it is a feature nobody
-- can reach and everybody has to keep working around.
--
-- Any entry still marked lent becomes owned, which is what it is: the thing is
-- yours, it is just somewhere else at the moment. Doing this before the enum
-- changes matters - MySQL turns a value that is no longer in the list into the
-- empty string, and an empty status is a row no filter will ever match again.
UPDATE items SET status = 'owned' WHERE status = 'lent';

ALTER TABLE items
  MODIFY status ENUM('owned','wishlist','ordered','sold') NOT NULL DEFAULT 'owned';

-- What was recorded is preserved rather than dropped on the floor. Somebody who
-- wrote "lent to Anders, March" deserves to still be able to read that, and the
-- notes column is where the rest of the human sentences already live.
UPDATE items
   SET notes = TRIM(CONCAT(
         COALESCE(NULLIF(notes, ''), ''),
         IF(COALESCE(NULLIF(notes, ''), '') = '', '', '\n\n'),
         'Was recorded as lent to ', lent_to,
         IFNULL(CONCAT(' on ', DATE_FORMAT(lent_on, '%Y-%m-%d')), ''), '.'))
 WHERE lent_to IS NOT NULL AND lent_to <> '';

ALTER TABLE items
  DROP COLUMN lent_to,
  DROP COLUMN lent_on;
