import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:lista_familia/constants.dart';
import 'tables/products.dart';
import 'tables/lists.dart';
import 'daos/product_dao.dart';
import 'daos/list_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [ProductTable, ListTable], daos: [ProductDao, ListDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      await m.database.transaction(() async {
        if (from < 2) {
          if (!await _columnExists(m, 'products', 'list_id')) {
            await m.addColumn(productTable, productTable.listId);
          }
          if (!await _tableExists(m, 'lists')) {
            await m.database.customStatement('''
              CREATE TABLE lists (
                id TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT NOT NULL DEFAULT '',
                position INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL
              )
            ''');
          }
        }
        if (from < 3) {
          if (!await _columnExists(m, 'lists', 'dirty')) {
            await m.addColumn(listTable, listTable.dirty);
          }
          if (!await _columnExists(m, 'lists', 'deleted')) {
            await m.addColumn(listTable, listTable.deleted);
          }
          if (!await _columnExists(m, 'lists', 'last_modified')) {
            await m.database.customStatement(
              'ALTER TABLE lists ADD COLUMN last_modified INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (!await _columnExists(m, 'lists', 'synced_at')) {
            await m.addColumn(listTable, listTable.syncedAt);
          }
          if (!await _columnExists(m, 'lists', 'user_id')) {
            await m.addColumn(listTable, listTable.userId);
          }
        }
        if (from < 4) {
          await _recreateWithPrimaryKey(m);
        }
        if (from < 5) {
          if (!await _columnExists(m, 'products', 'price')) {
            await m.database.customStatement(
              'ALTER TABLE products ADD COLUMN price REAL NOT NULL DEFAULT 0.0',
            );
          }
        }
      });
    },
  );
}

Future<void> _recreateWithPrimaryKey(Migrator m) async {
  await m.database.customStatement('DELETE FROM products WHERE rowid NOT IN (SELECT MAX(rowid) FROM products GROUP BY id)');
  await m.database.customStatement('DROP TABLE IF EXISTS products_new');
  await m.database.customStatement('''
    CREATE TABLE products_new (
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
      user_id TEXT NOT NULL,
      PRIMARY KEY (id)
    )
  ''');
  await m.database.customStatement('''
    INSERT INTO products_new (id, name, is_checked, is_important, quantity, created_by, created_at, position, list_id, dirty, deleted, last_modified, synced_at, user_id)
    SELECT id, name, is_checked, is_important, quantity, created_by, created_at, position, list_id, dirty, deleted, last_modified, synced_at, user_id
    FROM products
  ''');
  await m.database.customStatement('DROP TABLE products');
  await m.database.customStatement('ALTER TABLE products_new RENAME TO products');

  await m.database.customStatement('DELETE FROM lists WHERE rowid NOT IN (SELECT MAX(rowid) FROM lists GROUP BY id)');
  await m.database.customStatement('DROP TABLE IF EXISTS lists_new');
  await m.database.customStatement('''
    CREATE TABLE lists_new (
      id TEXT NOT NULL,
      name TEXT NOT NULL,
      icon TEXT NOT NULL DEFAULT '',
      position INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      dirty INTEGER NOT NULL DEFAULT 0,
      deleted INTEGER NOT NULL DEFAULT 0,
      last_modified INTEGER NOT NULL,
      synced_at INTEGER,
      user_id TEXT NOT NULL DEFAULT 'local_user',
      PRIMARY KEY (id)
    )
  ''');
  await m.database.customStatement('''
    INSERT INTO lists_new (id, name, icon, position, created_at, dirty, deleted, last_modified, synced_at, user_id)
    SELECT id, name, icon, position, created_at, dirty, deleted, last_modified, synced_at, user_id
    FROM lists
  ''');
  await m.database.customStatement('DROP TABLE lists');
  await m.database.customStatement('ALTER TABLE lists_new RENAME TO lists');
}

Future<bool> _tableExists(Migrator m, String table) async {
  final rows = await m.database.customSelect(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    variables: [Variable(table)],
  ).get();
  return rows.isNotEmpty;
}

Future<bool> _columnExists(Migrator m, String table, String column) async {
  final rows = await m.database.customSelect('PRAGMA table_info($table)').get();
  return rows.any((QueryRow row) => row.data['name'] == column);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, dbName));
    return NativeDatabase.createInBackground(file);
  });
}
