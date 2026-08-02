-- sort_order goes from the two tables that never used it.
--
-- Nobody set it on a manufacturer or a platform, so every list was already
-- alphabetical by the tiebreak and the column only offered a way to make the
-- order surprising. Both lists sort by name now.
--
-- The indexes go with it: three of the four on platforms led with a column that
-- was always zero, which made them useless for the ordering they were named
-- after. They lead on name instead.
--
-- Where sort_order still earns its keep - specifications on a model, slots on a
-- machine, categories and genres, which are hand-ordered - it stays.

ALTER TABLE platforms
  DROP KEY idx_platforms_sort,
  DROP KEY idx_platforms_class,
  DROP KEY idx_platforms_library,
  DROP KEY idx_platforms_vendor,
  DROP COLUMN sort_order,
  ADD KEY idx_platforms_name (name),
  ADD KEY idx_platforms_class (class_id, name),
  ADD KEY idx_platforms_library (library_id, name),
  ADD KEY idx_platforms_vendor (vendor_id, name);

ALTER TABLE vendors
  DROP KEY idx_vendors_library,
  DROP COLUMN sort_order,
  ADD KEY idx_vendors_library (library_id, name);
