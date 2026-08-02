-- Which machines one particular card fits, where its model does not say.
--
-- The model stays the authority when it has an answer: a copy of a BigRAM 2008
-- cannot fit something a BigRAM 2008 does not. This is for the card with no
-- model, or whose model has never been told.

CREATE TABLE IF NOT EXISTS item_fits (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  item_id        INT UNSIGNED NOT NULL,
  fits_model_id  INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_item_fits (item_id, fits_model_id),
  KEY idx_item_fits_target (fits_model_id),
  CONSTRAINT fk_item_fits_item
    FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE,
  CONSTRAINT fk_item_fits_target
    FOREIGN KEY (fits_model_id) REFERENCES hardware_models (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
