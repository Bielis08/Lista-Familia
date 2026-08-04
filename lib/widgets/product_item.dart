import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductItem extends StatelessWidget {
  final Product product;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onQuantityDecrease;
  final VoidCallback onQuantityIncrease;

  const ProductItem({
    super.key,
    required this.product,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onQuantityDecrease,
    required this.onQuantityIncrease,
  });

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: '',
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: '',
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: product.isChecked,
            onChanged: (_) => onToggle(),
            activeColor: Colors.green,
          ),
          const Icon(Icons.drag_handle, size: 24, color: Colors.grey),
        ],
      ),
      title: Text(
        product.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          decoration: product.isChecked ? TextDecoration.lineThrough : null,
          color: product.isChecked ? Colors.grey : null,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            _qtyButton(
              icon: Icons.remove_circle_outline,
              color: product.quantity > 0 ? Colors.green : Colors.grey,
              onPressed: product.quantity > 0 ? onQuantityDecrease : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${product.quantity}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _qtyButton(
              icon: Icons.add_circle_outline,
              color: Colors.green,
              onPressed: onQuantityIncrease,
            ),
            const Spacer(),
            _actionButton(
              icon: Icons.edit_outlined,
              color: Colors.blue,
              onPressed: onEdit,
            ),
            _actionButton(
              icon: Icons.delete_outline,
              color: Colors.red,
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
