-- What version is on the board.
--
-- A ROM revision, a flashed firmware, the sticker on the EPROM. Free text
-- because every maker numbered these differently and half of them not at all,
-- and because the field is only useful if nothing about a real board is
-- unrecordable in it.

ALTER TABLE item_hardware
  ADD COLUMN firmware VARCHAR(80) DEFAULT NULL AFTER board_revision;
