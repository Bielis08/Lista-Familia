# Lista Familia

Lista de la compra para la familia Montero Román. Funciona offline en el supermercado y sincroniza en tiempo real cuando hay conexión.

## Features

- **Offline-first**: Funciona sin internet, los cambios se guardan localmente
- **Sync en tiempo real**: Cambios aparecen al instante en otros dispositivos vía Supabase Realtime
- **Indicadores visuales**: Barra de estado muestra: conectado, sincronizando, pendiente, offline
- **Múltiples listas**: Supermercado, Fruta y Verdura, o crea las tuyas propias
- Añadir/editar/eliminar productos
- Marcar como comprados
- Control de cantidades
- Reordenar productos (arrastrar)
- Modo vista (solo lectura) / modo edición

## Architecture

```
UI (Flutter) → ProductRepository → Local DB (Drift/SQLite) ←→ Supabase (REST + Realtime)
                                         ↑
                                    SyncService
                              (push dirty + pull realtime)
```

- **Local-first**: Todo se escribe en SQLite primero (UI instantánea)
- **Push**: Productos `dirty=true` se suben a Supabase (1 llamada REST por producto)
- **Pull**: Supabase Realtime escucha cambios → upsert a SQLite
- **Fallback**: Sync periódico cada 30s si Realtime falla

## Getting Started

### Prerequisites
- Flutter SDK (3.x+)
- Supabase account (free tier)

### Installation

```bash
git clone https://github.com/Bielis08/Lista-Familia.git
cd Lista-Familia
flutter pub get
```

### Run

```bash
flutter run
```

### Build APK

```bash
flutter build apk --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_KEY=YOUR_KEY
```

## Supabase Setup

See `supabase/migrations/002_add_lists.sql` for the full SQL migration.

**Quick SQL:**
```sql
-- Lists table
CREATE TABLE lists (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT DEFAULT '',
  position INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER PUBLICATION supabase_realtime ADD TABLE lists;
ALTER TABLE lists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON lists FOR ALL USING (true) WITH CHECK (true);

-- Add list_id to products
ALTER TABLE products ADD COLUMN list_id TEXT NOT NULL DEFAULT 'supermercado';

-- Default lists
INSERT INTO lists (id, name, icon, position) VALUES
  ('supermercado', 'Supermercado', '🛒', 0),
  ('fruta-verdura', 'Fruta y Verdura', '🥬', 1);
```

## License

MIT License - See [LICENSE](LICENSE)

## Author

**Biel Montero Román** — [bielmonteroroman08@gmail.com](mailto:bielmonteroroman08@gmail.com)
