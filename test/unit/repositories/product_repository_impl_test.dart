import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/database/app_database.dart';
import 'package:lista_familia/repositories/product_repository_impl.dart';
import 'package:lista_familia/repositories/local_product_repository.dart';
import 'package:lista_familia/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalProductRepository local;
  late SyncService syncService;
  late ProductRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = LocalProductRepository(db);
    syncService = SyncService(db);
    repository = ProductRepositoryImpl(local, syncService);
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('addProduct', () {
    test('creates product', () async {
      final product = await repository.addProduct('Leche', 'mom');

      expect(product.name, 'Leche');
      expect(product.createdBy, 'mom');

      final dbProduct = await db.productDao.getById(product.id);
      expect(dbProduct!.dirty, true);
    });
  });

  group('toggleProduct', () {
    test('toggles and marks dirty', () async {
      final product = await repository.addProduct('Pan', 'dad');
      await repository.toggleProduct(product.id, true);

      final dbProduct = await db.productDao.getById(product.id);
      expect(dbProduct!.isChecked, true);
      expect(dbProduct.dirty, true);
    });
  });

  group('toggleImportant', () {
    test('toggles important and marks dirty', () async {
      final product = await repository.addProduct('Huevos', 'mom');
      await repository.toggleImportant(product.id, true);

      final dbProduct = await db.productDao.getById(product.id);
      expect(dbProduct!.isImportant, true);
    });
  });

  group('updateQuantity', () {
    test('updates quantity', () async {
      final product = await repository.addProduct('Queso', 'dad');
      await repository.updateQuantity(product.id, 5);

      final dbProduct = await db.productDao.getById(product.id);
      expect(dbProduct!.quantity, 5);
    });
  });

  group('updateProduct', () {
    test('updates name and quantity', () async {
      final product = await repository.addProduct('Old Name', 'mom');
      await repository.updateProduct(product.id, 'New Name', 3);

      final dbProduct = await db.productDao.getById(product.id);
      expect(dbProduct!.name, 'New Name');
      expect(dbProduct.quantity, 3);
    });
  });

  group('updatePosition', () {
    test('updates position', () async {
      final product = await repository.addProduct('Item', 'dad');
      await repository.updatePosition(product.id, 10);

      final dbProduct = await db.productDao.getById(product.id);
      expect(dbProduct!.position, 10);
    });
  });

  group('deleteProduct', () {
    test('soft deletes product', () async {
      final product = await repository.addProduct('To Delete', 'mom');
      await repository.deleteProduct(product.id);

      final dbProduct = await db.productDao.getById(product.id);
      expect(dbProduct!.deleted, true);
    });
  });

  group('uncheckAll', () {
    test('unchecks all products', () async {
      final p1 = await repository.addProduct('A', 'mom');
      final p2 = await repository.addProduct('B', 'dad');
      await repository.toggleProduct(p1.id, true);
      await repository.toggleProduct(p2.id, true);

      await repository.uncheckAll();

      final all = await repository.getAll();
      expect(all.every((p) => !p.isChecked), true);
    });
  });

  group('deleteCheckedProducts', () {
    test('deletes only checked products', () async {
      final p1 = await repository.addProduct('A', 'mom');
      final p2 = await repository.addProduct('B', 'dad');
      await repository.toggleProduct(p1.id, true);

      await repository.deleteCheckedProducts();

      final dbP1 = await db.productDao.getById(p1.id);
      final dbP2 = await db.productDao.getById(p2.id);
      expect(dbP1!.deleted, true);
      expect(dbP2!.deleted, false);
    });
  });

  group('deleteAllProducts', () {
    test('deletes all products', () async {
      await repository.addProduct('A', 'mom');
      await repository.addProduct('B', 'dad');

      await repository.deleteAllProducts();

      final all = await repository.getAll();
      expect(all.isEmpty, true);
    });
  });

  group('getAll', () {
    test('returns all non-deleted products', () async {
      await repository.addProduct('A', 'mom');
      await repository.addProduct('B', 'dad');

      final products = await repository.getAll();
      expect(products.length, 2);
    });
  });

  group('watchProducts', () {
    test('stream emits on changes', () async {
      final products = await repository.watchProducts().first;
      expect(products.isEmpty, true);
    });
  });

  group('sync state getters', () {
    test('isConnected delegates to syncService', () {
      expect(repository.isConnected, syncService.isConnected);
    });

    test('pendingCount delegates to syncService', () {
      expect(repository.pendingCount, syncService.pendingCount);
    });

    test('syncStatus delegates to syncService', () {
      expect(repository.syncStatus, syncService.status);
    });

    test('lastSyncTime delegates to syncService', () {
      expect(repository.lastSyncTime, syncService.lastSyncTime);
    });
  });

  group('local getter', () {
    test('exposes local repository', () {
      expect(repository.local, isA<LocalProductRepository>());
    });
  });
}
