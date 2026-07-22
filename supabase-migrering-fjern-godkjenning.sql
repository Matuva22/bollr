-- ============================================================
-- Bollr — migrasjon: fjern godkjenningssteget for vurderinger
-- Kjør denne i Supabase SQL Editor på eksisterende database
-- ============================================================

-- Vurderinger telles og vises nå med én gang, ingen admin-godkjenning
DROP FUNCTION IF EXISTS get_pending_ratings();
DROP FUNCTION IF EXISTS approve_rating(uuid);
DROP FUNCTION IF EXISTS reject_rating(uuid);

ALTER TABLE ratings DROP COLUMN IF EXISTS approved;

CREATE OR REPLACE FUNCTION bakery_averages()
RETURNS TABLE (
  id           uuid,
  name         text,
  place        text,
  type         text,
  lat          double precision,
  lng          double precision,
  rating_count bigint,
  avg_score    numeric,
  created_at   timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    b.id, b.name, b.place, b.type, b.lat, b.lng,
    COUNT(r.id)                    AS rating_count,
    ROUND(AVG(r.score)::numeric,2) AS avg_score,
    b.created_at
  FROM bakeries b
  LEFT JOIN ratings r ON r.bakery_id = b.id
  GROUP BY b.id, b.name, b.place, b.type, b.lat, b.lng, b.created_at
  ORDER BY avg_score DESC NULLS LAST;
$$;

GRANT EXECUTE ON FUNCTION bakery_averages() TO anon, authenticated;

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
  WHERE b.type = p_type
  ORDER BY r.score DESC NULLS LAST, r.created_at DESC
  LIMIT 15;
$$;

GRANT EXECUTE ON FUNCTION get_type_ratings(text) TO anon, authenticated;
