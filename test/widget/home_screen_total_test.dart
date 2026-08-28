import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_familia/constants.dart';
import 'package:lista_familia/database/app_database.dart';
import 'package:lista_familia/models/product.dart';
import 'package:lista_familia/repositories/local_product_repository.dart';
import 'package:lista_familia/repositories/product_repository_impl.dart';
import 'package:lista_familia/screens/home_screen.dart';
import 'package:lista_familia/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalProductRepository local;
  late SyncService syncService;
  late ProductRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = LocalProductRepository(db);
    syncService = SyncService(db);
    repository = ProductRepositoryImpl(local, syncService);
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  Future<Product> seed({
    required String name,
    required double price,
    required int quantity,
    String listId = defaultListId,
  }) async {
    final product = await local.addProduct(
      name,
      'test_user',
      listId: listId,
      price: price,
    );
    if (quantity != 1) {
      await local.updateQuantity(product.id, quantity);
    }
    return product;
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: repository),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  group('HomeScreen total price', () {
    testWidgets('shows total summing price x quantity with decimals', (tester) async {
      await seed(name: 'Pan', price: 1.5, quantity: 2);
      await seed(name: 'Leche', price: 0.75, quantity: 1);

      await pumpHome(tester);

      expect(find.text('Total: 3.75€'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('shows integer total without decimals when result has no remainder', (tester) async {
      await seed(name: 'Arroz', price: 2.0, quantity: 3);

      await pumpHome(tester);

      expect(find.text('Total: 6€'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('hides total badge when all prices are zero', (tester) async {
      await seed(name: 'Agua', price: 0.0, quantity: 4);

      await pumpHome(tester);

      expect(find.textContaining('Total:'), findsNothing);

      await unmount(tester);
    });

    testWidgets('hides total badge in edit mode', (tester) async {
      await seed(name: 'Pan', price: 1.5, quantity: 2);

      await pumpHome(tester);
      expect(find.text('Total: 3€'), findsOneWidget);

      await tester.tap(find.byTooltip('Modo edicion'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Total:'), findsNothing);

      await unmount(tester);
    });
  });
}