import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  Future<void> initialize({
    required String url,
    required String publishableKey,
  }) async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
    );
    _client = Supabase.instance.client;
  }

  Stream<List<Product>> watchProducts() {
    return client
        .from('products')
        .stream(primaryKey: ['id'])
        .order('order', ascending: true)
        .map((rows) => rows.map((row) => Product.fromMap(row)).toList());
  }

  Future<List<Product>> getProducts() async {
    final response = await client
        .from('products')
        .select()
        .order('order', ascending: true);
    return (response as List).map((row) => Product.fromMap(row)).toList();
  }

  Future<Product> addProduct(String name, String createdBy) async {
    final now = DateTime.now().toIso8601String();
    final count = await client.from('products').select().count();
    final data = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'is_checked': false,
      'quantity': 1,
      'created_by': createdBy,
      'created_at': now,
      'order': count,
    };
    final response = await client.from('products').insert(data).select().maybeSingle();
    if (response == null) {
      throw Exception('No se pudo agregar el producto');
    }
    return Product.fromMap(response);
  }

  Future<void> toggleProduct(String id, bool isChecked) async {
    await client.from('products').update({'is_checked': isChecked}).eq('id', id);
  }

  Future<void> updateQuantity(String id, int quantity) async {
    await client.from('products').update({'quantity': quantity}).eq('id', id);
  }

  Future<void> updateOrder(String id, int order) async {
    await client.from('products').update({'order': order}).eq('id', id);
  }

  Future<void> updateProduct(String id, String name, int quantity) async {
    await client.from('products').update({
      'name': name,
      'quantity': quantity,
    }).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }

  Future<void> deleteCheckedProducts() async {
    await client.from('products').delete().eq('is_checked', true);
  }

  Future<void> deleteAllProducts() async {
    await client.from('products').delete().neq('id', '');
  }
}