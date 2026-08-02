-- A machine is not a kind of thing, it is a place things go.
--
-- Roots were being marked 'machine' - the branch for an Amiga said it held
-- machines - which reads sensibly and is wrong: an Amiga branch holds machines
-- *and* peripherals *and* games *and* applications, and it is the branches under
-- it that say which. A root that claims a kind makes the tree lie about
-- everything filed anywhere beneath it.
UPDATE categories SET role = 'other' WHERE parent_id IS NULL;
