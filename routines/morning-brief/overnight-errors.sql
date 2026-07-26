-- Genericized sample. `<log_archive>` stands in for the table or S3 cluster your
-- log store exposes; the shape of the query is the part worth keeping.
--
-- Groups error-ish log lines into signatures per service, and reports each
-- signature's overnight count next to its older baseline so the model can tell a
-- new failure apart from steady noise.
WITH lines AS (
  SELECT dt,
    JSONExtract(raw, 'container_name', 'Nullable(String)') AS container,
    JSONExtract(raw, 'log', 'Nullable(String)') AS raw_log
  FROM <log_archive>
  WHERE _row_type = 1 AND dt > now() - INTERVAL 7 DAY
),
app AS (
  SELECT dt,
    replaceRegexpOne(container, '^/ecs-(.+?)-[0-9]+-.*$', '\\1') AS svc,
    coalesce(nullIf(JSONExtract(raw_log, 'message', 'Nullable(String)'), ''), raw_log) AS msg,
    JSONExtract(raw_log, 'level', 'Nullable(String)') AS lvl,
    JSONExtract(raw_log, 'key', 'Nullable(String)') AS key
  FROM lines
  WHERE raw_log IS NOT NULL
),
-- Retention is shorter than the 7-day filter above (about 3 days in practice), so the
-- baseline span has to be measured, not assumed, or the rate comparison is nonsense.
span AS (SELECT dateDiff('hour', min(dt), now()) AS total_h FROM lines)
SELECT
  svc,
  any(key) AS key,
  any(lvl) AS level,
  -- Collapse ids and numbers so the same failure groups into one signature.
  substring(replaceRegexpAll(msg, '[0-9a-f]{8,}|[0-9]+', '#'), 1, 160) AS signature,
  countIf(dt > now() - INTERVAL 16 HOUR) AS overnight,
  countIf(dt <= now() - INTERVAL 16 HOUR) AS baseline,
  (SELECT total_h FROM span) - 16 AS baseline_hours
FROM app
WHERE match(msg, '(?i)(error|exception|fatal|unhandled|failed)')
  -- Stack-trace continuation lines are part of the frame above, not new errors.
  AND NOT match(msg, '^\\s+(at |\\.\\.\\.)')
  AND (lvl IS NULL OR lvl NOT IN ('info', 'debug', 'trace'))
GROUP BY svc, signature
HAVING overnight > 0
ORDER BY baseline = 0 DESC, overnight DESC
LIMIT 20
