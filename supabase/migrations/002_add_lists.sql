-- Migration 002: Add multiple lists support
-- Run this in Supabase SQL Editor BEFORE updating the app

-- 1. Create lists table
CREATE TABLE lists (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT DEFAULT '',
  position INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable Realtime on lists table
ALTER PUBLICATION supabase_realtime ADD TABLE lists;

-- 3. RLS open for family use
ALTER TABLE lists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON lists FOR ALL USING (true) WITH CHECK (true);

-- 4. Add list_id column to products (defaults to 'supermercado' for existing data)
ALTER TABLE products ADD COLUMN list_id TEXT NOT NULL DEFAULT 'supermercado';

-- 5. Insert default lists
INSERT INTO lists (id, name, icon, position) VALUES
  ('supermercado', 'Supermercado', '🛒', 0),
  ('fruta-verdura', 'Fruta y Verdura', '🥬', 1);
