import 'dart:async';
import 'package:lista_familia/models/product.dart';
import 'package:lista_familia/models/list_model.dart';
import 'package:lista_familia/services/sync_service.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchProducts({String listId = 'supermercado'});
  Future<List<Product>> getAll({String listId = 'supermercado'});
  Future<Product> addProduct(String name, String createdBy, {String listId = 'supermercado', double price = 0.0});
  Future<void> toggleProduct(String id, bool isChecked);
  Future<void> toggleImportant(String id, bool isImportant);
  Future<void> updateQuantity(String id, int quantity);
  Future<void> updateProduct(String id, String name, int quantity, {double price = 0.0});
  Future<void> updatePosition(String id, int position);
  Future<void> updatePositions(List<({String id, int position})> updates);
  Future<void> deleteProduct(String id);
  Future<void> uncheckAll({String listId = 'supermercado'});
  Future<void> deleteCheckedProducts({String listId = 'supermercado'});
  Future<void> deleteAllProducts({String listId = 'supermercado'});
  Future<void> syncNow();

  Stream<List<ListModel>> watchLists();
  Future<List<ListModel>> getAllLists();
  Future<ListModel> addList(String name, String icon);
  Future<void> updateList(String id, {String? name, String? icon});
  Future<void> deleteList(String id);

  bool get isConnected;
  Stream<bool> get onConnectivityChanged;
  int get pendingCount;
  Stream<int> get onPendingChanged;
  SyncStatus get syncStatus;
  Stream<SyncStatus> get onStatusChanged;
  DateTime? get lastSyncTime;
}
