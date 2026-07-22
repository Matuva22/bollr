-- ============================================================
-- Bollr — hent siste vurderinger for et enkelt bakeri (detaljsiden)
-- Kjør denne i Supabase SQL Editor
-- ============================================================

CREATE OR REPLACE FUNCTION get_bakery_ratings(p_bakery_id uuid)
RETURNS TABLE (
  score      numeric,
  note       text,
  tags       text[],
  photo_url  text,
  created_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT r.score, r.note, r.tags, r.photo_url, r.created_at
  FROM ratings r
  WHERE r.bakery_id = p_bakery_id
  ORDER BY r.created_at DESC
  LIMIT 10;
$$;

GRANT EXECUTE ON FUNCTION get_bakery_ratings(uuid) TO anon, authenticated;
