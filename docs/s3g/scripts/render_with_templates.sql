-- Render pages using file-backed templates loaded into templates table.
-- Requires:
-- 1) sqlite3 site.db -cmd ".load ./markdown" < docs/s3g/scripts/render_with_templates.sql
-- 2) templates table has at least: layout, post
-- 3) pages table has src_path/out_path rows
-- 4) optional: post_meta_sources has src_path -> meta_path (.json)
--
-- Template placeholders:
-- layout: {{title}}, {{body}}
-- post:   {{title}}, {{content}}, {{description}}, {{date}}

BEGIN;

UPDATE pages
SET
  markdown_src = CAST(readfile(src_path) AS TEXT),
  body_html = markdown(CAST(readfile(src_path) AS TEXT)),
  updated_at = datetime('now'),
  title = COALESCE(
    CASE
      WHEN json_valid(CAST(readfile((SELECT meta_path FROM post_meta_sources ms WHERE ms.src_path = pages.src_path)) AS TEXT)) THEN
        json_extract(CAST(readfile((SELECT meta_path FROM post_meta_sources ms WHERE ms.src_path = pages.src_path)) AS TEXT), '$.title')
      ELSE NULL
    END,
    CASE
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
    END
  );

WITH
layout_tpl AS (
  SELECT content AS tpl FROM templates WHERE name = 'layout'
),
post_tpl AS (
  SELECT content AS tpl FROM templates WHERE name = 'post'
)
UPDATE pages
SET html = replace(
  replace(
    (SELECT tpl FROM layout_tpl),
    '{{title}}',
    replace(replace(replace(replace(COALESCE(title, 'Untitled'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;')
  ),
  '{{body}}',
  replace(
    replace(
      replace(
        replace(
          (SELECT tpl FROM post_tpl),
          '{{title}}',
          replace(replace(replace(replace(COALESCE(title, 'Untitled'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;')
        ),
        '{{content}}',
        COALESCE(body_html, '')
      ),
      '{{description}}',
      COALESCE(
        CASE
          WHEN json_valid(CAST(readfile((SELECT meta_path FROM post_meta_sources ms WHERE ms.src_path = pages.src_path)) AS TEXT)) THEN
            json_extract(CAST(readfile((SELECT meta_path FROM post_meta_sources ms WHERE ms.src_path = pages.src_path)) AS TEXT), '$.description')
          ELSE NULL
        END,
        ''
      )
    ),
    '{{date}}',
    COALESCE(
      CASE
        WHEN json_valid(CAST(readfile((SELECT meta_path FROM post_meta_sources ms WHERE ms.src_path = pages.src_path)) AS TEXT)) THEN
          json_extract(CAST(readfile((SELECT meta_path FROM post_meta_sources ms WHERE ms.src_path = pages.src_path)) AS TEXT), '$.date')
        ELSE NULL
      END,
      ''
    )
  )
);

SELECT writefile(out_path, html) FROM pages;

DELETE FROM pages_fts;

INSERT INTO pages_fts(docid, src_path, out_path, title, body)
SELECT
  id,
  src_path,
  out_path,
  COALESCE(title, ''),
  COALESCE(markdown_src, '')
FROM pages;

SELECT writefile(
  'public/site-index.html',
  '<!doctype html><html lang="en"><head><meta charset="utf-8">' ||
  '<meta name="viewport" content="width=device-width,initial-scale=1">' ||
  '<title>Site Index</title></head><body><h1>Site Index</h1><ul>' ||
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
