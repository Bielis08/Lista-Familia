import 'package:flutter/material.dart';

class NameQuantityDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final int initialQuantity;

  const NameQuantityDialog({
    super.key,
    required this.title,
    required this.initialName,
    required this.initialQuantity,
  });

  @override
  State<NameQuantityDialog> createState() => _NameQuantityDialogState();
}

class _NameQuantityDialogState extends State<NameQuantityDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _quantityController = TextEditingController(
      text: widget.initialQuantity.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
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
            controller: _quantityController,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (
            name: _nameController.text.trim(),
            quantity: _quantityController.text.trim(),
          )),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
