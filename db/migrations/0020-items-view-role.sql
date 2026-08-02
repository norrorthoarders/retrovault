-- What kind of thing an entry is, on the browse view.
--
-- `categories.role` already says whether a branch holds machines, peripherals or
-- software, but v_items did not carry it - so the hardware browser could not
-- filter machines from cards, and neither list could say which it was showing
-- without a query per row.
--
-- The view is replaced rather than altered, which is how views are changed.
DROP VIEW IF EXISTS v_items;
CREATE OR REPLACE VIEW v_items AS
SELECT
  i.*,
  lib.name AS library_name, lib.slug AS library_slug, lib.accent_color AS library_color,
  lib.kind AS library_kind, lib.owner_id AS library_owner_id,
  c.domain AS domain, c.path AS category_path, c.depth AS category_depth,
  p.name  AS platform_name,  p.slug AS platform_slug, p.accent_color AS platform_color,
  pv.name AS platform_vendor,
  c.name  AS category_name,  c.slug AS category_slug, c.role AS category_role,
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
LEFT JOIN companies pv ON pv.id = p.vendor_id
JOIN categories c  ON c.id  = i.category_id
LEFT JOIN companies       d   ON d.id   = i.developer_id
LEFT JOIN companies       pb  ON pb.id  = i.publisher_id
LEFT JOIN titles          t   ON t.id   = i.title_id
LEFT JOIN hardware_models hm  ON hm.id  = i.model_id
LEFT JOIN item_images     img ON img.id = i.cover_image_id
LEFT JOIN locations       loc ON loc.id = i.location_id
WHERE i.deleted_at IS NULL;
