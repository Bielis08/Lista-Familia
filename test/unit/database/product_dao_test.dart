import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProductTableCompanion createTestCompanion({
    String id = 'test_1',
    String name = 'Test Product',
    bool isChecked = false,
    bool isImportant = false,
    int quantity = 1,
    String createdBy = 'test_user',
    DateTime? createdAt,
    int position = 0,
    bool dirty = false,
    bool deleted = false,
    DateTime? lastModified,
    String userId = 'test_user',
  }) {
    final now = DateTime.now();
    return ProductTableCompanion(
      id: Value(id),
      name: Value(name),
      isChecked: Value(isChecked),
      isImportant: Value(isImportant),
      quantity: Value(quantity),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt ?? now),
      position: Value(position),
      dirty: Value(dirty),
      deleted: Value(deleted),
      lastModified: Value(lastModified ?? now),
      userId: Value(userId),
    );
  }

  group('insertProduct', () {
    test('inserts and retrieves a product', () async {
      final companion = createTestCompanion(id: '1', name: 'Leche');
      await db.productDao.insertProduct(companion);

      final products = await db.productDao.getAll();
      expect(products.length, 1);
      expect(products.first.id, '1');
      expect(products.first.name, 'Leche');
    });

    test('inserts multiple products', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', name: 'A'));
      await db.productDao.insertProduct(createTestCompanion(id: '2', name: 'B'));
      await db.productDao.insertProduct(createTestCompanion(id: '3', name: 'C'));

      final products = await db.productDao.getAll();
      expect(products.length, 3);
    });
  });

  group('getAll', () {
    test('returns only non-deleted products', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', name: 'Active'));
      await db.productDao.insertProduct(createTestCompanion(id: '2', name: 'Deleted', deleted: true));

      final products = await db.productDao.getAll();
      expect(products.length, 1);
      expect(products.first.name, 'Active');
    });

    test('orders by position ascending then createdAt descending', () async {
      final now = DateTime.now();
      await db.productDao.insertProduct(createTestCompanion(
        id: '1', name: 'Second', position: 2, createdAt: now,
      ));
      await db.productDao.insertProduct(createTestCompanion(
        id: '2', name: 'First', position: 1, createdAt: now,
      ));
      await db.productDao.insertProduct(createTestCompanion(
        id: '3', name: 'Third', position: 3, createdAt: now,
      ));

      final products = await db.productDao.getAll();
      expect(products[0].name, 'First');
      expect(products[1].name, 'Second');
      expect(products[2].name, 'Third');
    });
  });

  group('dirty tracking', () {
    test('getDirty returns only dirty non-deleted products', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', name: 'Clean'));
      await db.productDao.insertProduct(createTestCompanion(id: '2', name: 'Dirty', dirty: true));
      await db.productDao.insertProduct(createTestCompanion(id: '3', name: 'DirtyDeleted', dirty: true, deleted: true));

      final dirty = await db.productDao.getDirty();
      expect(dirty.length, 1);
      expect(dirty.first.name, 'Dirty');
    });

    test('getDeletedDirty returns only dirty deleted products', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', name: 'Clean'));
      await db.productDao.insertProduct(createTestCompanion(id: '2', name: 'DirtyDeleted', dirty: true, deleted: true));
      await db.productDao.insertProduct(createTestCompanion(id: '3', name: 'DeletedNotDirty', deleted: true));

      final deletedProducts = await db.productDao.getDeletedDirty();
      expect(deletedProducts.length, 1);
      expect(deletedProducts.first.name, 'DirtyDeleted');
    });

    test('setDirty marks product as dirty', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1'));
      await db.productDao.setDirty('1', userId: 'test_user');

      final product = await db.productDao.getById('1');
      expect(product!.dirty, true);
    });

    test('setDirty with deleted flag', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1'));
      await db.productDao.setDirty('1', userId: 'test_user', deleted: true);

      final product = await db.productDao.getById('1');
      expect(product!.dirty, true);
      expect(product.deleted, true);
    });

    test('updateProductFields marks dirty', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', name: 'Old'));
      await db.productDao.updateProductFields(id: '1', name: 'New');

      final product = await db.productDao.getById('1');
      expect(product!.name, 'New');
      expect(product.dirty, true);
    });

    test('updatePosition marks dirty', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', position: 0));
      await db.productDao.updatePosition('1', 5);

      final product = await db.productDao.getById('1');
      expect(product!.position, 5);
      expect(product.dirty, true);
    });

    test('softDelete marks deleted and dirty', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1'));
      await db.productDao.softDelete('1');

      final product = await db.productDao.getById('1');
      expect(product!.deleted, true);
      expect(product.dirty, true);

      // Should not appear in getAll
      final all = await db.productDao.getAll();
      expect(all.isEmpty, true);
    });

    test('hardDelete removes from database', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1'));
      await db.productDao.hardDelete('1');

      final product = await db.productDao.getById('1');
      expect(product, null);
    });

    test('markSynced clears dirty and sets syncedAt', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', dirty: true));
      final now = DateTime.now();
      await db.productDao.markSynced('1', now);

      final product = await db.productDao.getById('1');
      expect(product!.dirty, false);
      expect(product.syncedAt, isNotNull);
      // SQLite truncates to milliseconds, so compare within tolerance
      expect(product.syncedAt!.difference(now).inMilliseconds.abs(), lessThan(1000));
    });

    test('markAllSynced clears dirty for multiple products', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', dirty: true));
      await db.productDao.insertProduct(createTestCompanion(id: '2', dirty: true));
      await db.productDao.insertProduct(createTestCompanion(id: '3', dirty: true));

      final now = DateTime.now();
      await db.productDao.markAllSynced(['1', '3'], now);

      final p1 = await db.productDao.getById('1');
      final p2 = await db.productDao.getById('2');
      final p3 = await db.productDao.getById('3');

      expect(p1!.dirty, false);
      expect(p2!.dirty, true);
      expect(p3!.dirty, false);
    });
  });

  group('upsertFromRemote', () {
    test('inserts if not exists', () async {
      final remote = ProductTableData(
        id: 'remote_1', name: 'Remote Product', isChecked: false,
        isImportant: false, quantity: 1, createdBy: 'remote',
        createdAt: DateTime.now(), position: 0, listId: 'supermercado',
        dirty: false, deleted: false, lastModified: DateTime.now(),
        syncedAt: null, userId: 'remote',
      );

      await db.productDao.upsertFromRemote(remote);

      final product = await db.productDao.getById('remote_1');
      expect(product, isNotNull);
      expect(product!.name, 'Remote Product');
      expect(product.dirty, false);
    });

    test('updates if exists and NOT dirty', () async {
      await db.productDao.insertProduct(createTestCompanion(
        id: '1', name: 'Local', dirty: false,
      ));

      final remote = ProductTableData(
        id: '1', name: 'Remote Updated', isChecked: true,
        isImportant: false, quantity: 5, createdBy: 'remote',
        createdAt: DateTime.now(), position: 2, listId: 'supermercado',
        dirty: false, deleted: false, lastModified: DateTime.now(),
        syncedAt: null, userId: 'remote',
      );

      await db.productDao.upsertFromRemote(remote);

      final product = await db.productDao.getById('1');
      expect(product!.name, 'Remote Updated');
      expect(product.isChecked, true);
      expect(product.dirty, false);
    });

    test('does NOT overwrite if exists and IS dirty', () async {
      await db.productDao.insertProduct(createTestCompanion(
        id: '1', name: 'Local Dirty', dirty: true, isChecked: true,
      ));

      final remote = ProductTableData(
        id: '1', name: 'Remote', isChecked: false,
        isImportant: false, quantity: 1, createdBy: 'remote',
        createdAt: DateTime.now(), position: 0, listId: 'supermercado',
        dirty: false, deleted: false, lastModified: DateTime.now(),
        syncedAt: null, userId: 'remote',
      );

      await db.productDao.upsertFromRemote(remote);

      final product = await db.productDao.getById('1');
      expect(product!.name, 'Local Dirty');
      expect(product.isChecked, true);
    });
  });

  group('replaceAllFromRemote', () {
    test('deletes non-dirty and inserts remote products', () async {
      // Local non-dirty should be deleted
      await db.productDao.insertProduct(createTestCompanion(
        id: 'local_clean', name: 'Local Clean', dirty: false,
      ));
      // Local dirty should be preserved
      await db.productDao.insertProduct(createTestCompanion(
        id: 'local_dirty', name: 'Local Dirty', dirty: true,
      ));

      final remoteProducts = [
        ProductTableData(
          id: 'remote_1', name: 'Remote 1', isChecked: false,
          isImportant: false, quantity: 1, createdBy: 'remote',
          createdAt: DateTime.now(), position: 0, listId: 'supermercado',
          dirty: false, deleted: false, lastModified: DateTime.now(),
          syncedAt: null, userId: 'remote',
        ),
      ];

      await db.productDao.replaceAllFromRemote(remoteProducts);

      final all = await db.productDao.getAll();
      expect(all.length, 2);

      final remote = await db.productDao.getById('remote_1');
      expect(remote, isNotNull);

      final dirtyProd = await db.productDao.getById('local_dirty');
      expect(dirtyProd, isNotNull);
      expect(dirtyProd!.name, 'Local Dirty');

      final clean = await db.productDao.getById('local_clean');
      expect(clean, null);
    });
  });

  group('deleteAllNotDirty', () {
    test('deletes only non-dirty products', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', dirty: false));
      await db.productDao.insertProduct(createTestCompanion(id: '2', dirty: true));

      await db.productDao.deleteAllNotDirty();

      final all = await db.productDao.getAll();
      expect(all.length, 1);
      expect(all.first.id, '2');
    });
  });

  group('count', () {
    test('counts non-deleted products', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1'));
      await db.productDao.insertProduct(createTestCompanion(id: '2'));
      await db.productDao.insertProduct(createTestCompanion(id: '3', deleted: true));

      final count = await db.productDao.count();
      expect(count, 2);
    });
  });

  group('getById', () {
    test('returns product if exists', () async {
      await db.productDao.insertProduct(createTestCompanion(id: '1', name: 'Found'));
      final product = await db.productDao.getById('1');
      expect(product, isNotNull);
      expect(product!.name, 'Found');
    });

    test('returns null if not exists', () async {
      final product = await db.productDao.getById('nonexistent');
      expect(product, null);
    });
  });
}
