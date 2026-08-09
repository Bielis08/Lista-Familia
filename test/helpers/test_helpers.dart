import 'package:lista_familia/models/product.dart';

Product createTestProduct({
  String? id,
  String? name,
  bool isChecked = false,
  bool isImportant = false,
  int quantity = 1,
  String? createdBy,
  DateTime? createdAt,
  int position = 0,
}) {
  return Product(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: name ?? 'Test Product',
    isChecked: isChecked,
    isImportant: isImportant,
    quantity: quantity,
    createdBy: createdBy ?? 'test_user',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    position: position,
  );
}

List<Product> createTestProducts(int count) {
  return List.generate(count, (i) => createTestProduct(
    id: 'prod_$i',
    name: 'Product $i',
    position: i,
  ));
}
