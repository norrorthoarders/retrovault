-- Whether there is a box, and a currency per side of the trade.
--
-- Two things the entry could not previously record.
--
-- has_box: condition_box already existed, but there was nowhere to say whether a
-- box exists at all. "Not graded" and "there is no box" are different facts, and
-- completeness could not settle it either - 'loose' says something about the
-- whole entry, not about the box specifically, and a bare board that never
-- shipped in a box is not the same as one whose box was lost.
--
-- sold_currency: one currency column served both the purchase and the sale, so a
-- card bought in SEK and sold in EUR had to be recorded as one or the other and
-- the other figure was then wrong. Nullable rather than defaulted: an entry that
-- has not been sold has no sale currency, and inventing one would make every
-- unsold entry look like a completed trade.

ALTER TABLE items
  ADD COLUMN has_box       TINYINT(1) NOT NULL DEFAULT 0 AFTER completeness,
  ADD COLUMN sold_currency CHAR(3)    DEFAULT NULL       AFTER sold_price;

-- Anything already graded better than "no box" plainly has one, so say so rather
-- than making every existing entry look boxless. 'missing' is the grade that
-- means the box is gone, so it is the one value that does not imply a box.
UPDATE items
   SET has_box = 1
 WHERE condition_box IS NOT NULL
   AND condition_box NOT IN ('unknown', 'missing');

-- Entries with a recorded sale keep the single currency they were entered with,
-- so the figure they already show does not change meaning under them.
UPDATE items
   SET sold_currency = currency
 WHERE sold_price IS NOT NULL;

-- v_items selects i.*, and MariaDB expands that to a fixed column list when the
-- view is created. A new column on items is therefore invisible to every query
-- that reads the view - which is nearly all of them - until the view is built
-- again. Nothing about the definition changes here; it is the rebuild that
-- matters.
CREATE OR REPLACE VIEW v_items AS
SELECT
  i.*,
  lib.name AS library_name, lib.slug AS library_slug, lib.accent_color AS library_color,
  lib.kind AS library_kind, lib.owner_id AS library_owner_id,
  c.domain AS domain, c.path AS category_path, c.depth AS category_depth,
  p.name  AS platform_name,  p.slug AS platform_slug, p.accent_color AS platform_color,
  pv.name AS platform_vendor,
  c.name  AS category_name,  c.slug AS category_slug,
  g.name  AS genre_name,     g.slug AS genre_slug,
  d.name  AS developer_name, d.slug AS developer_slug, d.website AS developer_website, d.logo_filename AS developer_logo,
  pb.name AS publisher_name, pb.slug AS publisher_slug,
  t.name  AS title_name,     t.slug AS title_slug, t.work_key AS title_work_key,
  t.synopsis AS title_synopsis,
  hm.name AS model_name,     hm.slug AS model_slug,
  img.filename AS cover_filename,
  loc.name AS location_name, loc.path AS location_path
FROM items i
JOIN libraries lib ON lib.id = i.library_id
JOIN platforms  p  ON p.id  = i.platform_id
LEFT JOIN vendors pv ON pv.id = p.vendor_id
JOIN categories c  ON c.id  = i.category_id
LEFT JOIN genres          g   ON g.id   = i.genre_id
LEFT JOIN companies       d   ON d.id   = i.developer_id
LEFT JOIN companies       pb  ON pb.id  = i.publisher_id
LEFT JOIN titles          t   ON t.id   = i.title_id
LEFT JOIN hardware_models hm  ON hm.id  = i.model_id
LEFT JOIN item_images     img ON img.id = i.cover_image_id
LEFT JOIN locations       loc ON loc.id = i.location_id
WHERE i.deleted_at IS NULL;
