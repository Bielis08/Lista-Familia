import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductItem extends StatelessWidget {
  final Product product;
  final VoidCallback onToggle;
  final VoidCallback onToggleImportant;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onQuantityDecrease;
  final VoidCallback onQuantityIncrease;
  final bool isViewMode;

  const ProductItem({
    super.key,
    required this.product,
    required this.onToggle,
    required this.onToggleImportant,
    required this.onDelete,
    required this.onEdit,
    required this.onQuantityDecrease,
    required this.onQuantityIncrease,
    this.isViewMode = false,
  });

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
    final bool isImportant = product.isImportant;
    final bool isChecked = product.isChecked;

    return AnimatedOpacity(
      opacity: isChecked ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isImportant ? const Color(0xFF66BB6A) : Colors.transparent,
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: isChecked,
                onChanged: (_) => onToggle(),
                activeColor: const Color(0xFF43A047),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? Colors.grey : const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (isViewMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: product.quantity > 0
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'x${product.quantity}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: product.quantity > 0
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                              ),
                            ),
                          )
                        else ...[
                          _qtyButton(
                            icon: Icons.remove_circle_outline,
                            color: product.quantity > 0
                                ? const Color(0xFF43A047)
                                : Colors.grey.shade400,
                            onPressed:
                                product.quantity <= 0 ? null : onQuantityDecrease,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${product.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _qtyButton(
                            icon: Icons.add_circle_outline,
                            color: const Color(0xFF43A047),
                            onPressed: onQuantityIncrease,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isImportant ? Icons.star : Icons.star_border,
                  color: isImportant ? const Color(0xFFFFC107) : Colors.grey.shade300,
                  size: 22,
                ),
                onPressed: onToggleImportant,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              if (!isViewMode) ...[
                const SizedBox(width: 2),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 19, color: Colors.blue.shade400),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 19, color: Colors.red.shade300),
                  onPressed: () => _confirmDelete(context),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
