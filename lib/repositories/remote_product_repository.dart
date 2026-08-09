import 'package:lista_familia/models/product.dart';
import 'package:lista_familia/services/supabase_service.dart';

class RemoteProductRepository {
  final SupabaseService _service = SupabaseService.instance;

  Future<List<Product>> getAll() async {
    return await _service.getProducts();
  }

  Stream<List<Product>> watchProducts() {
    return _service.watchProducts();
  }

  Future<Product> addProduct(String name, String createdBy) async {
    return await _service.addProduct(name, createdBy);
  }

  Future<void> updateAll(Product product) async {
    await _service.updateAll(
      product.id,
      name: product.name,
      isChecked: product.isChecked,
      isImportant: product.isImportant,
      quantity: product.quantity,
      position: product.position,
    );
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
  }
}