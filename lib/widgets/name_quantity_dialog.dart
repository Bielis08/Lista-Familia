import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NameQuantityDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final int initialQuantity;
  final double initialPrice;

  const NameQuantityDialog({
    super.key,
    required this.title,
    required this.initialName,
    required this.initialQuantity,
    this.initialPrice = 0.0,
  });

  @override
  State<NameQuantityDialog> createState() => _NameQuantityDialogState();
}

class _NameQuantityDialogState extends State<NameQuantityDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _quantityController = TextEditingController(
      text: widget.initialQuantity.toString(),
    );
    _priceController = TextEditingController(
      text: _formatInitialPrice(widget.initialPrice),
    );
  }

  String _formatInitialPrice(double price) {
    if (price <= 0) return '';
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
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
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Precio (\u20ac)',
              border: OutlineInputBorder(),
              hintText: 'Opcional',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}\.?\d{0,2}$')),
            ],
          ),
        ],
      ),
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
            price: _priceController.text.trim(),
          )),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
