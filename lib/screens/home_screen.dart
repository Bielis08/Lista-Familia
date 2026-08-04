import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../widgets/product_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final SupabaseService _service = SupabaseService.instance;
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isAdding = false;
  StreamSubscription<List<Product>>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _subscribeToChanges() {
    _subscription = _service.watchProducts().listen((products) {
      if (mounted) {
        setState(() => _products = products);
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _service.getProducts();
      if (mounted) setState(() => _products = products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addProduct() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _isAdding) return;
    setState(() => _isAdding = true);
    try {
      await _service.addProduct(name, 'Usuario');
      if (mounted) _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _toggleProduct(Product product) async {
    final newState = !product.isChecked;
    setState(() => product.isChecked = newState);
    try {
      await _service.toggleProduct(product.id, newState);
    } catch (e) {
      setState(() => product.isChecked = !newState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Future<void> _decreaseQuantity(Product product) async {
    if (product.quantity <= 0) return;
    final newQty = product.quantity - 1;
    setState(() => product.quantity = newQty);
    try {
      await _service.updateQuantity(product.id, newQty);
    } catch (e) {
      setState(() => product.quantity = product.quantity + 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar cantidad: $e')),
        );
      }
    }
  }

  Future<void> _increaseQuantity(Product product) async {
    final newQty = product.quantity + 1;
    setState(() => product.quantity = newQty);
    try {
      await _service.updateQuantity(product.id, newQty);
    } catch (e) {
      setState(() => product.quantity = product.quantity - 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar cantidad: $e')),
        );
      }
    }
  }

  Future<void> _editProduct(Product product) async {
    final nameController = TextEditingController(text: product.name);
    final quantityController = TextEditingController(
      text: product.quantity.toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final newName = nameController.text.trim();
    final newQuantity = int.tryParse(quantityController.text) ?? product.quantity;

    if (newName.isEmpty) return;

    setState(() {
      product.name = newName;
      product.quantity = newQuantity;
    });

    try {
      await _service.updateProduct(product.id, newName, newQuantity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al editar: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(String id) async {
    final removed = _products.where((p) => p.id == id).toList();
    setState(() => _products.removeWhere((p) => p.id == id));
    try {
      await _service.deleteProduct(id);
    } catch (e) {
      setState(() => _products.addAll(removed));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Future<void> _uncheckAll() async {
    final checkedProducts = _products.where((p) => p.isChecked).toList();
    setState(() {
      for (var product in _products) {
        product.isChecked = false;
      }
    });
    try {
      for (var product in checkedProducts) {
        await _service.toggleProduct(product.id, false);
      }
    } catch (e) {
      setState(() {
        for (var product in checkedProducts) {
          product.isChecked = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al desmarcar: $e')),
        );
      }
    }
  }

  void _confirmDeleteAll() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todo'),
        content: const Text('¿Eliminar todos los productos de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              _deleteAll();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAll() async {
    final all = List<Product>.from(_products);
    setState(() => _products.clear());
    try {
      await _service.deleteAllProducts();
    } catch (e) {
      setState(() => _products = all);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar todo: $e')),
        );
      }
    }
  }

  Future<void> _reorderProducts(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    setState(() {
      final item = _products.removeAt(oldIndex);
      _products.insert(newIndex, item);
    });
    try {
      for (int i = 0; i < _products.length; i++) {
        await _service.updatePosition(_products[i].id, i);
      }
    } catch (e) {
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reordenar: $e')),
        );
      }
    }
  }

  int get _checkedCount => _products.where((p) => p.isChecked).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de la Compra'),
        actions: [
          if (_products.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete_checked') _uncheckAll();
                if (value == 'delete_all') {
                  Future.delayed(Duration.zero, () => _confirmDeleteAll());
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete_checked',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Desmarcar todos los marcados'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20),
                      SizedBox(width: 8),
                      Text('Eliminar todo'),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Añadir producto...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: const Icon(Icons.add_shopping_cart),
                    ),
                    onSubmitted: (_) => _addProduct(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addProduct,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_products.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No hay productos en la lista',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${_products.length} productos',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const Spacer(),
                        if (_checkedCount > 0)
                          Text(
                            '$_checkedCount marcados',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _products.length,
                      onReorderItem: _reorderProducts,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return ProductItem(
                          key: ValueKey(product.id),
                          product: product,
                          onToggle: () => _toggleProduct(product),
                          onDelete: () => _deleteProduct(product.id),
                          onEdit: () => _editProduct(product),
                          onQuantityDecrease: () => _decreaseQuantity(product),
                          onQuantityIncrease: () => _increaseQuantity(product),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}