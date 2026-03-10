.bail on

-- Single entry point:
-- 1) Ensure tables exist
-- 2) Load templates from files
-- 3) Load posts from post_sources
-- 4) Render HTML using markdown extension

.read docs/s3g/scripts/schema.sql
.load ./markdown
.read docs/s3g/scripts/load_templates.sql
.read docs/s3g/scripts/load_posts.sql
.read docs/s3g/scripts/render_with_templates.sql
