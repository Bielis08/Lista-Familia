import 'dart:async';
import 'package:lista_familia/database/app_database.dart';
import 'package:lista_familia/models/product.dart';
import 'package:lista_familia/repositories/product_repository.dart';
import 'package:lista_familia/repositories/local_product_repository.dart';
import 'package:lista_familia/services/sync_service.dart';

class ProductRepositoryImpl implements ProductRepository {
  final LocalProductRepository _local;
  final SyncService _syncService;

  ProductRepositoryImpl(this._local, this._syncService);

  static ProductRepositoryImpl? _instance;

  static ProductRepositoryImpl getInstance({
    required AppDatabase db,
  }) {
    _instance ??= ProductRepositoryImpl(
      LocalProductRepository(db),
      SyncService(db),
    );
    return _instance!;
  }

  @override
  Stream<List<Product>> watchProducts() {
    return _local.watchProducts();
  }

  @override
  Future<List<Product>> getAll() async {
    return await _local.getAll();
  }

  @override
  Future<Product> addProduct(String name, String createdBy) async {
    final product = await _local.addProduct(name, createdBy);
    _syncService.syncNow();
    return product;
  }

  @override
  Future<void> toggleProduct(String id, bool isChecked) async {
    await _local.toggleProduct(id, isChecked);
    _syncService.syncNow();
  }

  @override
  Future<void> toggleImportant(String id, bool isImportant) async {
    await _local.toggleImportant(id, isImportant);
    _syncService.syncNow();
  }

  @override
  Future<void> updateQuantity(String id, int quantity) async {
    await _local.updateQuantity(id, quantity);
    _syncService.syncNow();
  }

  @override
  Future<void> updateProduct(String id, String name, int quantity) async {
    await _local.updateProduct(id, name, quantity);
    _syncService.syncNow();
  }

  @override
  Future<void> updatePosition(String id, int position) async {
    await _local.updatePosition(id, position);
    _syncService.syncNow();
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _local.deleteProduct(id);
    _syncService.syncNow();
  }

  @override
  Future<void> uncheckAll() async {
    await _local.uncheckAll();
    _syncService.syncNow();
  }

  @override
  Future<void> deleteCheckedProducts() async {
    await _local.deleteCheckedProducts();
    _syncService.syncNow();
  }

  @override
  Future<void> deleteAllProducts() async {
    await _local.deleteAllProducts();
    _syncService.syncNow();
  }

  @override
  Future<void> syncNow() async {
    await _syncService.syncNow();
  }

  @override
  bool get isConnected => _syncService.isConnected;

  @override
  Stream<bool> get onConnectivityChanged => _syncService.onConnectivityChanged;

  @override
  int get pendingCount => _syncService.pendingCount;

  @override
  Stream<int> get onPendingChanged => _syncService.onPendingChanged;

  @override
  SyncStatus get syncStatus => _syncService.status;

  @override
  Stream<SyncStatus> get onStatusChanged => _syncService.onStatusChanged;

  @override
  DateTime? get lastSyncTime => _syncService.lastSyncTime;

  LocalProductRepository get local => _local;
}