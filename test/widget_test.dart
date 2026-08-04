import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/models/product.dart';

void main() {
  test('Product default values', () {
    final product = Product(
      id: '1',
      name: 'Test',
      createdBy: 'test',
      createdAt: DateTime.now(),
    );

    expect(product.isChecked, false);
    expect(product.isImportant, false);
    expect(product.quantity, 1);
    expect(product.position, 0);
  });
}
