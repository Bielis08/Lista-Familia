import 'package:flutter/material.dart';

class NameIconDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialName;
  final String initialIcon;

  const NameIconDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialName = '',
    this.initialIcon = '',
  });

  @override
  State<NameIconDialog> createState() => _NameIconDialogState();
}

class _NameIconDialogState extends State<NameIconDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _iconController = TextEditingController(text: widget.initialIcon);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _iconController,
            decoration: const InputDecoration(
              labelText: 'Icono (emoji)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (
            name: _nameController.text.trim(),
            icon: _iconController.text.trim(),
          )),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
