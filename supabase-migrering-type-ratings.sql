-- ============================================================
-- Bollr — hent vurderinger per bolletyp (for statistikk-siden)
-- Kjør i Supabase SQL Editor
-- ============================================================

CREATE OR REPLACE FUNCTION get_type_ratings(p_type text)
RETURNS TABLE (
  bakery_name  text,
  bakery_place text,
  score        numeric,
  note         text,
  photo_url    text,
  created_at   timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT b.name, b.place, r.score, r.note, r.photo_url, r.created_at
  FROM ratings r
  JOIN bakeries b ON b.id = r.bakery_id
  WHERE b.type = p_type AND r.approved = true
  ORDER BY r.score DESC NULLS LAST, r.created_at DESC
  LIMIT 15;
$$;

GRANT EXECUTE ON FUNCTION get_type_ratings(text) TO anon, authenticated;
