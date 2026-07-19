-- ============================================================
-- Bollr — komplett databaseoppsett
-- Slett alt i SQL Editor og kjør denne filen
-- ============================================================

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
  score      numeric(3,2) CHECK (score >= 0 AND score <= 5),
  note       text,
  photo_url  text,
  tags       text[] DEFAULT '{}',
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

CREATE POLICY "bakeries_read"   ON bakeries FOR SELECT USING (true);
CREATE POLICY "bakeries_insert" ON bakeries FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "ratings_read"   ON ratings FOR SELECT  TO authenticated USING (user_id = auth.uid());
CREATE POLICY "ratings_insert" ON ratings FOR INSERT  TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "ratings_update" ON ratings FOR UPDATE  TO authenticated USING (user_id = auth.uid());
CREATE POLICY "ratings_delete" ON ratings FOR DELETE  TO authenticated USING (user_id = auth.uid());

CREATE POLICY "wishlist_read"   ON wishlist FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "wishlist_insert" ON wishlist FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "wishlist_delete" ON wishlist FOR DELETE TO authenticated USING (user_id = auth.uid());

-- ── Aggregatfunksjon ───────────────────────────────────────

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

-- ── Storage-policyer (bucket må opprettes manuelt i dashbordet) ──

INSERT INTO storage.buckets (id, name, public)
VALUES ('bolle-bilder', 'bolle-bilder', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "storage_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'bolle-bilder');

CREATE POLICY "storage_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'bolle-bilder');

CREATE POLICY "storage_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'bolle-bilder' AND auth.uid()::text = (storage.foldername(name))[1]);
