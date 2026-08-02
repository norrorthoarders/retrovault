-- A manufacturer has a founding year and a website; neither had anywhere to go.
--
-- Named and typed to match companies, which has carried both for studios all
-- along. A manufacturer and a studio are both firms, and answering "when did
-- they start" two different ways would be two things to remember.

ALTER TABLE vendors
  ADD COLUMN founded_year SMALLINT UNSIGNED DEFAULT NULL AFTER country,
  ADD COLUMN website      VARCHAR(500)      DEFAULT NULL AFTER founded_year;
