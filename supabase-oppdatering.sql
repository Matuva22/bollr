-- ============================================================
-- Bollr — SQL-oppdatering (kjør i Supabase SQL Editor)
-- Legger til: per-kriteriums snitt, opprettelsesdato, slett-rettighet
-- ============================================================

-- 1. Oppdater bakery_averages() med per-kriteriums snitt og created_at
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
  avg_smak     numeric,
  avg_saft     numeric,
  avg_deig     numeric,
  avg_fyll     numeric,
  avg_sodme    numeric,
  avg_utseende numeric,
  avg_pris     numeric,
  created_at   timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    b.id, b.name, b.place, b.type, b.lat, b.lng,
    COUNT(r.id) AS rating_count,
    CASE WHEN COUNT(r.id) = 0 THEN NULL ELSE
      ROUND((
          COALESCE(AVG(r.smak)     * 0.20, 0) +
          COALESCE(AVG(r.saft)     * 0.18, 0) +
          COALESCE(AVG(r.deig)     * 0.15, 0) +
          COALESCE(AVG(r.fyll)     * 0.15, 0) +
          COALESCE(AVG(r.sodme)    * 0.12, 0) +
          COALESCE(AVG(r.utseende) * 0.10, 0) +
          COALESCE(AVG(r.pris)     * 0.10, 0)
        ) / NULLIF(
          CASE WHEN AVG(r.smak)     IS NOT NULL THEN 0.20 ELSE 0 END +
          CASE WHEN AVG(r.saft)     IS NOT NULL THEN 0.18 ELSE 0 END +
          CASE WHEN AVG(r.deig)     IS NOT NULL THEN 0.15 ELSE 0 END +
          CASE WHEN AVG(r.fyll)     IS NOT NULL THEN 0.15 ELSE 0 END +
          CASE WHEN AVG(r.sodme)    IS NOT NULL THEN 0.12 ELSE 0 END +
          CASE WHEN AVG(r.utseende) IS NOT NULL THEN 0.10 ELSE 0 END +
          CASE WHEN AVG(r.pris)     IS NOT NULL THEN 0.10 ELSE 0 END
        , 0), 2)
    END AS avg_score,
    ROUND(AVG(r.smak)::numeric,     2) AS avg_smak,
    ROUND(AVG(r.saft)::numeric,     2) AS avg_saft,
    ROUND(AVG(r.deig)::numeric,     2) AS avg_deig,
    ROUND(AVG(r.fyll)::numeric,     2) AS avg_fyll,
    ROUND(AVG(r.sodme)::numeric,    2) AS avg_sodme,
    ROUND(AVG(r.utseende)::numeric, 2) AS avg_utseende,
    ROUND(AVG(r.pris)::numeric,     2) AS avg_pris,
    b.created_at
  FROM bakeries b
  LEFT JOIN ratings r ON r.bakery_id = b.id
  GROUP BY b.id, b.name, b.place, b.type, b.lat, b.lng, b.created_at
  ORDER BY avg_score DESC NULLS LAST;
$$;

GRANT EXECUTE ON FUNCTION bakery_averages() TO anon, authenticated;

-- 2. Gi brukere lov til å slette egne vurderinger
CREATE POLICY "ratings_own_delete" ON ratings
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());
