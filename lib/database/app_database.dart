import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(productTable, productTable.listId);
        await m.createTable(listTable);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'lista_familia.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
