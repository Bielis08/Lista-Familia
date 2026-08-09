# Lista Familia

Lista de la compra para la familia Montero Román. Funciona offline en el supermercado y sincroniza en tiempo real cuando hay conexión.

## Features

- **Offline-first**: Funciona sin internet, los cambios se guardan localmente
- **Sync en tiempo real**: Cambios aparecen al instante en otros dispositivos vía Supabase Realtime
- **Indicadores visuales**: Barra de estado muestra: conectado, sincronizando, pendiente, offline
- Añadir/editar/eliminar productos
- Marcar como comprados
- Control de cantidades
- Reordenar productos (arrastrar)
- Modo vista (solo lectura) / modo edición

## Arquitectura

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

See [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for full SQL and configuration.

**Quick SQL:**
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

ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all" ON products FOR ALL USING (true) WITH CHECK (true);
```

## License

MIT License - See [LICENSE](LICENSE)

## Author

**Biel Montero Román** — [bielmonteroroman08@gmail.com](mailto:bielmonteroroman08@gmail.com)
