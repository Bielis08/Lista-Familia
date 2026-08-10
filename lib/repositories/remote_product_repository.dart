import 'package:lista_familia/constants.dart';
import 'package:lista_familia/models/product.dart';
import 'package:lista_familia/models/list_model.dart';
import 'package:lista_familia/services/supabase_service.dart';

class RemoteProductRepository {
  final SupabaseService _service;

  RemoteProductRepository([SupabaseService? service])
      : _service = service ?? SupabaseService.instance;

  Future<List<Product>> getAll() async {
    return await _service.getProducts();
  }

  Stream<List<Product>> watchProducts() {
    return _service.watchProducts();
  }

  Future<Product> addProduct(String name, String createdBy, {String listId = defaultListId}) async {
    return await _service.addProduct(name, createdBy, listId: listId);
  }

  Future<void> updateAll(Product product) async {
    await _service.updateAll(
      product.id,
      name: product.name,
      isChecked: product.isChecked,
      isImportant: product.isImportant,
      quantity: product.quantity,
      position: product.position,
      listId: product.listId,
      createdBy: product.createdBy,
      createdAt: product.createdAt,
    );
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
  }

  Future<void> deleteProductsByList(String listId) async {
    await _service.deleteProductsByList(listId);
  }

  Stream<List<ListModel>> watchLists() {
    return _service.watchLists();
  }

  Future<List<ListModel>> getLists() async {
    return await _service.getLists();
  }

  Future<ListModel> addList(String name, String icon) async {
    return await _service.addList(name, icon);
  }

  Future<void> updateList(String id, {String? name, String? icon, int? position, DateTime? createdAt}) async {
    await _service.updateList(id, name: name, icon: icon, position: position, createdAt: createdAt);
  }

  Future<void> deleteList(String id) async {
    await _service.deleteList(id);
  }
}
