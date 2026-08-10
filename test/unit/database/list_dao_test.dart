import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertList({
    required String id,
    bool dirty = false,
    bool deleted = false,
  }) async {
    await db.listDao.insertList(ListTableCompanion(
      id: Value(id),
      name: Value(id),
      createdAt: Value(DateTime.now()),
      dirty: Value(dirty),
      deleted: Value(deleted),
      lastModified: Value(DateTime.now()),
      userId: const Value('local_user'),
    ));
  }

  group('count', () {
    test('counts only non-deleted lists', () async {
      await insertList(id: 'a');
      await insertList(id: 'b');
      await insertList(id: 'c', deleted: true);

      expect(await db.listDao.count(), 2);
    });

    test('returns zero when empty', () async {
      expect(await db.listDao.count(), 0);
    });
  });

  group('getDeleted', () {
    test('returns deleted lists including synced ones', () async {
      await insertList(id: 'activa');
      await insertList(id: 'borrada_synced', deleted: true, dirty: false);
      await insertList(id: 'borrada_dirty', deleted: true, dirty: true);

      final deleted = await db.listDao.getDeleted();

      expect(deleted.length, 2);
      expect(deleted.map((l) => l.id).toSet(), {'borrada_synced', 'borrada_dirty'});
    });
  });
}
