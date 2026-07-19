-- ============================================================
-- Bollr — Supabase-skjema
-- Lim inn i SQL-editoren i Supabase (Database → SQL Editor → New query)
-- og kjør én blokk om gangen om noe feiler.
-- ============================================================


-- ─── 1. Tabeller ─────────────────────────────────────────────────────────

CREATE TABLE bakeries (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name      text NOT NULL,
  place     text NOT NULL,
  type      text NOT NULL DEFAULT 'Bolle',
  lat       double precision,
  lng       double precision,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE ratings (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bakery_id   uuid NOT NULL REFERENCES bakeries(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  smak        smallint CHECK (smak BETWEEN 1 AND 6),
  saft        smallint CHECK (saft BETWEEN 1 AND 6),
  deig        smallint CHECK (deig BETWEEN 1 AND 6),
  fyll        smallint CHECK (fyll BETWEEN 1 AND 6),
  sodme       smallint CHECK (sodme BETWEEN 1 AND 6),
  utseende    smallint CHECK (utseende BETWEEN 1 AND 6),
  pris        smallint CHECK (pris BETWEEN 1 AND 6),
  note        text,
  created_at  timestamptz DEFAULT now(),
  CONSTRAINT one_rating_per_user_bakery UNIQUE (bakery_id, user_id)
);

CREATE TABLE wishlist (
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bakery_id  uuid NOT NULL REFERENCES bakeries(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, bakery_id)
);


-- ─── 2. Offentlig aggregat-funksjon (bypass RLS via SECURITY DEFINER) ────
--
-- Returnerer snitt-score per bakeri uten å eksponere hvem som ga hva.
-- Samme vektformel som i appen: smak 20 %, saftighet 18 %, osv.
-- Normaliserer automatisk hvis bare noen kriterier er fylt ut.

CREATE OR REPLACE FUNCTION bakery_averages()
RETURNS TABLE (
  id           uuid,
  name         text,
  place        text,
  type         text,
  lat          double precision,
  lng          double precision,
  rating_count bigint,
  avg_score    numeric
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
      ROUND(
        (
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
        , 0), 2
      )
    END AS avg_score
  FROM bakeries b
  LEFT JOIN ratings r ON r.bakery_id = b.id
  GROUP BY b.id, b.name, b.place, b.type, b.lat, b.lng
  ORDER BY avg_score DESC NULLS LAST;
$$;

GRANT EXECUTE ON FUNCTION bakery_averages() TO anon, authenticated;


-- ─── 3. Row Level Security ───────────────────────────────────────────────

ALTER TABLE bakeries ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;

-- Bakerier: alle kan lese, innloggede kan legge til
CREATE POLICY "bakeries_public_read"  ON bakeries FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "bakeries_auth_insert"  ON bakeries FOR INSERT TO authenticated        WITH CHECK (true);

-- Vurderinger: kun egne rader (rå data er aldri offentlig)
CREATE POLICY "ratings_own_select"    ON ratings FOR SELECT TO authenticated USING     (user_id = auth.uid());
CREATE POLICY "ratings_own_insert"    ON ratings FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "ratings_own_update"    ON ratings FOR UPDATE TO authenticated
  USING     (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Ønskeliste: kun egne rader
CREATE POLICY "wishlist_own_select"   ON wishlist FOR SELECT TO authenticated USING     (user_id = auth.uid());
CREATE POLICY "wishlist_own_insert"   ON wishlist FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "wishlist_own_delete"   ON wishlist FOR DELETE TO authenticated USING     (user_id = auth.uid());


-- ─── 4. Demo-data (de samme bakeriene som var i forhåndsvisningen) ───────
--
-- Slett eller tilpass etter at du har fylt inn ekte data.

INSERT INTO bakeries (name, place, type, lat, lng) VALUES
  ('Sødahlhuset',        'Åndalsnes',   'Skillingsbolle',    62.567,  7.687),
  ('Lillehammer Bakeri', 'Lillehammer', 'Kanelbolle',        61.115, 10.466),
  ('Valaker Bakeri',     'Ålesund',     'Kardemommebolle',   62.472,  6.155),
  ('Åpent Bakeri',       'Oslo',        'Skolebolle',        59.923, 10.735),
  ('Hev Ringebu',        'Ringebu',     'Hvetebolle',        61.527, 10.145),
  ('Pillarguri Café',    'Otta',        'Kanelsnurr',        61.771,  9.539);
