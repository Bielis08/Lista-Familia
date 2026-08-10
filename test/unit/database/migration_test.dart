import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

const _v1ProductsTable = '''
  CREATE TABLE products (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    is_checked INTEGER NOT NULL DEFAULT 0 CHECK ("is_checked" IN (0, 1)),
    is_important INTEGER NOT NULL DEFAULT 0 CHECK ("is_important" IN (0, 1)),
    quantity INTEGER NOT NULL DEFAULT 1,
    created_by TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    position INTEGER NOT NULL DEFAULT 0,
    dirty INTEGER NOT NULL DEFAULT 0 CHECK ("dirty" IN (0, 1)),
    deleted INTEGER NOT NULL DEFAULT 0 CHECK ("deleted" IN (0, 1)),
    last_modified INTEGER NOT NULL,
    synced_at INTEGER,
    user_id TEXT NOT NULL
  )
''';

const _v2ListsTable = '''
  CREATE TABLE lists (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT '',
    position INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL
  )
''';

const _v3ListsTable = '''
  CREATE TABLE lists (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT '',
    position INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    dirty INTEGER NOT NULL DEFAULT 0 CHECK ("dirty" IN (0, 1)),
    deleted INTEGER NOT NULL DEFAULT 0 CHECK ("deleted" IN (0, 1)),
    last_modified INTEGER NOT NULL,
    synced_at INTEGER,
    user_id TEXT NOT NULL DEFAULT 'local_user'
  )
''';

Future<AppDatabase> _openMigratedDatabase(sqlite3.Database sqlite, String path) async {
  sqlite.dispose();
  return AppDatabase.forTesting(NativeDatabase.createInBackground(File(path)));
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('drift_migration_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('migrates v1 -> v3 preserving existing products', () async {
    final path = '${tempDir.path}/v1.sqlite';
    final sqlite = sqlite3.sqlite3.open(path);
    sqlite.execute(_v1ProductsTable);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    sqlite.execute(
      'INSERT INTO products (id, name, created_by, created_at, last_modified, user_id) '
      'VALUES (\'p1\', \'Leche\', \'user\', $now, $now, \'local_user\')',
    );
    sqlite.execute('PRAGMA user_version = 1');

    final db = await _openMigratedDatabase(sqlite, path);

    final products = await db.productDao.getAll();
    expect(products.length, 1);
    expect(products.first.name, 'Leche');

    final lists = await db.listDao.getAll();
    expect(lists, isEmpty);

    final listCount = await db.listDao.count();
    expect(listCount, 0);

    await db.close();
  });

  test('migrates v2 -> v3 preserving existing lists', () async {
    final path = '${tempDir.path}/v2.sqlite';
    final sqlite = sqlite3.sqlite3.open(path);
    sqlite.execute(_v1ProductsTable);
    sqlite.execute("ALTER TABLE products ADD COLUMN list_id TEXT NOT NULL DEFAULT 'supermercado'");
    sqlite.execute(_v2ListsTable);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    sqlite.execute(
      "INSERT INTO lists (id, name, created_at) VALUES ('l1', 'Compras', $now)",
    );
    sqlite.execute('PRAGMA user_version = 2');

    final db = await _openMigratedDatabase(sqlite, path);

    final lists = await db.listDao.getAll();
    expect(lists.length, 1);
    expect(lists.first.name, 'Compras');

    await db.close();
  });

  test('recovers database left partially migrated by previous buggy version', () async {
    final path = '${tempDir.path}/poisoned.sqlite';
    final sqlite = sqlite3.sqlite3.open(path);
    sqlite.execute(_v1ProductsTable);
    sqlite.execute("ALTER TABLE products ADD COLUMN list_id TEXT NOT NULL DEFAULT 'supermercado'");
    sqlite.execute(_v3ListsTable);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    sqlite.execute(
      "INSERT INTO lists (id, name, created_at, last_modified) VALUES ('l1', 'Compras', $now, $now)",
    );
    sqlite.execute('PRAGMA user_version = 1');

    final db = await _openMigratedDatabase(sqlite, path);

    final lists = await db.listDao.getAll();
    expect(lists.length, 1);
    expect(lists.first.name, 'Compras');

    final products = await db.productDao.getAll();
    expect(products, isEmpty);

    await db.close();
  });

  test('fresh database creates all tables', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final lists = await db.listDao.getAll();
    expect(lists, isEmpty);
    await db.close();
  });

  test('migrates v3 -> v4 recreating tables with primary key and deduplicating', () async {
    final path = '${tempDir.path}/v3.sqlite';
    final sqlite = sqlite3.sqlite3.open(path);
    sqlite.execute('''
      CREATE TABLE products (
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0,
        is_important INTEGER NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 1,
        created_by TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        list_id TEXT NOT NULL DEFAULT 'supermercado',
        dirty INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0,
        last_modified INTEGER NOT NULL,
        synced_at INTEGER,
        user_id TEXT NOT NULL
      )
    ''');
    sqlite.execute('''
      CREATE TABLE lists (
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT '',
        position INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0,
        last_modified INTEGER NOT NULL,
        synced_at INTEGER,
        user_id TEXT NOT NULL DEFAULT 'local_user'
      )
    ''');
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    sqlite.execute(
      'INSERT INTO products (id, name, created_by, created_at, last_modified, user_id) '
      "VALUES ('p1', 'Leche', 'user', $now, $now, 'local_user')",
    );
    sqlite.execute(
      'INSERT INTO products (id, name, created_by, created_at, last_modified, user_id) '
      "VALUES ('p1', 'Leche', 'user', $now, $now, 'local_user')",
    );
    sqlite.execute(
      'INSERT INTO products (id, name, created_by, created_at, last_modified, user_id) '
      "VALUES ('p1', 'Leche', 'user', $now, $now, 'local_user')",
    );
    sqlite.execute('PRAGMA user_version = 3');

    final db = await _openMigratedDatabase(sqlite, path);

    final products = await db.productDao.getAll();
    expect(products.length, 1);
    expect(products.first.name, 'Leche');

    await db.productDao.insertProduct(ProductTableCompanion(
      id: const Value('p1'),
      name: const Value('Pan'),
      isChecked: const Value(false),
      isImportant: const Value(false),
      quantity: const Value(1),
      createdBy: const Value('user'),
      createdAt: Value(DateTime.fromMillisecondsSinceEpoch(now * 1000)),
      position: const Value(0),
      listId: const Value('supermercado'),
      dirty: const Value(false),
      deleted: const Value(false),
      lastModified: Value(DateTime.fromMillisecondsSinceEpoch(now * 1000)),
      syncedAt: const Value(null),
      userId: const Value('user'),
    ));

    final afterReplace = await db.productDao.getAll();
    expect(afterReplace.length, 1);
    expect(afterReplace.first.name, 'Pan');

    await db.close();
  });
}
