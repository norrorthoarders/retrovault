-- A peripheral fits more than one machine.
--
-- fits_model_id could name exactly one, which is wrong for most real cards: a
-- Blizzard 1230 fits an A1200 and an A1200T, an ISA sound card fits every PC
-- anybody built. One column could not say so, and the note it replaced could
-- say it only in prose.

CREATE TABLE IF NOT EXISTS model_fits (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- The peripheral.
  model_id       INT UNSIGNED NOT NULL,
  -- A machine model it goes in.
  fits_model_id  INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  -- One row per pair: saying it twice is saying it once.
  UNIQUE KEY uq_model_fits (model_id, fits_model_id),
  KEY idx_model_fits_target (fits_model_id),
  CONSTRAINT fk_model_fits_model
    FOREIGN KEY (model_id) REFERENCES hardware_models (id) ON DELETE CASCADE,
  CONSTRAINT fk_model_fits_target
    FOREIGN KEY (fits_model_id) REFERENCES hardware_models (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Carry over whatever the single column held.
INSERT IGNORE INTO model_fits (model_id, fits_model_id)
SELECT id, fits_model_id FROM hardware_models WHERE fits_model_id IS NOT NULL;

-- And stop keeping the answer in two places.
ALTER TABLE hardware_models DROP FOREIGN KEY fk_hwmodels_fits_model;
ALTER TABLE hardware_models DROP COLUMN fits_model_id;
