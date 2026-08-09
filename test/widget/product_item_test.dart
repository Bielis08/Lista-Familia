import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/models/product.dart';
import 'package:lista_familia/widgets/product_item.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  Product createTestProduct({
    String name = 'Test Product',
    bool isChecked = false,
    bool isImportant = false,
    int quantity = 1,
  }) {
    return Product(
      id: 'test_1',
      name: name,
      isChecked: isChecked,
      isImportant: isImportant,
      quantity: quantity,
      createdBy: 'test_user',
      createdAt: DateTime(2026, 1, 1),
      position: 0,
    );
  }

  group('ProductItem', () {
    testWidgets('displays product name', (tester) async {
      final product = createTestProduct(name: 'Leche');

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      expect(find.text('Leche'), findsOneWidget);
    });

    testWidgets('shows unchecked checkbox when not checked', (tester) async {
      final product = createTestProduct(isChecked: false);

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('shows checked checkbox when checked', (tester) async {
      final product = createTestProduct(isChecked: true);

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('calls onToggle when checkbox tapped', (tester) async {
      final product = createTestProduct(isChecked: false);
      bool toggleCalled = false;

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () => toggleCalled = true,
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      await tester.tap(find.byType(Checkbox));
      expect(toggleCalled, isTrue);
    });

    testWidgets('shows star icon for important product', (tester) async {
      final product = createTestProduct(isImportant: true);

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('shows star_border for non-important product', (tester) async {
      final product = createTestProduct(isImportant: false);

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('calls onToggleImportant when star tapped', (tester) async {
      final product = createTestProduct(isImportant: false);
      bool importantCalled = false;

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () => importantCalled = true,
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.star_border));
      expect(importantCalled, true);
    });

    testWidgets('shows quantity in view mode', (tester) async {
      final product = createTestProduct(quantity: 5);

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      expect(find.text('x5'), findsOneWidget);
    });

    testWidgets('shows quantity controls in edit mode', (tester) async {
      final product = createTestProduct(quantity: 3);

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: false,
        ),
      ));

      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows edit and delete buttons in edit mode', (tester) async {
      final product = createTestProduct();

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: false,
        ),
      ));

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('hides edit and delete buttons in view mode', (tester) async {
      final product = createTestProduct();

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('calls onEdit when edit button tapped', (tester) async {
      final product = createTestProduct();
      bool editCalled = false;

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () => editCalled = true,
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: false,
        ),
      ));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(editCalled, true);
    });

    testWidgets('calls onQuantityIncrease when plus tapped', (tester) async {
      final product = createTestProduct(quantity: 1);
      bool increaseCalled = false;

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () => increaseCalled = true,
          isViewMode: false,
        ),
      ));

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      expect(increaseCalled, true);
    });

    testWidgets('calls onQuantityDecrease when minus tapped', (tester) async {
      final product = createTestProduct(quantity: 2);
      bool decreaseCalled = false;

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () => decreaseCalled = true,
          onQuantityIncrease: () {},
          isViewMode: false,
        ),
      ));

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      expect(decreaseCalled, true);
    });

    testWidgets('shows strike-through text when checked', (tester) async {
      final product = createTestProduct(name: 'Pan', isChecked: true);

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      final textWidget = tester.widget<Text>(find.text('Pan'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('shows green border when important', (tester) async {
      final product = createTestProduct(isImportant: true);

      await tester.pumpWidget(buildTestApp(
        ProductItem(
          product: product,
          onToggle: () {},
          onToggleImportant: () {},
          onDelete: () {},
          onEdit: () {},
          onQuantityDecrease: () {},
          onQuantityIncrease: () {},
          isViewMode: true,
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.left.color, const Color(0xFF66BB6A));
    });
  });
}
