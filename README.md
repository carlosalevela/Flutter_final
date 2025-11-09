# skin_check_ai

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Base de datos
-- Ejecuta este SQL en SQL Editor
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios pueden ver su propio perfil
CREATE POLICY "Users can view own profile" 
ON profiles FOR SELECT 
USING (auth.uid() = id);

-- Política: Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Users can update own profile" 
ON profiles FOR UPDATE 
USING (auth.uid() = id);

-- Trigger para crear perfil automáticamente al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (new.id, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger automático
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


TABLA DE HISTORIAL 
-- Tabla para guardar el historial de análisis
CREATE TABLE skin_analyses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  diagnosis TEXT NOT NULL,
  description TEXT NOT NULL,
  risk_level TEXT NOT NULL,
  recommendations TEXT[] NOT NULL,
  requires_medical_attention BOOLEAN NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE skin_analyses ENABLE ROW LEVEL SECURITY;

-- Política: usuarios solo ven sus propios análisis
CREATE POLICY "Users can view own analyses" 
ON skin_analyses FOR SELECT 
USING (auth.uid() = user_id);

-- Política: usuarios pueden insertar sus análisis
CREATE POLICY "Users can insert own analyses" 
ON skin_analyses FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Política: usuarios pueden eliminar sus análisis
CREATE POLICY "Users can delete own analyses" 
ON skin_analyses FOR DELETE 
USING (auth.uid() = user_id);

-- Índice para mejorar performance
CREATE INDEX idx_skin_analyses_user_id ON skin_analyses(user_id);
CREATE INDEX idx_skin_analyses_created_at ON skin_analyses(created_at DESC);


CONFIGURACION DATABASE PERMISOS 

-- Política: Los usuarios autenticados pueden subir imágenes en su propia carpeta
CREATE POLICY "Users can upload own images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'skin-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Política: Cualquiera puede ver las imágenes (público)
CREATE POLICY "Public can view images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'skin-images');

-- Política: Los usuarios pueden actualizar sus propias imágenes
CREATE POLICY "Users can update own images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'skin-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'skin-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Política: Los usuarios pueden eliminar sus propias imágenes
CREATE POLICY "Users can delete own images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'skin-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);