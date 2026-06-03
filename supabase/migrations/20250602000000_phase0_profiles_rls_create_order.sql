-- Fase 0: adaptada si profiles ya existe (Mi_Vocho en producción).
-- En proyecto nuevo: ejecutar completo. En existente: ver migración aplicada vía MCP.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

UPDATE public.profiles SET role = 'client' WHERE role IS NULL;

INSERT INTO public.profiles (id, full_name, role)
SELECT
  u.id,
  COALESCE(u.raw_user_meta_data->>'full_name', ''),
  CASE WHEN u.email = 'duena@lavolkswagen.com' THEN 'owner' ELSE 'client' END
FROM auth.users u
ON CONFLICT (id) DO UPDATE SET
  role = CASE
    WHEN EXCLUDED.role = 'owner' OR public.profiles.role = 'owner' THEN 'owner'
    ELSE COALESCE(public.profiles.role, 'client')
  END,
  full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
  updated_at = NOW();

UPDATE public.profiles p
SET role = 'owner', updated_at = NOW()
FROM auth.users u
WHERE p.id = u.id AND u.email = 'duena@lavolkswagen.com';

ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'client';

DO $$
BEGIN
  ALTER TABLE public.profiles ALTER COLUMN role SET NOT NULL;
EXCEPTION WHEN others THEN NULL;
END $$;

DO $$
BEGIN
  ALTER TABLE public.profiles
    ADD CONSTRAINT profiles_role_check CHECK (role IN ('client', 'owner'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Ver supabase remoto para políticas, trigger y create_order_with_stock (aplicado vía MCP).
