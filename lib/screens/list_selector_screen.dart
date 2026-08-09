import 'dart:async';
import 'package:flutter/material.dart';
import '../models/list_model.dart';
import '../repositories/product_repository_impl.dart';
import 'home_screen.dart';

class ListSelectorScreen extends StatefulWidget {
  final ProductRepositoryImpl repository;

  const ListSelectorScreen({super.key, required this.repository});

  @override
  State<ListSelectorScreen> createState() => _ListSelectorScreenState();
}

class _ListSelectorScreenState extends State<ListSelectorScreen> {
  List<ListModel> _lists = [];
  bool _isLoading = true;
  StreamSubscription<List<ListModel>>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadLists();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToChanges() {
    try {
      _subscription = widget.repository.watchLists().listen((lists) {
        if (mounted) setState(() => _lists = lists);
      });
    } catch (e) {
      debugPrint('Watch lists error: $e');
    }
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    try {
      final lists = await widget.repository.getAllLists();
      if (mounted) setState(() => _lists = lists);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar listas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openList(ListModel list) {
    Navigator.push<ListModel>(
      context,
      MaterialPageRoute<ListModel>(
        builder: (_) => HomeScreen(
          repository: widget.repository,
          listId: list.id,
          listName: list.name,
          listIcon: list.icon,
        ),
      ),
    );
  }

  Future<void> _addList() async {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📝');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva lista'),
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
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icono (emoji)',
                border: OutlineInputBorder(),
              ),
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
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final name = nameController.text.trim();
    final icon = iconController.text.trim();
    if (name.isEmpty) return;

    try {
      await widget.repository.addList(name, icon.isNotEmpty ? icon : '📝');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear lista: $e')),
        );
      }
    }
  }

  Future<void> _editList(ListModel list) async {
    final nameController = TextEditingController(text: list.name);
    final iconController = TextEditingController(text: list.icon);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar lista'),
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
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icono (emoji)',
                border: OutlineInputBorder(),
              ),
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

    final name = nameController.text.trim();
    final icon = iconController.text.trim();
    if (name.isEmpty) return;

    try {
      await widget.repository.updateList(
        list.id,
        name: name,
        icon: icon.isNotEmpty ? icon : list.icon,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al editar: $e')),
        );
      }
    }
  }

  Future<void> _deleteList(ListModel list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lista'),
        content: Text('¿Eliminar "${list.name}" y todos sus productos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.repository.deleteList(list.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
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
        title: const Text('Mis Listas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? Center(
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
                          Icons.list_alt_rounded,
                          size: 48,
                          color: Color(0xFF66BB6A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No hay listas',
                        style: TextStyle(
                          color: Color(0xFF424242),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Crea tu primera lista de la compra',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _lists.length,
                  itemBuilder: (context, index) {
                    final list = _lists[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Text(
                          list.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        title: Text(
                          list.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editList(list),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () => _deleteList(list),
                              tooltip: 'Eliminar',
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        onTap: () => _openList(list),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addList,
        backgroundColor: const Color(0xFF43A047),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
