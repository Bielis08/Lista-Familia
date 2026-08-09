# AGENTS.md - Lista Familia

## Project Overview
Flutter shopping list app for the Montero Román family (4 users). Offline-first architecture with Supabase backend for real-time sync. Supports multiple shopping lists.

## Tech Stack
- **Framework**: Flutter 3.x + Dart
- **Local DB**: Drift (SQLite) for offline storage
- **Backend**: Supabase (PostgreSQL + Realtime)
- **Connectivity**: connectivity_plus

## Architecture
```
lib/
├── database/          # Drift SQLite layer
│   ├── app_database.dart       # DB connection & migrations (schema v2)
│   ├── tables/
│   │   ├── products.dart       # ProductTable schema with listId + sync metadata
│   │   └── lists.dart          # ListTable schema (id, name, icon, position)
│   └── daos/
│       ├── product_dao.dart    # CRUD + sync queries (list-scoped)
│       └── list_dao.dart       # List CRUD + sync queries
├── models/
│   ├── product.dart            # Product data class (id, name, isChecked, isImportant, quantity, createdBy, createdAt, position, listId)
│   └── list_model.dart         # ListModel data class (id, name, icon, position, createdAt)
├── repositories/
│   ├── product_repository.dart           # Abstract interface (product + list methods)
│   ├── local_product_repository.dart     # Drift implementation (source of truth for UI)
│   ├── remote_product_repository.dart    # Supabase REST wrapper
│   └── product_repository_impl.dart      # Orchestrates local + sync
├── services/
│   ├── supabase_service.dart    # Supabase client init + REST queries (products + lists)
│   ├── sync_service.dart        # Realtime listener + periodic push/pull (both tables)
│   └── update_service.dart      # APK update checker
├── screens/
│   ├── list_selector_screen.dart  # List selection / management UI
│   └── home_screen.dart           # Product list UI (scoped by listId)
└── widgets/
    └── product_item.dart        # Product list item widget
```

## Sync Strategy
- **Local-first**: All reads/writes go to SQLite first (instant UI)
- **Push**: Dirty records → Supabase REST API (single updateAll call per product)
- **Pull**: Supabase Realtime stream → upsert to local DB (products + lists)
- **Fallback**: Periodic sync every 30s if Realtime fails
- **Conflict resolution**: Last-write-wins (server timestamp)
- **Soft delete**: Products marked `deleted=true, dirty=true` then hard-deleted after push

## Key Files for Changes
- `lib/database/tables/products.dart` - Add columns here, then run `dart run build_runner build`
- `lib/database/tables/lists.dart` - List table schema
- `lib/database/daos/product_dao.dart` - Product queries (list-scoped)
- `lib/database/daos/list_dao.dart` - List CRUD queries
- `lib/services/supabase_service.dart` - Supabase REST operations (products + lists)
- `lib/services/sync_service.dart` - Sync logic (realtime + push/pull for both tables)
- `lib/screens/list_selector_screen.dart` - List management UI
- `lib/screens/home_screen.dart` - Main product list UI

## Commands
```bash
flutter pub get                    # Install deps
dart run build_runner build        # Regenerate Drift code after schema changes
flutter analyze                    # Check for errors
flutter run -d <device_id>        # Run on specific device
flutter build apk --dart-define=SUPABASE_URL=URL --dart-define=SUPABASE_KEY=KEY  # Build release APK
```

## Supabase Config
- URL: `https://gjkmrlaiipzabpuvwfyr.supabase.co`
- Tables:
  - `products` (id TEXT PK, name, is_checked, is_important, quantity, created_by, created_at, position, list_id)
  - `lists` (id TEXT PK, name, icon, position, created_at)
- Realtime: enabled on both `products` and `lists` tables
- RLS: open policies for anon role (family use)
- Migration: `supabase/migrations/002_add_lists.sql`

## Gotchas
- After modifying `ProductTable` or `ListTable` in `tables/`, MUST run `dart run build_runner build`
- Drift generates `*.g.dart` files - never edit manually
- Sync service uses Supabase Realtime `.stream(primaryKey: ['id'])` for BOTH tables
- `replaceAllFromRemote()` in a transaction: deletes non-dirty local records, inserts new remote ones (preserves local dirty state)
- Position is scoped per list (products use `countByList` for auto-positioning)
- Initial migration in `main.dart` syncs ALL products (unfiltered) and ALL lists from Supabase

## Maintenance Rules

### When adding new functionality:
1. **Update AGENTS.md** - Add new files to Architecture section, update Key Files for Changes if needed
2. **Update README.md** - Add feature description, usage instructions, or screenshots if user-facing
3. **Update Supabase schema** - If new columns/tables are needed, migrate Supabase first, then update Drift schema
4. **Add tests** - Write unit tests for new logic, widget tests for new UI components
5. **Run `dart run build_runner build`** - After any schema changes in Drift tables

### When modifying database schema:
1. Update `lib/database/tables/products.dart` (or new table file)
2. Run `dart run build_runner build`
3. Update Supabase table structure via dashboard
4. Update `lib/database/daos/product_dao.dart` with new queries
5. Update sync logic in `lib/services/sync_service.dart` if needed

### When adding new screens/widgets:
1. Add to `lib/screens/` or `lib/widgets/`
2. Update navigation in `lib/main.dart` if new route
3. Add widget tests in `test/widget/`
4. Update README.md with feature description
