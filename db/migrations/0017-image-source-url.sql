-- Where an imported picture came from.
--
-- The content hash tells us a picture is already here *after* it has been
-- fetched, which is the right check on the way in but too late for a review
-- screen: somebody ticks six pictures, waits, and is then told that five of them
-- were already on the entry. Remembering the address it was taken from lets the
-- screen say so before anything is ticked.
--
-- Null for anything uploaded from a phone or a disk, which is most of them.
ALTER TABLE item_images
  ADD COLUMN source_url VARCHAR(500) DEFAULT NULL AFTER provenance;
