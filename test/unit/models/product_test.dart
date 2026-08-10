import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/models/product.dart';

void main() {
  group('Product', () {
    test('fromMap creates correct Product', () {
      final map = {
        'id': '1',
        'name': 'Leche',
        'is_checked': true,
        'is_important': false,
        'quantity': 3,
        'created_by': 'mom',
        'created_at': '2026-01-15T10:30:00.000',
        'position': 5,
      };

      final product = Product.fromMap(map);

      expect(product.id, '1');
      expect(product.name, 'Leche');
      expect(product.isChecked, true);
      expect(product.isImportant, false);
      expect(product.quantity, 3);
      expect(product.createdBy, 'mom');
      expect(product.createdAt, DateTime(2026, 1, 15, 10, 30, 0));
      expect(product.position, 5);
    });

    test('fromMap handles missing optional fields with defaults', () {
      final map = {
        'id': '1',
        'name': 'Pan',
        'created_by': 'dad',
        'created_at': '2026-01-15T10:30:00.000',
      };

      final product = Product.fromMap(map);

      expect(product.isChecked, false);
      expect(product.isImportant, false);
      expect(product.quantity, 1);
      expect(product.position, 0);
    });

    test('fromMap handles null created_at with DateTime.now()', () {
      final map = {
        'id': '1',
        'name': 'Pan',
        'created_by': 'dad',
        'created_at': null,
      };

      final before = DateTime.now();
      final product = Product.fromMap(map);
      final after = DateTime.now();

      expect(product.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(product.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('toMap creates correct map', () {
      final product = Product(
        id: '1',
        name: 'Huevos',
        isChecked: true,
        isImportant: true,
        quantity: 12,
        createdBy: 'mom',
        createdAt: DateTime(2026, 1, 15, 10, 30, 0),
        position: 3,
      );

      final map = product.toMap();

      expect(map['id'], '1');
      expect(map['name'], 'Huevos');
      expect(map['is_checked'], true);
      expect(map['is_important'], true);
      expect(map['quantity'], 12);
      expect(map['created_by'], 'mom');
      expect(map['created_at'], '2026-01-15T10:30:00.000');
      expect(map['position'], 3);
    });

    test('round-trip fromMap toMap preserves data', () {
      final original = Product(
        id: '42',
        name: 'Queso',
        isChecked: false,
        isImportant: true,
        quantity: 2,
        createdBy: 'dad',
        createdAt: DateTime(2026, 6, 20, 14, 0, 0),
        position: 7,
      );

      final map = original.toMap();
      final restored = Product.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.isChecked, original.isChecked);
      expect(restored.isImportant, original.isImportant);
      expect(restored.quantity, original.quantity);
      expect(restored.createdBy, original.createdBy);
      expect(restored.position, original.position);
    });

    group('copyWith', () {
      test('updates only specified fields', () {
        final original = Product(
          id: '1',
          name: 'Original',
          quantity: 1,
          isChecked: false,
          isImportant: false,
          createdBy: 'test',
          createdAt: DateTime(2026),
        );

        final updated = original.copyWith(name: 'Updated', quantity: 5);

        expect(updated.name, 'Updated');
        expect(updated.quantity, 5);
        expect(updated.id, original.id);
        expect(updated.isChecked, original.isChecked);
        expect(updated.isImportant, original.isImportant);
        expect(updated.createdBy, original.createdBy);
        expect(updated.createdAt, original.createdAt);
        expect(updated.position, original.position);
      });

      test('updates isChecked', () {
        final product = Product(
          id: '1', name: 'Test', isChecked: false,
          createdBy: 'test', createdAt: DateTime(2026),
        );
        final toggled = product.copyWith(isChecked: true);
        expect(toggled.isChecked, true);
      });

      test('updates isImportant', () {
        final product = Product(
          id: '1', name: 'Test', isImportant: false,
          createdBy: 'test', createdAt: DateTime(2026),
        );
        final toggled = product.copyWith(isImportant: true);
        expect(toggled.isImportant, true);
      });

      test('updates position', () {
        final product = Product(
          id: '1', name: 'Test', position: 0,
          createdBy: 'test', createdAt: DateTime(2026),
        );
        final moved = product.copyWith(position: 10);
        expect(moved.position, 10);
      });

      test('no changes when no parameters passed', () {
        final product = Product(
          id: '1', name: 'Same', quantity: 1,
          createdBy: 'test', createdAt: DateTime(2026),
        );
        final same = product.copyWith();
        expect(same.name, product.name);
        expect(same.quantity, product.quantity);
      });
    });
  });
}
