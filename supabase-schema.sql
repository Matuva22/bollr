-- ============================================================
-- Bollr — komplett databaseoppsett
-- Slett alt i SQL Editor og kjør denne filen
-- ============================================================

-- Rydd opp eksisterende
DROP FUNCTION IF EXISTS bakery_averages() CASCADE;
DROP TABLE IF EXISTS wishlist CASCADE;
DROP TABLE IF EXISTS ratings CASCADE;
DROP TABLE IF EXISTS bakeries CASCADE;

-- ── Tabeller ──────────────────────────────────────────────

CREATE TABLE bakeries (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text NOT NULL,
  place      text NOT NULL DEFAULT '',
  type       text NOT NULL DEFAULT 'Bolle',
  lat        double precision,
  lng        double precision,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ratings (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bakery_id  uuid NOT NULL REFERENCES bakeries(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  smak       int CHECK (smak BETWEEN 1 AND 6),
  saft       int CHECK (saft BETWEEN 1 AND 6),
  deig       int CHECK (deig BETWEEN 1 AND 6),
  fyll       int CHECK (fyll BETWEEN 1 AND 6),
  sodme      int CHECK (sodme BETWEEN 1 AND 6),
  utseende   int CHECK (utseende BETWEEN 1 AND 6),
  pris       int CHECK (pris BETWEEN 1 AND 6),
  note       text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (bakery_id, user_id)
);

CREATE TABLE wishlist (
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bakery_id  uuid NOT NULL REFERENCES bakeries(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, bakery_id)
);

-- ── Row Level Security ─────────────────────────────────────

ALTER TABLE bakeries ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;

-- Bakerier: alle kan lese, innloggede kan legge til
CREATE POLICY "bakeries_read"   ON bakeries FOR SELECT USING (true);
CREATE POLICY "bakeries_insert" ON bakeries FOR INSERT TO authenticated WITH CHECK (true);

-- Vurderinger: kun egne rader
CREATE POLICY "ratings_read"   ON ratings FOR SELECT  TO authenticated USING (user_id = auth.uid());
CREATE POLICY "ratings_insert" ON ratings FOR INSERT  TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "ratings_update" ON ratings FOR UPDATE  TO authenticated USING (user_id = auth.uid());
CREATE POLICY "ratings_delete" ON ratings FOR DELETE  TO authenticated USING (user_id = auth.uid());

-- Ønskeliste: kun egne rader
CREATE POLICY "wishlist_read"   ON wishlist FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "wishlist_insert" ON wishlist FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "wishlist_delete" ON wishlist FOR DELETE TO authenticated USING (user_id = auth.uid());

-- ── Aggregatfunksjon (SECURITY DEFINER) ────────────────────

CREATE FUNCTION bakery_averages()
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
