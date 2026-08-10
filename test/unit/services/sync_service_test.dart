import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/database/app_database.dart';
import 'package:lista_familia/services/sync_service.dart';
import 'package:drift/drift.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncService syncService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncService = SyncService(db);
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  Future<void> insertTestProduct({
    String id = 'test_1',
    String name = 'Test',
    bool dirty = false,
    bool deleted = false,
  }) async {
    await db.productDao.insertProduct(ProductTableCompanion(
      id: Value(id),
      name: Value(name),
      dirty: Value(dirty),
      deleted: Value(deleted),
      lastModified: Value(DateTime.now()),
      createdBy: const Value('test_user'),
      createdAt: Value(DateTime.now()),
      userId: const Value('test_user'),
    ));
  }

  group('initialization', () {
    test('initializes with default state', () {
      expect(syncService.status, SyncStatus.idle);
    });

    test('_updatePendingCount is called on init', () async {
      await db.productDao.insertProduct(ProductTableCompanion(
        id: const Value('1'),
        name: const Value('Dirty'),
        dirty: const Value(true),
        deleted: const Value(false),
        lastModified: Value(DateTime.now()),
        createdBy: const Value('test_user'),
        createdAt: Value(DateTime.now()),
        userId: const Value('test_user'),
      ));

      final service = SyncService(db);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(service.pendingCount, 1);
      service.dispose();
    });
  });

  group('pendingCount', () {
    test('counts dirty products', () async {
      await insertTestProduct(id: '1', dirty: true);
      await insertTestProduct(id: '2', dirty: true);
      await insertTestProduct(id: '3', dirty: false);

      await syncService.syncNow();

      expect(syncService.pendingCount, 2);
    });

    test('counts dirty deleted products', () async {
      await insertTestProduct(id: '1', dirty: true, deleted: true);
      await insertTestProduct(id: '2', dirty: true, deleted: true);

      await syncService.syncNow();

      expect(syncService.pendingCount, 2);
    });
  });

  group('status', () {
    test('syncNow reports error when remote is unreachable', () async {
      final statuses = <SyncStatus>[];
      syncService.onStatusChanged.listen(statuses.add);

      await syncService.syncNow();

      expect(syncService.status, SyncStatus.error);
      expect(statuses, contains(SyncStatus.syncing));
      expect(statuses, contains(SyncStatus.error));
    });

    test('syncNow preserves pending dirty records on remote failure', () async {
      await insertTestProduct(id: '1', dirty: true);

      await syncService.syncNow();

      expect(syncService.status, SyncStatus.error);
      expect(syncService.pendingCount, 1);
    });
  });

  group('isConnected', () {
    test('defaults to true', () {
      expect(syncService.isConnected, true);
    });
  });

  group('dispose', () {
    test('can be called multiple times safely', () {
      syncService.dispose();
      syncService.dispose();
    });
  });
}
