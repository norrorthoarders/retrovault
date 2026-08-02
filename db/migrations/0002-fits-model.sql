-- Hardware compatibility becomes a reference, not a sentence.
--
-- hardware_models.fits held free text: "A1200 only", "any ISA PC". Useful to
-- read and useless to query - "what fits my A500" could not be answered, which
-- is the one question the field existed for. It now points at the machine model
-- it fits, chosen from the models on that platform.
--
-- The old text is kept in fits_note rather than thrown away: some of it does not
-- map to one model ("any ISA PC") and losing it would lose real information.

ALTER TABLE hardware_models
  ADD COLUMN fits_model_id INT UNSIGNED DEFAULT NULL AFTER fits,
  ADD KEY idx_hwmodels_fits_model (fits_model_id),
  ADD CONSTRAINT fk_hwmodels_fits_model
      FOREIGN KEY (fits_model_id) REFERENCES hardware_models (id) ON DELETE SET NULL;

-- Where the text names exactly one model on the same platform, resolve it.
UPDATE hardware_models p
  JOIN hardware_models m
    ON m.platform_id = p.platform_id
   AND m.id <> p.id
   AND LOWER(m.name) = LOWER(TRIM(p.fits))
   SET p.fits_model_id = m.id
 WHERE p.fits IS NOT NULL AND p.fits <> '';

ALTER TABLE hardware_models CHANGE COLUMN fits fits_note VARCHAR(200) DEFAULT NULL;
