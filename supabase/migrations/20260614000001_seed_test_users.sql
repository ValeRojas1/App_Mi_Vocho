-- Usuarios de prueba para desarrollo y pruebas web.
-- Contraseña común: MiVocho2026!
-- Solo ejecutar en entornos de desarrollo/staging.

CREATE OR REPLACE FUNCTION public.seed_test_user(
  p_email text,
  p_password text,
  p_full_name text,
  p_role text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  existing_id uuid;
  new_user_id uuid;
BEGIN
  IF p_role NOT IN ('client', 'owner', 'admin') THEN
    RAISE EXCEPTION 'Rol inválido';
  END IF;

  SELECT id INTO existing_id FROM auth.users WHERE email = lower(trim(p_email));

  IF existing_id IS NOT NULL THEN
    UPDATE public.profiles
    SET full_name = NULLIF(trim(p_full_name), ''), role = p_role, updated_at = NOW()
    WHERE id = existing_id;

    UPDATE auth.users
    SET
      encrypted_password = crypt(p_password, gen_salt('bf')),
      email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
      updated_at = NOW()
    WHERE id = existing_id;

    RETURN existing_id;
  END IF;

  new_user_id := gen_random_uuid();

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token,
    email_change_token_new, email_change
  ) VALUES (
    '00000000-0000-0000-0000-000000000000', new_user_id, 'authenticated', 'authenticated',
    lower(trim(p_email)), crypt(p_password, gen_salt('bf')), NOW(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', p_full_name), NOW(), NOW(), '', '', '', ''
  );

  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  ) VALUES (
    gen_random_uuid(), new_user_id,
    jsonb_build_object('sub', new_user_id::text, 'email', lower(trim(p_email))),
    'email', new_user_id::text, NOW(), NOW(), NOW()
  );

  INSERT INTO public.profiles (id, full_name, role, updated_at)
  VALUES (new_user_id, NULLIF(trim(p_full_name), ''), p_role, NOW())
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    updated_at = NOW();

  RETURN new_user_id;
END;
$$;

SELECT public.seed_test_user('admin@mi-vocho.test', 'MiVocho2026!', 'Admin Prueba', 'admin');
SELECT public.seed_test_user('cliente@mi-vocho.test', 'MiVocho2026!', 'Cliente Prueba', 'client');
SELECT public.seed_test_user('duena@mi-vocho.test', 'MiVocho2026!', 'Dueña Prueba', 'owner');
SELECT public.seed_test_user('cliente1@test.com', 'MiVocho2026!', 'Cliente Uno', 'client');

DROP FUNCTION IF EXISTS public.seed_test_user(text, text, text, text);
