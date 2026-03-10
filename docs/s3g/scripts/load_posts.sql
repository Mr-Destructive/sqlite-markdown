-- Load posts from post_sources table into pages table.
-- No .shell commands required.
--
-- Required:
--   post_sources(src_path, out_path) rows exist.
--
-- Example:
-- INSERT INTO post_sources(src_path, out_path) VALUES
--   ('posts/index.md', 'public/index.html'),
--   ('posts/blog/first.md', 'public/blog/first.html');
--
-- Usage:
-- sqlite3 site.db < docs/s3g/scripts/load_posts.sql

INSERT INTO pages(src_path, out_path)
SELECT src_path, out_path
FROM post_sources
WHERE src_path IS NOT NULL AND src_path <> '' AND out_path IS NOT NULL AND out_path <> ''
ON CONFLICT(src_path) DO UPDATE SET out_path = excluded.out_path;
