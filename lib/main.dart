import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/supabase_service.dart';
import 'database/app_database.dart';
import 'repositories/product_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gjkmrlaiipzabpuvwfyr.supabase.co',
  );
  const supabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_AqSsDfU6pKgRH7IkNosxnQ_TSxtJCac',
  );

  try {
    await SupabaseService.instance.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  final db = AppDatabase();
  final repository = ProductRepositoryImpl.getInstance(db: db);

  // Initial migration: populate local DB from Supabase if empty
  try {
    final count = await db.productDao.count();
    if (count == 0) {
      final remoteProducts = await repository.getAll();
      await repository.local.syncFromRemote(remoteProducts);
    }
  } catch (e) {
    debugPrint('Migration error: $e');
  }

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final ProductRepositoryImpl repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista Familiar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
      home: HomeScreen(repository: repository),
    );
  }
}