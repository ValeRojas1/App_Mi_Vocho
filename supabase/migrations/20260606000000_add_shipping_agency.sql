ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS shipping_agency TEXT;

UPDATE public.store_settings
SET
  address = 'Av. Huancavelica 676, El Tambo, Huancayo',
  city = 'Huancayo, Perú',
  opening_hours = '9:30 am a 6:30 pm',
  updated_at = NOW();

CREATE TABLE IF NOT EXISTS public.promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  position INTEGER NOT NULL UNIQUE CHECK (position BETWEEN 0 AND 2),
  title TEXT NOT NULL DEFAULT 'Oferta',
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "promotions_read_all" ON public.promotions;
CREATE POLICY "promotions_read_all" ON public.promotions
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "promotions_write_owner" ON public.promotions;
CREATE POLICY "promotions_write_owner" ON public.promotions
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'owner'
    )
  );

INSERT INTO public.promotions (position, title)
VALUES
  (0, 'Oferta 1'),
  (1, 'Oferta 2'),
  (2, 'Oferta 3')
ON CONFLICT (position) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('promotion-images', 'promotion-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "promotion_images_read_all" ON storage.objects;
CREATE POLICY "promotion_images_read_all" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'promotion-images');

DROP POLICY IF EXISTS "promotion_images_write_owner" ON storage.objects;
CREATE POLICY "promotion_images_write_owner" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'promotion-images'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'owner'
    )
  );
