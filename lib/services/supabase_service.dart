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
        .order('position', ascending: true)
        .map((rows) => rows.map(Product.fromMap).toList());
  }

  Future<List<Product>> getProducts() async {
    final response = await client
        .from('products')
        .select()
        .order('position', ascending: true) as List<dynamic>;
    return response.map((row) => Product.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<Product> addProduct(String name, String createdBy) async {
    final now = DateTime.now().toIso8601String();
    final countResponse = await client.from('products').select('id');
    final count = countResponse.length;
    final data = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'is_checked': false,
      'quantity': 1,
      'created_by': createdBy,
      'created_at': now,
      'position': count,
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

  Future<void> toggleImportant(String id, bool isImportant) async {
    await client.from('products').update({'is_important': isImportant}).eq('id', id);
  }

  Future<void> updateQuantity(String id, int quantity) async {
    await client.from('products').update({'quantity': quantity}).eq('id', id);
  }

  Future<void> updatePosition(String id, int position) async {
    await client.from('products').update({'position': position}).eq('id', id);
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