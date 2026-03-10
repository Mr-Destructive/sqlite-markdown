-- Load templates from files listed in template_sources.
-- Required:
--   template_sources(name, path) rows exist.
--
-- Example:
-- INSERT INTO template_sources(name, path) VALUES
--   ('layout', 'docs/s3g/templates/layout.html'),
--   ('post',   'docs/s3g/templates/post.html');
--
-- sqlite3 site.db < docs/s3g/scripts/load_templates.sql

BEGIN;

INSERT INTO templates(name, content, updated_at)
SELECT
  ts.name,
  CAST(readfile(ts.path) AS TEXT),
  datetime('now')
FROM template_sources ts
WHERE 1
ON CONFLICT(name) DO UPDATE SET
  content = excluded.content,
  updated_at = excluded.updated_at;

COMMIT;
