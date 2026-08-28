import 'package:flutter/material.dart';
import '../constants.dart';
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
        content: Text('Eliminar "${product.name}"?'),
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

    final content = AnimatedOpacity(
      opacity: isChecked ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: AppDecorations.cardShadow.copyWith(
          border: Border(
            left: BorderSide(
              color: isImportant ? AppColors.success : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              Semantics(
                label: '${product.name}, ${isChecked ? "marcado" : "no marcado"}',
                child: Checkbox(
                  value: isChecked,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
                        color: isChecked ? Colors.grey : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Row(
                      children: [
                        if (isViewMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 2,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: product.quantity > 0 ? AppColors.greenBg : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'x${product.quantity}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: product.quantity > 0 ? AppColors.greenText : Colors.grey,
                              ),
                            ),
                          )
                        else ...[
                          _qtyButton(
                            icon: Icons.remove_circle_outline,
                            color: product.quantity > 0 ? AppColors.accent : Colors.grey.shade400,
                            onPressed: product.quantity <= 0 ? null : onQuantityDecrease,
                            tooltip: 'Disminuir cantidad',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2),
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
                            color: AppColors.accent,
                            onPressed: onQuantityIncrease,
                            tooltip: 'Aumentar cantidad',
                          ),
                        ],
                      ],
                    ),
                    if (product.price > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blueBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_formatPrice(product.price)}\u20ac',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blueText,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Semantics(
                label: isImportant ? 'Quitar importante' : 'Marcar importante',
                child: IconButton(
                  icon: Icon(
                    isImportant ? Icons.star : Icons.star_border,
                    color: isImportant ? AppColors.starYellow : Colors.grey.shade300,
                    size: 22,
                  ),
                  onPressed: onToggleImportant,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (!isViewMode) ...[
                const SizedBox(width: 2),
                Semantics(
                  label: 'Editar ${product.name}',
                  child: IconButton(
                    icon: Icon(Icons.edit_outlined, size: 19, color: Colors.blue.shade400),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Semantics(
                  label: 'Eliminar ${product.name}',
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, size: 19, color: Colors.red.shade300),
                    onPressed: () => _confirmDelete(context),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return content;
  }

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return SizedBox(
      width: AppConstraints.minTouchTarget - 18,
      height: AppConstraints.minTouchTarget - 18,
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }
}
