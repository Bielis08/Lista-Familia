import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/models/product.dart';

void main() {
  group('Product', () {
    test('fromMap creates product correctly', () {
      final map = {
        'id': '123',
        'name': 'Leche',
        'is_checked': false,
        'is_important': true,
        'quantity': 2,
        'created_by': 'Mamá',
        'created_at': '2024-01-15T10:30:00.000Z',
        'position': 0,
      };

      final product = Product.fromMap(map);

      expect(product.id, '123');
      expect(product.name, 'Leche');
      expect(product.isChecked, false);
      expect(product.isImportant, true);
      expect(product.quantity, 2);
      expect(product.createdBy, 'Mamá');
      expect(product.position, 0);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': '123',
        'name': 'Pan',
      };

      final product = Product.fromMap(map);

      expect(product.isChecked, false);
      expect(product.isImportant, false);
      expect(product.quantity, 1);
      expect(product.createdBy, '');
      expect(product.position, 0);
    });

    test('toMap serializes correctly', () {
      final product = Product(
        id: '123',
        name: 'Huevos',
        isChecked: true,
        isImportant: false,
        quantity: 12,
        createdBy: 'Papá',
        createdAt: DateTime(2024, 1, 15),
        position: 3,
      );

      final map = product.toMap();

      expect(map['id'], '123');
      expect(map['name'], 'Huevos');
      expect(map['is_checked'], true);
      expect(map['is_important'], false);
      expect(map['quantity'], 12);
      expect(map['created_by'], 'Papá');
      expect(map['position'], 3);
    });

    test('copyWith creates new instance with changes', () {
      final product = Product(
        id: '123',
        name: 'Mantequilla',
        quantity: 1,
        createdBy: 'Mamá',
        createdAt: DateTime(2024),
      );

      final updated = product.copyWith(name: 'Mantequilla Vegetal', quantity: 3);

      expect(updated.name, 'Mantequilla Vegetal');
      expect(updated.quantity, 3);
      expect(updated.id, '123');
      expect(updated.createdBy, 'Mamá');
    });

    test('copyWith preserves original when no args', () {
      final product = Product(
        id: '123',
        name: 'Queso',
        quantity: 2,
        createdBy: 'Mamá',
        createdAt: DateTime(2024),
      );

      final copy = product.copyWith();

      expect(copy.name, 'Queso');
      expect(copy.quantity, 2);
      expect(copy, isNot(same(product)));
    });
  });
}
