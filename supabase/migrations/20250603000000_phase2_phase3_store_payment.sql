-- Fase 2/3: tienda, métodos de pago, dirección de entrega

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS delivery_address TEXT;

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'card';

CREATE TABLE IF NOT EXISTS public.store_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL DEFAULT 'Huancayo',
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  phone TEXT,
  opening_hours TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "store_settings_read_all" ON public.store_settings;
CREATE POLICY "store_settings_read_all" ON public.store_settings
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "store_settings_write_owner" ON public.store_settings;
CREATE POLICY "store_settings_write_owner" ON public.store_settings
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'owner'
    )
  );

INSERT INTO public.store_settings (name, address, city, latitude, longitude, phone, opening_hours)
SELECT
  'La Casa del Volkswagen',
  'Av. Centenario, Huancayo',
  'Huancayo, Perú',
  -12.0684,
  -75.2110,
  NULL,
  'Lun–Sáb 9:00–18:00'
WHERE NOT EXISTS (SELECT 1 FROM public.store_settings LIMIT 1);
