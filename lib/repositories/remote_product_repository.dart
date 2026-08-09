import 'package:lista_familia/models/product.dart';
import 'package:lista_familia/models/list_model.dart';
import 'package:lista_familia/services/supabase_service.dart';

class RemoteProductRepository {
  final SupabaseService _service = SupabaseService.instance;

  Future<List<Product>> getAll() async {
    return await _service.getProducts();
  }

  Stream<List<Product>> watchProducts() {
    return _service.watchProducts();
  }

  Future<Product> addProduct(String name, String createdBy, {String listId = 'supermercado'}) async {
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
    );
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
  }

  // --- Lists ---

  Stream<List<ListModel>> watchLists() {
    return _service.watchLists();
  }

  Future<List<ListModel>> getLists() async {
    return await _service.getLists();
  }

  Future<ListModel> addList(String name, String icon) async {
    return await _service.addList(name, icon);
  }

  Future<void> updateList(String id, {String? name, String? icon}) async {
    await _service.updateList(id, name: name, icon: icon);
  }

  Future<void> deleteList(String id) async {
    await _service.deleteList(id);
  }
}
