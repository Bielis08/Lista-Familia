import 'dart:async';
import 'package:lista_familia/models/product.dart';
import 'package:lista_familia/services/sync_service.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchProducts();
  Future<List<Product>> getAll();
  Future<Product> addProduct(String name, String createdBy);
  Future<void> toggleProduct(String id, bool isChecked);
  Future<void> toggleImportant(String id, bool isImportant);
  Future<void> updateQuantity(String id, int quantity);
  Future<void> updateProduct(String id, String name, int quantity);
  Future<void> updatePosition(String id, int position);
  Future<void> deleteProduct(String id);
  Future<void> uncheckAll();
  Future<void> deleteCheckedProducts();
  Future<void> deleteAllProducts();
  Future<void> syncNow();
  bool get isConnected;
  Stream<bool> get onConnectivityChanged;
  int get pendingCount;
  Stream<int> get onPendingChanged;
  SyncStatus get syncStatus;
  Stream<SyncStatus> get onStatusChanged;
  DateTime? get lastSyncTime;
}