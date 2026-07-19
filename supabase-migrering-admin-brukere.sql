-- ============================================================
-- Bollr — admin: hent antall registrerte brukere
-- Kjør i Supabase SQL Editor
-- ============================================================

CREATE OR REPLACE FUNCTION get_user_count()
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  cnt bigint;
BEGIN
  IF auth.email() != 'matsmyrholt@gmail.com' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  SELECT COUNT(*) INTO cnt FROM auth.users;
  RETURN cnt;
END;
$$;

GRANT EXECUTE ON FUNCTION get_user_count() TO authenticated;
