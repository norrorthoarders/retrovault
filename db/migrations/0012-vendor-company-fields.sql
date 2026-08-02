-- A hardware manufacturer is a company, and should be recorded like one.
--
-- `companies` - the software side - has carried a logo, a closing year, a
-- Wikipedia link and free notes since the beginning. `vendors` had a name, a
-- country, a founding year and a website, so Commodore could be recorded as
-- founded in 1954 but not as gone in 1994, and there was nowhere to put the badge
-- that makes a list of makers readable at a glance.
--
-- The two tables stay separate on purpose - a maker belongs to a library while a
-- studio is shared - but there is no reason for the columns to differ. Same names
-- as companies uses, so anything that reads one shape can read the other.

ALTER TABLE vendors
  ADD COLUMN logo_filename VARCHAR(255) DEFAULT NULL AFTER slug,
  ADD COLUMN defunct_year  SMALLINT UNSIGNED DEFAULT NULL AFTER founded_year,
  ADD COLUMN wikipedia_url VARCHAR(500) DEFAULT NULL AFTER website,
  ADD COLUMN notes         TEXT DEFAULT NULL AFTER wikipedia_url;

-- Where a maker and a studio are plainly the same firm, bring across what the
-- studio already knows rather than making somebody retype it. Matched on the slug,
-- which is the same word on both sides, and only into columns that are still empty
-- so nothing anybody typed is overwritten.
UPDATE vendors v
  JOIN companies c ON c.slug = v.slug
   SET v.defunct_year  = COALESCE(v.defunct_year,  c.defunct_year),
       v.wikipedia_url = COALESCE(v.wikipedia_url, c.wikipedia_url),
       v.notes         = COALESCE(v.notes,         c.notes),
       v.website       = COALESCE(v.website,       c.website),
       v.founded_year  = COALESCE(v.founded_year,  c.founded_year),
       v.country       = COALESCE(v.country,       c.country);

-- Logos are deliberately not copied. logo_filename names a file in
-- public/uploads, and two rows pointing at one file means deleting either takes
-- the other's badge with it.
