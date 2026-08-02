-- Where a photograph came from, as against what it is of.
--
-- `kind` already says what a picture shows (box front, media, manual). What it
-- could not say is whether it is the publisher's artwork or a photograph
-- somebody took of the copy on their shelf - and that is the difference that
-- decides whether a scraper may write there.
--
-- Two axes rather than a list of sections: provenance x subject. The sections
-- somebody sees are combinations of the two, which is why hardware and software
-- can show different ones without either meaning a new column.
ALTER TABLE item_images
  ADD COLUMN provenance ENUM('official','personal') NOT NULL DEFAULT 'personal' AFTER kind;

-- 'unit' for the hardware itself: a photograph of a motherboard is not a box
-- front, which is what the Amiga Hardware Database scraper had to call it.
ALTER TABLE item_images
  MODIFY COLUMN kind ENUM('box_front','box_back','box_spine','media','manual',
                          'extras','screenshot','unit','other')
    NOT NULL DEFAULT 'other';

-- Existing rows stay 'personal'.
--
-- There is no reliable way to tell a scraped picture from an uploaded one after
-- the fact, and of the two mistakes, calling somebody's own photograph official
-- is the more misleading - it claims a provenance the picture does not have.
-- Nothing is lost either way: a mislabelled picture is in the wrong section, not
-- gone, and one click moves it.
