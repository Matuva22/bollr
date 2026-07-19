-- ============================================================
-- Bollr — admin-funksjoner for godkjenning av vurderinger
-- Kjør i Supabase SQL Editor
-- ============================================================

-- Hent alle vurderinger som venter på godkjenning (kun admin)
CREATE OR REPLACE FUNCTION get_pending_ratings()
RETURNS TABLE (
  id           uuid,
  bakery_id    uuid,
  bakery_name  text,
  bakery_type  text,
  bakery_place text,
  score        numeric,
  note         text,
  photo_url    text,
  created_at   timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.email() != 'matsmyrholt@gmail.com' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  RETURN QUERY
    SELECT r.id, r.bakery_id, b.name, b.type, b.place,
           r.score, r.note, r.photo_url, r.created_at
    FROM ratings r
    JOIN bakeries b ON b.id = r.bakery_id
    WHERE r.approved = false
    ORDER BY r.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_pending_ratings() TO authenticated;

-- Godkjenn én vurdering (kun admin)
CREATE OR REPLACE FUNCTION approve_rating(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.email() != 'matsmyrholt@gmail.com' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  UPDATE ratings SET approved = true WHERE id = p_id;
END;
$$;

GRANT EXECUTE ON FUNCTION approve_rating(uuid) TO authenticated;
