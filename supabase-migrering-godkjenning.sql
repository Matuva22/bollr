-- ============================================================
-- Bollr — migrasjon: legg til tags og godkjenning
-- Kjør denne i Supabase SQL Editor på eksisterende database
-- ============================================================

ALTER TABLE ratings ADD COLUMN IF NOT EXISTS tags text[] DEFAULT '{}';
ALTER TABLE ratings ADD COLUMN IF NOT EXISTS approved boolean NOT NULL DEFAULT false;

-- Godkjenn alle eksisterende vurderinger (lagt inn før modereringssystemet)
UPDATE ratings SET approved = true WHERE approved = false;

-- Oppdater bakery_averages() til å bare telle godkjente vurderinger
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
  LEFT JOIN ratings r ON r.bakery_id = b.id AND r.approved = true
  GROUP BY b.id, b.name, b.place, b.type, b.lat, b.lng, b.created_at
  ORDER BY avg_score DESC NULLS LAST;
$$;

GRANT EXECUTE ON FUNCTION bakery_averages() TO anon, authenticated;
