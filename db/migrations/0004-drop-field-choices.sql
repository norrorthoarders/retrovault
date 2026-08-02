-- model_fields.kind and .options are no longer written or read.
--
-- They existed for a specification that offered a fixed list rather than a free
-- box. The row editor dropped the third input that fed them, so kind has been
-- 'text' and options empty on every row since; nothing renders a select from
-- them either. A column nothing writes and nothing reads only makes the table
-- look as though it does more than it does.
--
-- The width column goes with them: every field has been 'full' since the
-- editor stopped asking.

ALTER TABLE model_fields
  DROP COLUMN kind,
  DROP COLUMN options,
  DROP COLUMN width;
