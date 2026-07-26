-- Genericized sample; `<log_archive>` is your log store's table or cluster.
--
-- Only run when the error query comes back empty, to tell "the environment was
-- quiet" apart from "the archive stopped receiving logs". One day of rows, so the
-- scan stays cheap.
SELECT
  dateDiff('minute', max(dt), now()) AS lag_minutes,
  count() AS rows_1d
FROM <log_archive>
WHERE _row_type = 1 AND dt > now() - INTERVAL 1 DAY
