import 'package:drift/drift.dart';
import 'package:lista_familia/database/app_database.dart';
import 'package:lista_familia/models/product.dart' as models;
import 'package:lista_familia/models/list_model.dart' as list_models;

class LocalProductRepository {
  final AppDatabase _db;

  LocalProductRepository(this._db);

  Stream<List<models.Product>> watchProducts({String listId = 'supermercado'}) {
    return _db.productDao.watchByList(listId).map(
          (rows) => rows.map(toProduct).toList(),
        );
  }

  Future<List<models.Product>> getAll({String listId = 'supermercado'}) async {
    final rows = await _db.productDao.getAllByList(listId);
    return rows.map(toProduct).toList();
  }

  Future<List<models.Product>> getAllProducts() async {
    final rows = await _db.productDao.getAll();
    return rows.map(toProduct).toList();
  }

  Future<List<models.Product>> getDirty() async {
    final rows = await _db.productDao.getDirty();
    return rows.map(toProduct).toList();
  }

  Future<List<models.Product>> getDeletedDirty() async {
    final rows = await _db.productDao.getDeletedDirty();
    return rows.map(toProduct).toList();
  }

  Future<void> syncFromRemote(List<models.Product> remoteProducts) async {
    final remoteRows = remoteProducts.map((p) => ProductTableData(
          id: p.id,
          name: p.name,
          isChecked: p.isChecked,
          isImportant: p.isImportant,
          quantity: p.quantity,
          createdBy: p.createdBy,
          createdAt: p.createdAt,
          position: p.position,
          listId: p.listId,
          dirty: false,
          deleted: false,
          lastModified: p.createdAt,
          syncedAt: DateTime.now(),
          userId: p.createdBy,
        )).toList();
    await _db.productDao.replaceAllFromRemote(remoteRows);
  }

  Future<models.Product> addProduct(String name, String createdBy, {String listId = 'supermercado'}) async {
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final count = await _db.productDao.countByList(listId);
    final companion = ProductTableCompanion(
      id: Value(id),
      name: Value(name),
      isChecked: const Value(false),
      isImportant: const Value(false),
      quantity: const Value(1),
      createdBy: Value(createdBy),
      createdAt: Value(now),
      position: Value(count),
      listId: Value(listId),
      dirty: const Value(true),
      deleted: const Value(false),
      lastModified: Value(now),
      syncedAt: const Value(null),
      userId: Value(createdBy),
    );
    await _db.productDao.insertProduct(companion);
    return models.Product(
      id: id,
      name: name,
      createdBy: createdBy,
      createdAt: now,
      position: count,
      listId: listId,
    );
  }

  Future<void> toggleProduct(String id, bool isChecked) async {
    await _db.productDao.updateProductFields(id: id, isChecked: isChecked);
  }

  Future<void> toggleImportant(String id, bool isImportant) async {
    await _db.productDao.updateProductFields(id: id, isImportant: isImportant);
  }

  Future<void> updateQuantity(String id, int quantity) async {
    await _db.productDao.updateProductFields(id: id, quantity: quantity);
  }

  Future<void> updateProduct(String id, String name, int quantity) async {
    await _db.productDao.updateProductFields(id: id, name: name, quantity: quantity);
  }

  Future<void> updatePosition(String id, int position) async {
    await _db.productDao.updatePosition(id, position);
  }

  Future<void> deleteProduct(String id) async {
    await _db.productDao.softDelete(id);
  }

  Future<void> uncheckAll({String listId = 'supermercado'}) async {
    final products = await _db.productDao.getAllByList(listId);
    for (final p in products) {
      if (p.isChecked) {
        await _db.productDao.updateProductFields(id: p.id, isChecked: false);
      }
    }
  }

  Future<void> deleteCheckedProducts({String listId = 'supermercado'}) async {
    final products = await _db.productDao.getAllByList(listId);
    for (final p in products) {
      if (p.isChecked) {
        await _db.productDao.softDelete(p.id);
      }
    }
  }

  Future<void> deleteAllProducts({String listId = 'supermercado'}) async {
    final products = await _db.productDao.getAllByList(listId);
    for (final p in products) {
      await _db.productDao.softDelete(p.id);
    }
  }

  Future<void> markSynced(String id) async {
    await _db.productDao.markSynced(id, DateTime.now());
  }

  Future<void> markAllSynced(List<String> ids) async {
    await _db.productDao.markAllSynced(ids, DateTime.now());
  }

  Future<void> hardDelete(String id) async {
    await _db.productDao.hardDelete(id);
  }

  models.Product toProduct(ProductTableData row) {
    return models.Product(
      id: row.id,
      name: row.name,
      isChecked: row.isChecked,
      isImportant: row.isImportant,
      quantity: row.quantity,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
      position: row.position,
      listId: row.listId,
    );
  }

  // --- Lists ---

  Stream<List<list_models.ListModel>> watchLists() {
    return _db.listDao.watchAll().map(
          (rows) => rows.map(toListModel).toList(),
        );
  }

  Future<List<list_models.ListModel>> getAllLists() async {
    final rows = await _db.listDao.getAll();
    return rows.map(toListModel).toList();
  }

  Future<list_models.ListModel> addList(String name, String icon) async {
    final now = DateTime.now();
    final id = name.toLowerCase().replaceAll(' ', '-');
    final count = await _db.listDao.count();
    final companion = ListTableCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      position: Value(count),
      createdAt: Value(now),
    );
    await _db.listDao.insertList(companion);
    return list_models.ListModel(
      id: id,
      name: name,
      icon: icon,
      position: count,
      createdAt: now,
    );
  }

  Future<void> updateList(String id, {String? name, String? icon}) async {
    final companion = ListTableCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      icon: icon != null ? Value(icon) : const Value.absent(),
    );
    await _db.listDao.updateList(companion);
  }

  Future<void> deleteList(String id) async {
    await _db.listDao.deleteList(id);
  }

  list_models.ListModel toListModel(ListTableData row) {
    return list_models.ListModel(
      id: row.id,
      name: row.name,
      icon: row.icon,
      position: row.position,
      createdAt: row.createdAt,
    );
  }

  Future<void> syncListsFromRemote(List<list_models.ListModel> remoteLists) async {
    final remoteRows = remoteLists.map((l) => ListTableData(
          id: l.id,
          name: l.name,
          icon: l.icon,
          position: l.position,
          createdAt: l.createdAt,
        )).toList();
    await _db.listDao.replaceAllFromRemote(remoteRows);
  }
}
