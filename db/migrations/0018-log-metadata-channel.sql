-- A third stream: what the metadata sources were asked and what they answered.
--
-- The column was an ENUM of the two streams that existed, so writing 'metadata'
-- was truncated and the entry lost - and log_event() rewrites an unknown channel
-- to 'server' before it gets here, which hid it twice over. The tab counting
-- lookups said zero while lookups were being logged.
ALTER TABLE logs
  MODIFY COLUMN channel ENUM('security','server','metadata') NOT NULL DEFAULT 'server';
