import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/product.dart';
import '../repositories/product_repository_impl.dart';
import '../services/sync_service.dart';
import '../services/update_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/name_quantity_dialog.dart';
import '../widgets/product_item.dart';
import '../widgets/sync_status_bar.dart';
import '../widgets/update_dialog.dart';

class HomeScreen extends StatefulWidget {
  final ProductRepositoryImpl repository;
  final String listId;
  final String listName;
  final String listIcon;

  const HomeScreen({
    super.key,
    required this.repository,
    this.listId = defaultListId,
    this.listName = 'Lista de la Compra',
    this.listIcon = '🛒',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final UpdateService _updateService = UpdateService();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isAdding = false;
  bool _isViewMode = true;
  bool _isConnected = true;
  String _searchQuery = '';
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(connected ? 'Conexion restaurada' : 'Sin conexion a internet'),
              backgroundColor: connected ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
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
    _subscription = widget.repository.watchProducts(listId: widget.listId).listen(
      (products) {
        if (mounted) setState(() => _products = products);
      },
      onError: (Object e) {
        debugPrint('Watch products error: $e');
      },
    );
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await widget.repository.getAll(listId: widget.listId);
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
      await widget.repository.addProduct(name, defaultUserName, listId: widget.listId);
      if (mounted) {
        _controller.clear();
        FocusScope.of(context).unfocus();
      }
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
    final previousProduct = product;
    setState(() => _products = _products.map(
      (p) => p.id == product.id ? p.copyWith(isChecked: newState) : p,
    ).toList());
    try {
      await widget.repository.toggleProduct(product.id, newState);
    } catch (e) {
      if (mounted) {
        setState(() => _products = _products.map(
          (p) => p.id == product.id ? previousProduct : p,
        ).toList());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Future<void> _toggleImportant(Product product) async {
    final newState = !product.isImportant;
    final previousProduct = product;
    setState(() => _products = _products.map(
      (p) => p.id == product.id ? p.copyWith(isImportant: newState) : p,
    ).toList());
    try {
      await widget.repository.toggleImportant(product.id, newState);
    } catch (e) {
      if (mounted) {
        setState(() => _products = _products.map(
          (p) => p.id == product.id ? previousProduct : p,
        ).toList());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Future<void> _decreaseQuantity(Product product) async {
    if (product.quantity <= 0) return;
    final newQty = product.quantity - 1;
    final previousProduct = product;
    setState(() => _products = _products.map(
      (p) => p.id == product.id ? p.copyWith(quantity: newQty) : p,
    ).toList());
    try {
      await widget.repository.updateQuantity(product.id, newQty);
    } catch (e) {
      if (mounted) {
        setState(() => _products = _products.map(
          (p) => p.id == product.id ? previousProduct : p,
        ).toList());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar cantidad: $e')),
        );
      }
    }
  }

  Future<void> _increaseQuantity(Product product) async {
    final newQty = product.quantity + 1;
    final previousProduct = product;
    setState(() => _products = _products.map(
      (p) => p.id == product.id ? p.copyWith(quantity: newQty) : p,
    ).toList());
    try {
      await widget.repository.updateQuantity(product.id, newQty);
    } catch (e) {
      if (mounted) {
        setState(() => _products = _products.map(
          (p) => p.id == product.id ? previousProduct : p,
        ).toList());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar cantidad: $e')),
        );
      }
    }
  }

  Future<void> _editProduct(Product product) async {
    final result = await showDialog<({String name, String quantity})>(
      context: context,
      builder: (context) => NameQuantityDialog(
        title: 'Editar producto',
        initialName: product.name,
        initialQuantity: product.quantity,
      ),
    );

    if (result == null) return;

    final newName = result.name;
    final newQuantity = int.tryParse(result.quantity) ?? product.quantity;

    if (newName.isEmpty) return;

    final previousProduct = product;
    setState(() => _products = _products.map(
      (p) => p.id == product.id ? p.copyWith(name: newName, quantity: newQuantity) : p,
    ).toList());

    try {
      await widget.repository.updateProduct(product.id, newName, newQuantity);
    } catch (e) {
      if (mounted) {
        setState(() => _products = _products.map(
          (p) => p.id == product.id ? previousProduct : p,
        ).toList());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al editar: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(String id) async {
    final removed = _products.where((p) => p.id == id).toList();
    setState(() => _products = _products.where((p) => p.id != id).toList());
    try {
      await widget.repository.deleteProduct(id);
    } catch (e) {
      if (mounted) {
        setState(() => _products = [..._products, ...removed]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Future<void> _uncheckAll() async {
    final previousProducts = List<Product>.from(_products);
    setState(() => _products = _products.map(
      (p) => p.copyWith(isChecked: false),
    ).toList());
    try {
      for (final p in previousProducts.where((p) => p.isChecked)) {
        await widget.repository.toggleProduct(p.id, false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _products = previousProducts);
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
        content: const Text('Eliminar todos los productos de la lista?'),
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
      if (mounted) {
        setState(() => _products = all);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar todo: $e')),
        );
      }
    }
  }

  Future<void> _reorderProducts(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final previousProducts = List<Product>.from(_products);
    setState(() {
      final item = _products.removeAt(oldIndex);
      _products.insert(newIndex, item);
    });
    try {
      for (int i = 0; i < _products.length; i++) {
        await widget.repository.updatePosition(_products[i].id, i);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _products = previousProducts);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reordenar: $e')),
        );
      }
    }
  }

  int get _checkedCount => _products.where((p) => p.isChecked).length;

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _checkForUpdate() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buscando actualizaciones...'),
        duration: Duration(seconds: 1),
      ),
    );

    final release = await _updateService.checkForUpdate();

    if (mounted) {
      if (release != null) {
        UpdateDialog.show(context, release, _updateService);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya tienes la ultima version'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildProductItem(Product product) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appGradient),
        ),
        title: Text('${widget.listIcon} ${widget.listName}'),
        actions: [
          IconButton(
            icon: Icon(
              _isViewMode ? Icons.visibility_outlined : Icons.edit_outlined,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => setState(() => _isViewMode = !_isViewMode),
            tooltip: _isViewMode ? 'Modo edicion' : 'Modo vista',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_checked') {
                _uncheckAll();
              } else if (value == 'delete_all') {
                Future.delayed(Duration.zero, _confirmDeleteAll);
              } else if (value == 'check_update') {
                _checkForUpdate();
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
              const PopupMenuItem(
                value: 'check_update',
                child: Row(
                  children: [
                    Icon(Icons.system_update_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Buscar actualizaciones'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _isViewMode ? Colors.grey.shade100.withValues(alpha: 0.5) : null,
        child: Column(
        children: [
          SyncStatusBar(
            isConnected: _isConnected,
            syncStatus: _syncStatus,
            pendingCount: _pendingCount,
          ),
          if (!_isLoading && _products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: TextField(
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: AppDecorations.searchInputDecoration(
                  hintText: 'Buscar producto...',
                  context: context,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: _isViewMode
                      ? TextField(
                          controller: _controller,
                          enabled: false,
                          decoration: AppDecorations.disabledInputDecoration(
                            hintText: 'Modo vista activo',
                          ),
                        )
                      : TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 15),
                          decoration: AppDecorations.addProductInputDecoration(
                            hintText: 'Anadir producto...',
                          ),
                          onSubmitted: (_) => _addProduct(),
                        ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: _isViewMode ? Colors.grey.shade300 : AppColors.accent,
                  borderRadius: AppRadius.lgAll,
                  child: InkWell(
                    onTap: _isViewMode ? null : _addProduct,
                    borderRadius: AppRadius.lgAll,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _isViewMode ? Colors.grey.shade300 : AppColors.accent,
                        borderRadius: AppRadius.lgAll,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isViewMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_outlined, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Solo lectura',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.3,
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
            const Expanded(
              child: EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Tu lista esta vacia',
                subtitle: 'Anade tu primer producto',
              ),
            )
          else if (_filteredProducts.isEmpty && _searchQuery.isNotEmpty)
            Expanded(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Sin resultados',
                subtitle: 'No se encontraron productos para "$_searchQuery"',
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
                          '${_filteredProducts.length} productos',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Opacity(
                          opacity: _checkedCount > 0 ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.greenBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_checkedCount marcados',
                              style: const TextStyle(
                                color: AppColors.greenText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) => _buildProductItem(_filteredProducts[index]),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 80),
                            itemCount: _filteredProducts.length,
                            onReorderItem: _reorderProducts,
                            itemBuilder: (context, index) => _buildProductItem(_filteredProducts[index]),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }
}
