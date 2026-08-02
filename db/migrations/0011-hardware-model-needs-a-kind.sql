-- A hardware model must have a kind, and the database should say so.
--
-- hardware_models.category_id decided whether a model is a machine or a part -
-- effective_fits(), fittable_peripherals() and is_machine_category() all read it -
-- and the constraint was ON DELETE SET NULL. So deleting a category did not
-- refuse and did not cascade: it silently emptied that column, leaving models
-- that were neither a machine nor a part, and those rows then fell out of every
-- query that inner-joins categories. Nothing in the interface showed it.
--
-- tree_save() now counts hardware_models before allowing a branch to be deleted,
-- but a guard in one controller is not the same as a rule. A direct DELETE, a
-- future code path, or a second delete route added later all bypass it. RESTRICT
-- puts the rule where it cannot be bypassed: deleting a category that is still
-- the kind of something fails, and the failure is the point.
--
-- Two steps, in this order, because RESTRICT cannot be added while rows already
-- violate it.

-- 1. Repair what is already broken. Anything orphaned by the old behaviour is
--    filed under a kind derived from what the model looks like: a row with an
--    interface is something that plugs into a machine, so it is a part; one
--    without is a machine. Both land in a real category rather than a made-up
--    one, so nothing has to be invented and nothing stays NULL.
UPDATE hardware_models hm
   SET hm.category_id = (
         SELECT c.id FROM categories c
          WHERE c.domain = 'hardware'
            AND c.role = CASE WHEN hm.interface IS NULL AND hm.interface_vocab_id IS NULL
                              THEN 'machine' ELSE 'peripheral' END
          ORDER BY c.depth, c.id LIMIT 1)
 WHERE hm.category_id IS NULL;

-- A row that still has no kind means the hardware branch of the tree is missing
-- entirely, which the schema does not allow. Put it under whatever category
-- exists rather than leaving the migration unable to finish.
UPDATE hardware_models
   SET category_id = (SELECT id FROM categories ORDER BY depth, id LIMIT 1)
 WHERE category_id IS NULL;

-- 2. NOT NULL, and refuse the delete rather than nulling the column.
ALTER TABLE hardware_models
  DROP FOREIGN KEY fk_hwm_category;

ALTER TABLE hardware_models
  MODIFY COLUMN category_id INT UNSIGNED NOT NULL;

ALTER TABLE hardware_models
  ADD CONSTRAINT fk_hwm_category
    FOREIGN KEY (category_id) REFERENCES categories (id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
