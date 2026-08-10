import 'package:drift/drift.dart';
import 'package:lista_familia/database/tables/lists.dart';
import '../app_database.dart';

part 'list_dao.g.dart';

@DriftAccessor(tables: [ListTable])
class ListDao extends DatabaseAccessor<AppDatabase> with _$ListDaoMixin {
  ListDao(super.db);

  Stream<List<ListTableData>> watchAll() {
    return (select(listTable)
          ..orderBy([(l) => OrderingTerm.asc(l.position)]))
        .watch();
  }

  Future<List<ListTableData>> getAll() {
    return (select(listTable)
          ..orderBy([(l) => OrderingTerm.asc(l.position)]))
        .get();
  }

  Future<int> insertList(ListTableCompanion list) {
    return into(listTable).insert(list, mode: InsertMode.replace);
  }

  Future<void> updateList(ListTableCompanion list) async {
    await (update(listTable)..where((l) => l.id.equals(list.id.value))).write(list);
  }

  Future<void> deleteList(String id) async {
    await (delete(listTable)..where((l) => l.id.equals(id))).go();
  }

  Future<int> count() async {
    return select(listTable).get().then((list) => list.length);
  }

  Future<ListTableData?> getById(String id) {
    return (select(listTable)..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertFromRemote(ListTableData remote) async {
    final existing = await (select(listTable)..where((l) => l.id.equals(remote.id))).getSingleOrNull();
    if (existing == null) {
      await into(listTable).insert(
        ListTableCompanion(
          id: Value(remote.id),
          name: Value(remote.name),
          icon: Value(remote.icon),
          position: Value(remote.position),
          createdAt: Value(remote.createdAt),
        ),
      );
    } else {
      await (update(listTable)..where((l) => l.id.equals(remote.id))).write(
        ListTableCompanion(
          name: Value(remote.name),
          icon: Value(remote.icon),
          position: Value(remote.position),
        ),
      );
    }
  }

  Future<void> replaceAllFromRemote(List<ListTableData> remoteLists) async {
    await transaction(() async {
      await delete(listTable).go();
      for (final remote in remoteLists) {
        await into(listTable).insert(
          ListTableCompanion(
            id: Value(remote.id),
            name: Value(remote.name),
            icon: Value(remote.icon),
            position: Value(remote.position),
            createdAt: Value(remote.createdAt),
          ),
        );
      }
    });
  }
}
