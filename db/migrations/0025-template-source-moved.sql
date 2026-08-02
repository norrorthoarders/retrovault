-- The starter data moved to github.com/norrorthoarders/retrovault.
--
-- The default in the code is only consulted when nothing is stored, and an
-- instance that has ever opened Instance settings has a row - so changing the
-- default alone would leave every existing install fetching from an address
-- nobody publishes to any more, and it would keep working for a while, which is
-- the worst kind of wrong.
--
-- Only where it is still the old default. An address somebody typed themselves is
-- theirs: a fork, a mirror on the LAN, a checkout served over HTTP. Overwriting
-- that would be this migration deciding it knows better.
UPDATE settings
   SET value = 'https://raw.githubusercontent.com/norrorthoarders/retrovault/main/starter-data'
 WHERE name = 'template_source'
   AND value IN (
     'https://raw.githubusercontent.com/frossmant/retrovault/main/starter-data',
     'https://raw.githubusercontent.com/frossmant/retrovault/main/starter-data/'
   );
