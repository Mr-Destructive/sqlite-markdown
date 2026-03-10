PRAGMA journal_mode = WAL;

CREATE TABLE IF NOT EXISTS pages (
  id INTEGER PRIMARY KEY,
  src_path TEXT NOT NULL UNIQUE,
  out_path TEXT NOT NULL UNIQUE,
  title TEXT,
  markdown_src TEXT,
  body_html TEXT,
  html TEXT,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS template_sources (
  name TEXT PRIMARY KEY,
  path TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS post_sources (
  src_path TEXT PRIMARY KEY,
  out_path TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS post_meta_sources (
  src_path TEXT PRIMARY KEY,
  meta_path TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS templates (
  name TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS pages_fts USING fts4(
  src_path,
  out_path,
  title,
  body
);
