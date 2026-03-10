-- Full-text search query (FTS4).
-- Usage:
-- sqlite3 site.db \
--   -cmd ".parameter init" \
--   -cmd ".parameter set @q 'sqlite'" \
--   < docs/s3g/scripts/search.sql

.headers on
.mode column

SELECT
  p.src_path,
  p.out_path,
  p.title,
  snippet(pages_fts, '<b>', '</b>', ' ... ', 3, 24) AS snippet
FROM pages_fts
JOIN pages p ON p.id = pages_fts.docid
WHERE pages_fts MATCH @q
ORDER BY p.updated_at DESC, p.id DESC
LIMIT 20;
