import 'package:drift/drift.dart';
import 'package:lista_familia/database/tables/products.dart';
import '../app_database.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [ProductTable])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Stream<List<ProductTableData>> watchAll() {
    return (select(productTable)
          ..where((p) => p.deleted.equals(false))
          ..orderBy([
            (p) => OrderingTerm.asc(p.position),
            (p) => OrderingTerm.desc(p.createdAt),
          ]))
        .watch();
  }

  Future<List<ProductTableData>> getAll() {
    return (select(productTable)
          ..where((p) => p.deleted.equals(false))
          ..orderBy([
            (p) => OrderingTerm.asc(p.position),
            (p) => OrderingTerm.desc(p.createdAt),
          ]))
        .get();
  }

  Future<List<ProductTableData>> getDirty() {
    return (select(productTable)
          ..where((p) => p.dirty.equals(true) & p.deleted.equals(false)))
        .get();
  }

  Future<List<ProductTableData>> getDeletedDirty() {
    return (select(productTable)
          ..where((p) => p.dirty.equals(true) & p.deleted.equals(true)))
        .get();
  }

  Future<int> insertProduct(ProductTableCompanion product) {
    return into(productTable).insert(product, mode: InsertMode.replace);
  }

  Future<void> upsertFromRemote(ProductTableData remote) async {
    final existing = await (select(productTable)..where((p) => p.id.equals(remote.id))).getSingleOrNull();

    if (existing == null) {
      await into(productTable).insert(
        ProductTableCompanion(
          id: Value(remote.id),
          name: Value(remote.name),
          isChecked: Value(remote.isChecked),
          isImportant: Value(remote.isImportant),
          quantity: Value(remote.quantity),
          createdBy: Value(remote.createdBy),
          createdAt: Value(remote.createdAt),
          position: Value(remote.position),
          dirty: const Value(false),
          deleted: const Value(false),
          lastModified: Value(remote.createdAt),
          syncedAt: Value(DateTime.now()),
          userId: Value(remote.createdBy),
        ),
      );
    } else if (!existing.dirty) {
      await (update(productTable)..where((p) => p.id.equals(remote.id))).write(
        ProductTableCompanion(
          name: Value(remote.name),
          isChecked: Value(remote.isChecked),
          isImportant: Value(remote.isImportant),
          quantity: Value(remote.quantity),
          position: Value(remote.position),
          dirty: const Value(false),
          lastModified: Value(remote.createdAt),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> replaceAllFromRemote(List<ProductTableData> remoteProducts) async {
    await transaction(() async {
      await (delete(productTable)..where((p) => p.dirty.equals(false) & p.deleted.equals(false))).go();

      for (final remote in remoteProducts) {
        final existing = await (select(productTable)..where((p) => p.id.equals(remote.id))).getSingleOrNull();
        if (existing == null) {
          await into(productTable).insert(
            ProductTableCompanion(
              id: Value(remote.id),
              name: Value(remote.name),
              isChecked: Value(remote.isChecked),
              isImportant: Value(remote.isImportant),
              quantity: Value(remote.quantity),
              createdBy: Value(remote.createdBy),
              createdAt: Value(remote.createdAt),
              position: Value(remote.position),
              dirty: const Value(false),
              deleted: const Value(false),
              lastModified: Value(remote.createdAt),
              syncedAt: Value(DateTime.now()),
              userId: Value(remote.createdBy),
            ),
          );
        }
      }
    });
  }

  Future<void> markSynced(String id, DateTime syncedAt) async {
    await (update(productTable)..where((p) => p.id.equals(id))).write(
      ProductTableCompanion(
        dirty: const Value(false),
        syncedAt: Value(syncedAt),
      ),
    );
  }

  Future<void> markAllSynced(List<String> ids, DateTime syncedAt) async {
    await batch((batch) {
      for (final id in ids) {
        batch.update(productTable,
          ProductTableCompanion(
            dirty: const Value(false),
            syncedAt: Value(syncedAt),
          ),
          where: (p) => p.id.equals(id),
        );
      }
    });
  }

  Future<void> setDirty(String id, {bool deleted = false}) async {
    final now = DateTime.now();
    await (update(productTable)..where((p) => p.id.equals(id))).write(
      ProductTableCompanion(
        dirty: const Value(true),
        deleted: Value(deleted),
        lastModified: Value(now),
        userId: Value('local_user'),
      ),
    );
  }

  Future<void> updatePosition(String id, int position) async {
    final now = DateTime.now();
    await (update(productTable)..where((p) => p.id.equals(id))).write(
      ProductTableCompanion(
        position: Value(position),
        dirty: const Value(true),
        lastModified: Value(now),
        userId: Value('local_user'),
      ),
    );
  }

  Future<void> updateProductFields({
    required String id,
    String? name,
    int? quantity,
    bool? isChecked,
    bool? isImportant,
  }) async {
    final now = DateTime.now();
    final companion = ProductTableCompanion(
      dirty: const Value(true),
      lastModified: Value(now),
      userId: Value('local_user'),
      name: name != null ? Value(name) : const Value.absent(),
      quantity: quantity != null ? Value(quantity) : const Value.absent(),
      isChecked: isChecked != null ? Value(isChecked) : const Value.absent(),
      isImportant: isImportant != null ? Value(isImportant) : const Value.absent(),
    );
    await (update(productTable)..where((p) => p.id.equals(id))).write(companion);
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now();
    await (update(productTable)..where((p) => p.id.equals(id))).write(
      ProductTableCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        lastModified: Value(now),
        userId: Value('local_user'),
      ),
    );
  }

  Future<void> hardDelete(String id) async {
    await (delete(productTable)..where((p) => p.id.equals(id))).go();
  }

  Future<void> deleteAllNotDirty() async {
    await (delete(productTable)..where((p) => p.dirty.equals(false))).go();
  }

  Future<int> count() async {
    return (select(productTable)..where((p) => p.deleted.equals(false))).get().then((list) => list.length);
  }

  Future<ProductTableData?> getById(String id) {
    return (select(productTable)..where((p) => p.id.equals(id))).getSingleOrNull();
  }
}