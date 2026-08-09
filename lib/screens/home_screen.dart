import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/product_repository_impl.dart';
import '../services/sync_service.dart';
import '../widgets/product_item.dart';

class HomeScreen extends StatefulWidget {
  final ProductRepositoryImpl repository;

  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isAdding = false;
  bool _isViewMode = true;
  bool _isConnected = true;
  int _pendingCount = 0;
  SyncStatus _syncStatus = SyncStatus.idle;
  StreamSubscription<List<Product>>? _subscription;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<int>? _pendingSubscription;
  StreamSubscription<SyncStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _subscribeToChanges();
    _setupConnectivity();
    _setupSyncStatus();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connectivitySubscription?.cancel();
    _pendingSubscription?.cancel();
    _statusSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setupConnectivity() {
    _connectivitySubscription = widget.repository.onConnectivityChanged.listen((connected) {
      if (mounted && _isConnected != connected) {
        setState(() => _isConnected = connected);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(connected ? 'Conexión restaurada' : 'Sin conexión a internet'),
            backgroundColor: connected ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _setupSyncStatus() {
    _pendingSubscription = widget.repository.onPendingChanged.listen((count) {
      if (mounted) setState(() => _pendingCount = count);
    });

    _statusSubscription = widget.repository.onStatusChanged.listen((status) {
      if (mounted) setState(() => _syncStatus = status);
    });

    _isConnected = widget.repository.isConnected;
    _pendingCount = widget.repository.pendingCount;
    _syncStatus = widget.repository.syncStatus;
  }

  void _subscribeToChanges() {
    try {
      _subscription = widget.repository.watchProducts().listen((products) {
        if (mounted) {
          setState(() => _products = products);
        }
      });
    } catch (e) {
      debugPrint('Watch products error: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await widget.repository.getAll();
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
      await widget.repository.addProduct(name, 'Usuario');
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
      await widget.repository.toggleProduct(product.id, newState);
    } catch (e) {
      setState(() => product.isChecked = !newState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Future<void> _toggleImportant(Product product) async {
    final newState = !product.isImportant;
    setState(() => product.isImportant = newState);
    try {
      await widget.repository.toggleImportant(product.id, newState);
    } catch (e) {
      setState(() => product.isImportant = !newState);
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
      await widget.repository.updateQuantity(product.id, newQty);
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
      await widget.repository.updateQuantity(product.id, newQty);
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
      await widget.repository.updateProduct(product.id, newName, newQuantity);
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
      await widget.repository.deleteProduct(id);
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
        await widget.repository.toggleProduct(product.id, false);
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
      await widget.repository.deleteAllProducts();
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
        await widget.repository.updatePosition(_products[i].id, i);
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

  Widget _buildSyncStatusBar() {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (!_isConnected) {
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFEF6C00);
      icon = Icons.wifi_off_rounded;
      text = 'Sin conexión - se sincronizará al reconectar';
    } else if (_syncStatus == SyncStatus.syncing) {
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1976D2);
      icon = Icons.sync_rounded;
      text = 'Sincronizando...';
    } else if (_pendingCount > 0) {
      bgColor = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFF9A825);
      icon = Icons.cloud_upload_outlined;
      text = '$_pendingCount cambios pendientes de subir';
    } else {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      icon = Icons.cloud_done_outlined;
      text = 'Todo sincronizado';
    }

    return Container(
      width: double.infinity,
      height: 32,
      color: bgColor,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_syncStatus == SyncStatus.syncing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
              )
            else
              Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(color: textColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Lista de la Compra'),
        actions: [
          IconButton(
            icon: Icon(
              _isViewMode ? Icons.visibility_outlined : Icons.edit_outlined,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => setState(() => _isViewMode = !_isViewMode),
            tooltip: _isViewMode ? 'Modo edición' : 'Modo vista',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_checked') {
                _uncheckAll();
              } else if (value == 'delete_all') {
                Future.delayed(Duration.zero, _confirmDeleteAll);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_checked',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 10),
                    Text('Desmarcar todos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_all',
                enabled: !_isViewMode,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      size: 20,
                      color: _isViewMode ? Colors.grey : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isViewMode ? 'Eliminar todo (bloqueado)' : 'Eliminar todo',
                    ),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSyncStatusBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isViewMode,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: _isViewMode ? 'Modo vista' : 'Añadir producto...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _addProduct(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isViewMode ? null : _addProduct,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _isViewMode ? Colors.grey.shade300 : const Color(0xFF43A047),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
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
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tu lista está vacía',
                      style: TextStyle(
                        color: Color(0xFF424242),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Añade tu primer producto',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          '${_products.length} productos',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (_checkedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_checkedCount marcados',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
Expanded(
                    child: _isViewMode
                        ? RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 4, bottom: 80),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                return ProductItem(
                                  key: ValueKey(product.id),
                                  product: product,
                                  onToggle: () => _toggleProduct(product),
                                  onToggleImportant: () => _toggleImportant(product),
                                  onDelete: () => _deleteProduct(product.id),
                                  onEdit: () => _editProduct(product),
                                  onQuantityDecrease: () => _decreaseQuantity(product),
                                  onQuantityIncrease: () => _increaseQuantity(product),
                                  isViewMode: _isViewMode,
                                );
                              },
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 80),
                            itemCount: _products.length,
                            onReorderItem: _reorderProducts,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return ProductItem(
                                key: ValueKey(product.id),
                                product: product,
                                onToggle: () => _toggleProduct(product),
                                onToggleImportant: () => _toggleImportant(product),
                                onDelete: () => _deleteProduct(product.id),
                                onEdit: () => _editProduct(product),
                                onQuantityDecrease: () => _decreaseQuantity(product),
                                onQuantityIncrease: () => _increaseQuantity(product),
                                isViewMode: _isViewMode,
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