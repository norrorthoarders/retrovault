-- What the release is, as against what you think of your copy.
--
-- A lookup's summary was being written into `notes`, which is the field somebody
-- keeps their own remarks in - "bought at Retro Gathering 2019, box has a tear,
-- disk 2 is a replacement". Importing a description overwrote that, or sat on top
-- of it, and there was no way to have both.
--
-- They are different things and belong in different columns: a description is
-- about the release and is the same for every copy of it; a note is about this
-- one.
ALTER TABLE items
  ADD COLUMN description TEXT DEFAULT NULL AFTER notes;

-- Searchable too. Somebody looking for "platformer" is looking for words that are
-- now in the description rather than the notes.
ALTER TABLE items DROP INDEX ft_items_search;
ALTER TABLE items ADD FULLTEXT KEY ft_items_search (title, subtitle, notes, description);
