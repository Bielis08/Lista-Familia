import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/database/app_database.dart';
import 'package:lista_familia/repositories/local_product_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;
  late LocalProductRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalProductRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertTestProduct({
    String id = 'test_1',
    String name = 'Test',
    bool dirty = false,
    bool deleted = false,
    bool isChecked = false,
    int position = 0,
  }) async {
    await db.productDao.insertProduct(ProductTableCompanion(
      id: Value(id),
      name: Value(name),
      isChecked: Value(isChecked),
      dirty: Value(dirty),
      deleted: Value(deleted),
      lastModified: Value(DateTime.now()),
      createdBy: Value('test_user'),
      createdAt: Value(DateTime.now()),
      userId: Value('test_user'),
    ));
  }

  group('addProduct', () {
    test('creates product with dirty=true and auto position', () async {
      final product = await repo.addProduct('Leche', 'mom');

      expect(product.name, 'Leche');
      expect(product.createdBy, 'mom');
      expect(product.position, 0);

      final dbProduct = await db.productDao.getById(product.id);
      expect(dbProduct!.dirty, true);
      expect(dbProduct.deleted, false);
    });

    test('increments position', () async {
      await repo.addProduct('First', 'mom');
      final second = await repo.addProduct('Second', 'mom');

      expect(second.position, 1);
    });
  });

  group('getAll', () {
    test('returns non-deleted products', () async {
      await insertTestProduct(id: '1', name: 'A');
      await insertTestProduct(id: '2', name: 'B');

      final products = await repo.getAll();
      expect(products.length, 2);
    });

    test('excludes deleted', () async {
      await insertTestProduct(id: '1', name: 'A');
      await insertTestProduct(id: '2', name: 'B', deleted: true);

      final products = await repo.getAll();
      expect(products.length, 1);
    });
  });

  group('toggleProduct', () {
    test('updates isChecked and marks dirty', () async {
      await insertTestProduct(id: '1', isChecked: false);
      await repo.toggleProduct('1', true);

      final product = await db.productDao.getById('1');
      expect(product!.isChecked, true);
      expect(product.dirty, true);
    });
  });

  group('toggleImportant', () {
    test('updates isImportant and marks dirty', () async {
      await insertTestProduct(id: '1');
      await repo.toggleImportant('1', true);

      final product = await db.productDao.getById('1');
      expect(product!.isImportant, true);
      expect(product.dirty, true);
    });
  });

  group('updateQuantity', () {
    test('updates quantity and marks dirty', () async {
      await insertTestProduct(id: '1');
      await repo.updateQuantity('1', 5);

      final product = await db.productDao.getById('1');
      expect(product!.quantity, 5);
      expect(product.dirty, true);
    });
  });

  group('updateProduct', () {
    test('updates name and quantity', () async {
      await insertTestProduct(id: '1', name: 'Old');
      await repo.updateProduct('1', 'New', 3);

      final product = await db.productDao.getById('1');
      expect(product!.name, 'New');
      expect(product.quantity, 3);
    });
  });

  group('updatePosition', () {
    test('updates position and marks dirty', () async {
      await insertTestProduct(id: '1', position: 0);
      await repo.updatePosition('1', 5);

      final product = await db.productDao.getById('1');
      expect(product!.position, 5);
      expect(product.dirty, true);
    });
  });

  group('deleteProduct', () {
    test('soft deletes product', () async {
      await insertTestProduct(id: '1');
      await repo.deleteProduct('1');

      final product = await db.productDao.getById('1');
      expect(product!.deleted, true);
      expect(product.dirty, true);
    });
  });

  group('uncheckAll', () {
    test('unchecks all checked products', () async {
      await insertTestProduct(id: '1', isChecked: true);
      await insertTestProduct(id: '2', isChecked: true);
      await insertTestProduct(id: '3', isChecked: false);

      await repo.uncheckAll();

      final p1 = await db.productDao.getById('1');
      final p2 = await db.productDao.getById('2');
      final p3 = await db.productDao.getById('3');

      expect(p1!.isChecked, false);
      expect(p2!.isChecked, false);
      expect(p3!.isChecked, false);
    });
  });

  group('deleteCheckedProducts', () {
    test('soft deletes only checked products', () async {
      await insertTestProduct(id: '1', isChecked: true);
      await insertTestProduct(id: '2', isChecked: false);

      await repo.deleteCheckedProducts();

      final p1 = await db.productDao.getById('1');
      final p2 = await db.productDao.getById('2');

      expect(p1!.deleted, true);
      expect(p2!.deleted, false);
    });
  });

  group('deleteAllProducts', () {
    test('soft deletes all products', () async {
      await insertTestProduct(id: '1');
      await insertTestProduct(id: '2');

      await repo.deleteAllProducts();

      final all = await db.productDao.getAll();
      expect(all.isEmpty, true);

      // Still in DB as soft deleted
      final p1 = await db.productDao.getById('1');
      expect(p1!.deleted, true);
    });
  });

  group('getDirty / getDeletedDirty', () {
    test('getDirty returns dirty non-deleted', () async {
      await insertTestProduct(id: '1', dirty: true);
      await insertTestProduct(id: '2', dirty: true, deleted: true);
      await insertTestProduct(id: '3', dirty: false);

      final dirty = await repo.getDirty();
      expect(dirty.length, 1);
      expect(dirty.first.id, '1');
    });

    test('getDeletedDirty returns dirty deleted', () async {
      await insertTestProduct(id: '1', dirty: true);
      await insertTestProduct(id: '2', dirty: true, deleted: true);

      final deleted = await repo.getDeletedDirty();
      expect(deleted.length, 1);
      expect(deleted.first.id, '2');
    });
  });

  group('syncFromRemote', () {
    test('replaces non-dirty with remote, preserves dirty', () async {
      await insertTestProduct(id: 'local_clean', name: 'Clean', dirty: false);
      await insertTestProduct(id: 'local_dirty', name: 'Dirty', dirty: true);

      final remote = [
        repo.toProduct(ProductTableData(
          id: 'remote_1', name: 'Remote', isChecked: false,
          isImportant: false, quantity: 1, createdBy: 'remote',
          createdAt: DateTime.now(), position: 0, dirty: false,
          deleted: false, lastModified: DateTime.now(), syncedAt: null,
          userId: 'remote',
        )),
      ];

      await repo.syncFromRemote(remote);

      final all = await db.productDao.getAll();
      expect(all.length, 2);

      final remoteProd = await db.productDao.getById('remote_1');
      expect(remoteProd, isNotNull);

      final dirtyProd = await db.productDao.getById('local_dirty');
      expect(dirtyProd, isNotNull);
    });
  });

  group('markSynced / hardDelete', () {
    test('markSynced clears dirty', () async {
      await insertTestProduct(id: '1', dirty: true);
      await repo.markSynced('1');

      final product = await db.productDao.getById('1');
      expect(product!.dirty, false);
    });

    test('hardDelete removes from db', () async {
      await insertTestProduct(id: '1');
      await repo.hardDelete('1');

      final product = await db.productDao.getById('1');
      expect(product, null);
    });
  });

  group('toProduct', () {
    test('converts ProductTableData to Product', () async {
      final now = DateTime(2026, 1, 15);
      final row = ProductTableData(
        id: '1', name: 'Leche', isChecked: true,
        isImportant: false, quantity: 3, createdBy: 'mom',
        createdAt: now, position: 5, dirty: false,
        deleted: false, lastModified: now, syncedAt: null,
        userId: 'mom',
      );

      final product = repo.toProduct(row);

      expect(product.id, '1');
      expect(product.name, 'Leche');
      expect(product.isChecked, true);
      expect(product.quantity, 3);
      expect(product.createdBy, 'mom');
      expect(product.position, 5);
    });
  });
}
