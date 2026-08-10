import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/list_model.dart';
import '../repositories/product_repository_impl.dart';
import '../widgets/empty_state.dart';
import '../widgets/name_icon_dialog.dart';
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
    _subscription = widget.repository.watchLists().listen(
      (lists) {
        if (mounted) setState(() => _lists = lists);
      },
      onError: (Object e) {
        debugPrint('Watch lists error: $e');
      },
    );
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
    final result = await showDialog<({String name, String icon})>(
      context: context,
      builder: (context) => const NameIconDialog(
        title: 'Nueva lista',
        confirmLabel: 'Crear',
        initialIcon: defaultListIcon,
      ),
    );

    if (result == null) return;

    final name = result.name;
    final icon = result.icon;
    if (name.isEmpty) return;

    try {
      await widget.repository.addList(name, icon.isNotEmpty ? icon : defaultListIcon);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear lista: $e')),
        );
      }
    }
  }

  Future<void> _editList(ListModel list) async {
    final result = await showDialog<({String name, String icon})>(
      context: context,
      builder: (context) => NameIconDialog(
        title: 'Editar lista',
        confirmLabel: 'Guardar',
        initialName: list.name,
        initialIcon: list.icon,
      ),
    );

    if (result == null) return;

    final name = result.name;
    final icon = result.icon;
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
        content: Text('Eliminar "${list.name}" y todos sus productos?'),
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
          decoration: const BoxDecoration(gradient: AppColors.appGradient),
        ),
        title: const Text('Mis Listas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? const EmptyState(
                  icon: Icons.list_alt_rounded,
                  title: 'No hay listas',
                  subtitle: 'Crea tu primera lista de la compra',
                )
              : RefreshIndicator(
                  onRefresh: _loadLists,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _lists.length,
                    itemBuilder: (context, index) {
                      final list = _lists[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.xs,
                          ),
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
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addList,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
