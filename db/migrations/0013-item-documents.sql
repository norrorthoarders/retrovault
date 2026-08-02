-- Documents an entry points at.
--
-- The metadata lookup finds manuals, schematics and ROM listings archived at the
-- source, and listed them with "not imported" underneath - which told you the
-- manual exists somewhere and left you to write the address down by hand.
--
-- Links rather than files, deliberately. A scanned service manual is tens of
-- megabytes, it is already hosted by somebody who curates it, and copying it here
-- would make this instance responsible for storage and for a redistribution
-- question nobody asked. What is worth keeping is that the document exists and
-- where it is.
CREATE TABLE IF NOT EXISTS item_documents (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  item_id    INT UNSIGNED NOT NULL,
  label      VARCHAR(200)  NOT NULL,
  url        VARCHAR(1000) NOT NULL,
  -- Where it came from, so a link found by a scraper can be told from one
  -- somebody typed - and so a re-run can leave the typed ones alone.
  source     VARCHAR(60)  DEFAULT NULL,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_item_documents_item (item_id),
  -- The same address twice on one entry is a duplicate, not a second document.
  UNIQUE KEY uq_item_documents (item_id, url(255)),
  CONSTRAINT fk_item_documents_item FOREIGN KEY (item_id) REFERENCES items (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
