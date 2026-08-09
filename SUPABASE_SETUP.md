# Configuración de Supabase para Lista Familiar

## 1. Crear proyecto

1. Ve a [https://supabase.com](https://supabase.com)
2. Crea una cuenta gratis (GitHub)
3. Crea un nuevo proyecto

## 2. Obtener claves

En **Settings → API**:
- **Project URL** → `https://xxxxx.supabase.co`
- **anon/public** → clave que empieza con `eyJ...`

## 3. Configurar en la app

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_KEY=YOUR_KEY
```

Para release:
```bash
flutter build apk --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_KEY=YOUR_KEY
```

## 4. Crear tabla `products`

Ve a **Database → SQL Editor** y ejecuta:

```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  is_checked BOOLEAN DEFAULT FALSE,
  is_important BOOLEAN DEFAULT FALSE,
  quantity INTEGER DEFAULT 1,
  created_by TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  position INTEGER DEFAULT 0
);

-- Habilitar Realtime (sincronización en tiempo real)
ALTER PUBLICATION supabase_realtime ADD TABLE products;

-- RLS (permisos para la familia)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all for family" ON products
  FOR ALL
  USING (true)
  WITH CHECK (true);
```

## 5. Habilitar Realtime

Si no ejecutaste el SQL anterior, habilita manualmente:
1. **Database → Replication**
2. Añade la tabla `products` a la publicación

## 6. Verificar

1. Abre la app en 2 dispositivos
2. Añade un producto en uno → debe aparecer al instante en el otro
3. Pon uno en modo avión → debe seguir funcionando localmente
4. Quita modo avión → se sincroniza automáticamente

## Troubleshooting

### Productos no aparecen en otros dispositivos
- Verifica que Realtime esté habilitado en **Database → Replication**
- Comprueba que la tabla `products` esté en la publicación

### Error al insertar
- Verifica que RLS esté habilitado con políticas para `anon`
- La columna `id` debe ser `text` (no `uuid`)

### Duplicados en la app
- Borra los datos de la app (**Ajustes → Apps → Lista Familia → Borrar datos**)
- Vuelve a abrir la app

## Límites Free Tier

- 500 MB DB, 50K usuarios/mes, 1 GB storage
- Más que suficiente para 4 usuarios
