# Changelog

## [0.6.0] - 2026-08-04

### Changed
- `applicationId` changed from `com.example.lista_familia` to `com.bielmontero.lista_familia`
- Credentials moved from hardcoded to `--dart-define` environment variables
- Replaced unused `uuid` dependency with `connectivity_plus`

### Added
- Pull-to-refresh in view mode
- Offline connectivity indicator banner
- Connectivity restoration toast notification
- Release signing configuration (key.properties template)
- ProGuard rules for release builds
- Minification and resource shrinking for release APK
- Unit tests for Product model
- Stricter lint rules (prefer_const, avoid_print, require_trailing_commas, etc.)
- SQL migration for `is_important` column in Supabase setup docs

### Fixed
- Added missing `is_important` column to Supabase table documentation

## [0.5.0] - Previous version

### Added
- Real-time sync with Supabase
- Product list with checkbox, quantity controls, and importance star
- Edit mode with drag-to-reorder
- View/Edit mode toggle
- Delete individual, checked, or all products
- Optimistic updates with rollback on error
