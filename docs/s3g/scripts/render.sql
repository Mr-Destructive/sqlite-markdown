-- Requires:
-- 1) sqlite3 site.db -cmd ".load ./markdown" < this_file.sql
-- 2) pages table populated with src_path/out_path rows
-- Optional:
--   .parameter set @index_out 'public/site-index.html'

BEGIN;

UPDATE pages
SET
  markdown_src = CAST(readfile(src_path) AS TEXT),
  html = markdown(CAST(readfile(src_path) AS TEXT)),
  updated_at = datetime('now'),
  title = CASE
    WHEN substr(CAST(readfile(src_path) AS TEXT), 1, 2) = '# ' THEN
      trim(
        CASE
          WHEN instr(CAST(readfile(src_path) AS TEXT), char(10)) > 0 THEN
            substr(
              CAST(readfile(src_path) AS TEXT),
              3,
              instr(CAST(readfile(src_path) AS TEXT), char(10)) - 3
            )
          ELSE substr(CAST(readfile(src_path) AS TEXT), 3)
        END
      )
    ELSE trim(replace(replace(src_path, '.md', ''), '/', ' '))
  END;

-- Write each HTML page to disk.
SELECT writefile(
  out_path,
  '<!doctype html>' || char(10) ||
  '<html lang="en"><head><meta charset="utf-8">' ||
  '<meta name="viewport" content="width=device-width,initial-scale=1">' ||
  '<title>' || replace(COALESCE(title, 'Untitled'), '&', '&amp;') || '</title>' ||
  '<style>body{max-width:740px;margin:2rem auto;padding:0 1rem;font:18px/1.6 Georgia,serif}pre{overflow:auto;padding:.8rem;background:#f4f4f4}code{font-family:ui-monospace,monospace}</style>' ||
  '</head><body>' || char(10) ||
  COALESCE(html, '') || char(10) ||
  '</body></html>'
)
FROM pages;

-- Write a simple generated site index.
SELECT writefile(
  COALESCE(@index_out, 'site-index.html'),
  '<!doctype html>' || char(10) ||
  '<html lang="en"><head><meta charset="utf-8">' ||
  '<meta name="viewport" content="width=device-width,initial-scale=1">' ||
  '<title>Site Index</title></head><body>' ||
  '<h1>Site Index</h1><ul>' ||
  COALESCE(
    (
      SELECT group_concat(
        '<li><a href="' || out_path || '">' ||
        replace(COALESCE(title, out_path), '&', '&amp;') ||
        '</a></li>',
        ''
      )
      FROM (SELECT out_path, title FROM pages ORDER BY out_path)
    ),
    ''
  ) ||
  '</ul></body></html>'
);

COMMIT;
