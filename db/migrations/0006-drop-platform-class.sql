-- A platform has no kind of its own.
--
-- platforms.class_id said whether a platform held computers, consoles or
-- handhelds - the same fact every machine model filed under it already carries
-- in its category. Two records of one thing, free to disagree, and the model is
-- the one that decides: an Amiga 500 is a computer because its model says so.
--
-- The kind is derived now (platform_kinds()), from the commonest machine
-- category among the platform's models. A platform with no models yet reports
-- none, which is honest rather than a default.
--
-- platform_classes goes with it: nothing read it once the column was gone.

ALTER TABLE platforms
  DROP FOREIGN KEY fk_platforms_class;

ALTER TABLE platforms
  DROP KEY idx_platforms_class,
  DROP COLUMN class_id;

DROP TABLE IF EXISTS platform_classes;
