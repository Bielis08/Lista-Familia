import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/list_model.dart';

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

  // --- Products ---

  Stream<List<Product>> watchProducts() {
    return client
        .from('products')
        .stream(primaryKey: ['id'])
        .order('position', ascending: true)
        .map((rows) => rows.map(Product.fromMap).toList());
  }

  Stream<List<Product>> watchProductsByList(String listId) {
    return client
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('list_id', listId)
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

  Future<List<Product>> getProductsByList(String listId) async {
    final response = await client
        .from('products')
        .select()
        .eq('list_id', listId)
        .order('position', ascending: true) as List<dynamic>;
    return response.map((row) => Product.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<Product> addProduct(String name, String createdBy, {String listId = 'supermercado'}) async {
    final now = DateTime.now().toIso8601String();
    final countResponse = await client.from('products').select('id').eq('list_id', listId);
    final count = countResponse.length;
    final data = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'is_checked': false,
      'quantity': 1,
      'created_by': createdBy,
      'created_at': now,
      'position': count,
      'list_id': listId,
    };
    final response = await client.from('products').insert(data).select().maybeSingle();
    if (response == null) {
      throw Exception('No se pudo agregar el producto');
    }
    return Product.fromMap(response);
  }

  Future<void> updateProduct(String id, String name, int quantity) async {
    await client.from('products').update({
      'name': name,
      'quantity': quantity,
    }).eq('id', id);
  }

  Future<void> updateAll(String id, {
    required String name,
    required bool isChecked,
    required bool isImportant,
    required int quantity,
    required int position,
    required String listId,
  }) async {
    await client.from('products').update({
      'name': name,
      'is_checked': isChecked,
      'is_important': isImportant,
      'quantity': quantity,
      'position': position,
      'list_id': listId,
    }).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }

  // --- Lists ---

  Stream<List<ListModel>> watchLists() {
    return client
        .from('lists')
        .stream(primaryKey: ['id'])
        .order('position', ascending: true)
        .map((rows) => rows.map(ListModel.fromMap).toList());
  }

  Future<List<ListModel>> getLists() async {
    final response = await client
        .from('lists')
        .select()
        .order('position', ascending: true) as List<dynamic>;
    return response.map((row) => ListModel.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<ListModel> addList(String name, String icon) async {
    final now = DateTime.now().toIso8601String();
    final countResponse = await client.from('lists').select('id');
    final count = countResponse.length;
    final data = {
      'id': name.toLowerCase().replaceAll(' ', '-'),
      'name': name,
      'icon': icon,
      'position': count,
      'created_at': now,
    };
    final response = await client.from('lists').insert(data).select().maybeSingle();
    if (response == null) {
      throw Exception('No se pudo agregar la lista');
    }
    return ListModel.fromMap(response);
  }

  Future<void> updateList(String id, {String? name, String? icon, int? position}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (position != null) updates['position'] = position;
    if (updates.isNotEmpty) {
      await client.from('lists').update(updates).eq('id', id);
    }
  }

  Future<void> deleteList(String id) async {
    await client.from('lists').delete().eq('id', id);
  }
}
