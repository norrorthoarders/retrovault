-- What a copy actually came on, as a list.
--
-- `items.media_type` is one free-text box and `media_count` a number beside it,
-- so a release that came on a cartridge *and* a manual disk, or three floppies
-- and a CD, had to be flattened into a sentence. The software model editor has
-- had proper rows for this since it was written - a medium from the shared
-- vocabulary and a quantity, reorderable - and the entry form never got them.
--
-- Same shape as software_model_media, because it is the same list about a
-- different thing.
CREATE TABLE IF NOT EXISTS item_media (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  item_id    INT UNSIGNED NOT NULL,
  medium     VARCHAR(60)  NOT NULL,
  quantity   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  sort_order INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_item_media_item (item_id, sort_order),
  CONSTRAINT fk_item_media_item FOREIGN KEY (item_id)
    REFERENCES items (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- What is already there, carried over. An entry saying "3.5\" floppy x 3" means
-- the same thing as one row of that medium with a quantity of three, and leaving
-- it behind would empty the field for every entry that has one.
INSERT INTO item_media (item_id, medium, quantity, sort_order)
SELECT id, media_type, GREATEST(1, media_count), 0
  FROM items
 WHERE media_type IS NOT NULL AND media_type <> '';
