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
├── constants.dart              # App-wide constants (colors, spacing, defaults)
├── theme.dart                  # Centralized theme definition
├── database/
│   ├── app_database.dart       # DB connection & migrations (schema v3)
│   ├── tables/
│   │   ├── products.dart       # ProductTable schema with sync metadata + explicit PK
│   │   └── lists.dart          # ListTable schema with dirty tracking + explicit PK
│   └── daos/
│       ├── product_dao.dart    # CRUD + sync queries with batch operations
│       └── list_dao.dart       # List CRUD + sync queries with dirty tracking
├── models/
│   ├── product.dart            # Immutable Product with copyWith()
│   └── list_model.dart         # Immutable ListModel with copyWith()
├── repositories/
│   ├── product_repository.dart           # Abstract interface
│   ├── local_product_repository.dart     # Drift implementation (source of truth for UI)
│   ├── remote_product_repository.dart    # Supabase REST wrapper
│   └── product_repository_impl.dart      # Orchestrates local + sync
├── services/
│   ├── supabase_service.dart    # Supabase client init + REST queries
│   ├── sync_service.dart        # Realtime listener + periodic push/pull (products + lists)
│   └── update_service.dart      # APK update checker (UI extracted to widget)
├── screens/
│   ├── list_selector_screen.dart  # List selection / management UI
│   └── home_screen.dart           # Product list UI (scoped by listId)
└── widgets/
    ├── product_item.dart        # Product list item with swipe-to-delete
    ├── empty_state.dart         # Shared empty state widget
    ├── sync_status_bar.dart     # Sync status indicator
    ├── update_dialog.dart       # Update dialog widget
    ├── name_icon_dialog.dart    # Name+icon dialog owning its controllers
    └── name_quantity_dialog.dart # Name+quantity dialog owning its controllers
```

## Key Files for Changes
- `lib/constants.dart` - All constants, colors, spacing, decorations
- `lib/database/tables/products.dart` - Add columns here, then run `dart run build_runner build`
- `lib/database/tables/lists.dart` - List table schema with sync metadata
- `lib/database/daos/product_dao.dart` - Product queries with batch operations
- `lib/database/daos/list_dao.dart` - List queries with dirty tracking
- `lib/services/supabase_service.dart` - Supabase REST operations
- `lib/services/sync_service.dart` - Sync logic for both products and lists
- `lib/screens/list_selector_screen.dart` - List management UI
- `lib/screens/home_screen.dart` - Main product list UI

## Commands
```bash
flutter pub get                    # Install deps
dart run build_runner build        # Regenerate Drift code after schema changes
flutter analyze                    # Check for errors
flutter test                       # Run all tests
flutter run -d <device_id>        # Run on specific device
flutter build apk --dart-define=SUPABASE_URL=URL --dart-define=SUPABASE_KEY=KEY  # Build release APK
```

## Supabase Config
- URL: `https://gjkmrlaiipzabpuvwfyr.supabase.co`
- Tables:
  - `products` (id TEXT PK, name, is_checked, is_important, quantity, created_by, created_at, position, list_id, dirty, deleted, last_modified, synced_at, user_id)
  - `lists` (id TEXT PK, name, icon, position, created_at, dirty, deleted, last_modified, synced_at, user_id)
- Realtime: enabled on both `products` and `lists` tables
- RLS: open policies for anon role (family use)

## Key Patterns
- **Immutable Models**: All models use `copyWith()` - never mutate directly
- **Optimistic UI**: Mutate local state, then sync. Rollback on failure with proper `mounted` checks
- **Batch Operations**: `batchSoftDelete`, `batchUpdateProductFields`, `upsertBatch` for bulk operations
- **Dirty Tracking**: Both products AND lists have dirty/deleted/sync metadata
- **Cascade Delete**: Deleting a list soft-deletes all its products
- **Shared Widgets**: `EmptyState`, `SyncStatusBar`, `UpdateDialog` reused across screens
- **Centralized Constants**: All colors, spacing, radius in `constants.dart`

## Maintenance Rules

### When adding new functionality:
1. **Update AGENTS.md** - Add new files to Architecture section
2. **Update Supabase schema** - If new columns/tables needed
3. **Update constants.dart** - Add new colors/spacing/constants
4. **Add tests** - Write unit tests for new logic
5. **Run `dart run build_runner build`** - After any schema changes in Drift tables

### When modifying database schema:
1. Update `lib/database/tables/` file
2. Run `dart run build_runner build`
3. Update `app_database.dart` migration (increment schemaVersion)
4. Update Supabase table structure via dashboard
5. Update relevant DAO with new queries
6. Update sync logic in `sync_service.dart` if needed

### When adding new screens/widgets:
1. Add to `lib/screens/` or `lib/widgets/`
2. Update navigation in appropriate screen
3. Reuse `EmptyState`, `SyncStatusBar` patterns
4. Use `AppColors`, `AppSpacing`, `AppRadius` from constants
